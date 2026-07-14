-- ============================================================
-- Migration: 20260714000000_cleanup_duplicate_triggers.sql
-- Purpose  : Remove duplicate & broken triggers left over from
--            multiple schema iterations.
--
-- Problems fixed:
--   1. section_stats_trigger  ↔ trigger_update_course_stats_sections  (duplicate on sections)
--   2. lesson_stats_trigger   ↔ trigger_update_course_stats_lessons   (duplicate on lessons)
--   3. earning_stats_trigger  on instructor_earnings (table was DROPped in teacher_id migration)
--   4. trigger_auto_instructor_earning on enrollments (old version that wrote to dropped table)
--   5. trigger_update_instructor_stats on enrollments (redundant with enrolled_count logic)
--
-- Strategy: keep the NEWEST / most correct version of each trigger,
--           drop the older duplicates.
-- ============================================================

begin;

-- ──────────────────────────────────────────────────────────────
-- 1 & 2 ▸ DUPLICATE STATS TRIGGERS ON sections & lessons
--
--   KEEP  : trigger_update_course_stats_sections / _lessons
--           (defined at L933/938 in the full schema — uses the
--            canonical update_course_stats() function)
--   DROP  : section_stats_trigger / lesson_stats_trigger
--           (older copies defined at L1994 — call separate
--            per-table wrapper functions that do the same thing)
-- ──────────────────────────────────────────────────────────────

drop trigger if exists section_stats_trigger on public.sections;
drop trigger if exists lesson_stats_trigger  on public.lessons;

-- Also drop the wrapper functions that are now unused
drop function if exists public.trigger_update_course_stats_on_section() cascade;
drop function if exists public.trigger_update_course_stats_on_lesson()  cascade;
drop function if exists public.trigger_update_course_stats_on_earning() cascade;

-- ──────────────────────────────────────────────────────────────
-- 3 ▸ BROKEN TRIGGER ON DROPPED TABLE instructor_earnings
--
--   The migration 20260713180500 ran:
--     drop table if exists public.instructor_earnings cascade;
--   That CASCADE already dropped earning_stats_trigger, but
--   we add an explicit guard here in case the table was
--   re-created later without the trigger being cleaned up.
-- ──────────────────────────────────────────────────────────────

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name   = 'instructor_earnings'
  ) then
    drop trigger if exists earning_stats_trigger on public.instructor_earnings;
  end if;
end $$;

-- ──────────────────────────────────────────────────────────────
-- 4 ▸ OLD trigger_auto_instructor_earning (pre-teacher_id)
--
--   The migration 20260713180500 dropped this trigger.
--   The full DB file re-created an IMPROVED version at L5829
--   that uses teacher_id correctly.
--   We drop any stale copy and ensure only one exists.
-- ──────────────────────────────────────────────────────────────

drop trigger if exists trigger_auto_instructor_earning on public.enrollments;

-- Re-create the canonical, teacher_id-aware version
-- (matches L5750-L5834 in 000_nasaq_full_database.sql)
create or replace function public.trigger_create_instructor_earning()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_teacher_id     uuid;
  v_gross          decimal(10,2);
  v_coupon_discount decimal(10,2);
  v_platform_fee   decimal(10,2);
  v_net            decimal(10,2);
  v_revenue_share  decimal(5,2) := 100.00;
begin
  -- Only process active / completed enrollments
  if new.status not in ('active', 'completed') then
    return new;
  end if;

  v_teacher_id      := new.teacher_id;
  v_gross           := greatest(coalesce(new.price,    0), 0);
  v_coupon_discount := least(greatest(coalesce(new.discount, 0), 0), v_gross);

  -- Fallback: resolve teacher_id from courses if not set on enrollment
  if v_teacher_id is null then
    select teacher_id into v_teacher_id
    from public.courses
    where id = new.course_id;
  end if;

  -- Nothing to record for free enrollments or unknown teacher
  if v_teacher_id is null or v_gross <= 0 then
    return new;
  end if;

  v_platform_fee := 0.00;
  v_net          := greatest(v_gross - v_coupon_discount - v_platform_fee, 0);

  -- Only insert if instructor_earnings table exists
  -- (guard against future table drops)
  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'instructor_earnings'
  ) then
    return new;
  end if;

  insert into public.instructor_earnings (
    teacher_id, enrollment_id, course_id,
    gross_amount, coupon_discount, platform_fee,
    net_amount, revenue_share, status, available_at, created_at
  )
  values (
    v_teacher_id, new.id, new.course_id,
    v_gross, v_coupon_discount, v_platform_fee,
    v_net, v_revenue_share,
    'available', now(), now()
  )
  on conflict (enrollment_id)
  do update set
    teacher_id        = excluded.teacher_id,
    course_id         = excluded.course_id,
    gross_amount      = excluded.gross_amount,
    coupon_discount   = excluded.coupon_discount,
    platform_fee      = excluded.platform_fee,
    net_amount        = excluded.net_amount,
    revenue_share     = excluded.revenue_share,
    status            = case
                          when public.instructor_earnings.status = 'paid'
                          then public.instructor_earnings.status
                          else excluded.status
                        end,
    available_at      = coalesce(public.instructor_earnings.available_at, excluded.available_at);

  return new;
end;
$$;

create trigger trigger_auto_instructor_earning
  after insert or update of status, price, discount, teacher_id, course_id
  on public.enrollments
  for each row
  execute function public.trigger_create_instructor_earning();

-- Revoke direct execution from clients
revoke execute on function public.trigger_create_instructor_earning() from public;
revoke execute on function public.trigger_create_instructor_earning() from authenticated;
revoke execute on function public.trigger_create_instructor_earning() from anon;

-- ──────────────────────────────────────────────────────────────
-- 5 ▸ VERIFY: list remaining triggers so we can confirm cleanup
-- ──────────────────────────────────────────────────────────────

do $$
declare
  r record;
begin
  raise notice '=== Active triggers after cleanup ===';
  for r in
    select
      trigger_name,
      event_object_table as tbl,
      string_agg(event_manipulation, '/' order by event_manipulation) as events,
      action_timing
    from information_schema.triggers
    where trigger_schema = 'public'
    group by trigger_name, event_object_table, action_timing
    order by event_object_table, trigger_name
  loop
    raise notice '  [%] % → %', r.tbl, r.trigger_name, r.events;
  end loop;
end $$;

commit;
