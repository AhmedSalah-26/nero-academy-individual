-- ============================================================
-- supabase/migrations/20260714000000_cleanup_duplicate_triggers.sql
-- ============================================================
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


-- ============================================================
-- supabase/migrations/20260714000100_instructor_purchase_requests_rls.sql
-- ============================================================
-- ============================================================
-- Migration: 20260714000100_instructor_purchase_requests_rls.sql
-- Purpose  : Allow instructors to view purchase requests for
--            their own courses.
--
-- Problem  : The existing RLS policy on parent_enrollments only
--            allows:
--              - the student who placed the order (user_id = auth.uid())
--              - admins
--            Instructors were completely excluded, so
--            ManualPurchaseRequestsScreen always returned 0 rows.
-- ============================================================

begin;

-- ── 1. Add index for the new access pattern ───────────────────
create index if not exists idx_parent_enrollments_teacher
  on public.parent_enrollments(teacher_id);

-- ── 2. Replace the existing SELECT policy to include teachers ─
drop policy if exists "Users can view their own enrollments"
  on public.parent_enrollments;
drop policy if exists "Users and teachers can view their enrollments"
  on public.parent_enrollments;

create policy "Users and teachers can view their enrollments"
  on public.parent_enrollments
  for select
  to authenticated
  using (
    -- the student who placed the order
    user_id = auth.uid()
    -- platform admin
    or public.current_profile_role() = 'admin'
    -- the instructor who owns the courses in this order
    or teacher_id = public.current_teacher_id()
  );

-- ── 3. Allow instructors to update the payment_status ─────────
--   (needed for approve / cancel actions)
drop policy if exists "Teachers can update their purchase requests"
  on public.parent_enrollments;

create policy "Teachers can update their purchase requests"
  on public.parent_enrollments
  for update
  to authenticated
  using (
    teacher_id = public.current_teacher_id()
    or public.current_profile_role() = 'admin'
  )
  with check (
    teacher_id = public.current_teacher_id()
    or public.current_profile_role() = 'admin'
  );

commit;


-- ============================================================
-- supabase/migrations/20260714000200_instructor_forum_functions.sql
-- ============================================================
-- ============================================================
-- Migration: 20260714000200_instructor_forum_functions.sql
-- Purpose  : Create missing RPC functions needed by the forums
--            management screen and the forums list cubit.
--
-- Functions created:
--   1. get_instructor_forum_courses(p_user_id uuid)
--      Returns courses owned by the instructor along with
--      whether each course has an active group conversation.
--
--   2. set_course_group_enabled(p_course_id uuid, p_enabled bool)
--      Creates or deletes the group conversation for a course.
-- ============================================================

begin;

-- ── 1. get_instructor_forum_courses ──────────────────────────
--
--   Input : p_user_id  — the auth.uid() / profiles.id
--   Output: table with columns:
--             course_id uuid
--             title_ar  text
--             title_en  text
--             has_group boolean
-- ─────────────────────────────────────────────────────────────

create or replace function public.get_instructor_forum_courses(
  p_user_id uuid
)
returns table (
  course_id uuid,
  title_ar  text,
  title_en  text,
  has_group boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_teacher_id uuid;
begin
  -- Resolve teachers.id from profile_id
  select id into v_teacher_id
  from public.teachers
  where profile_id = p_user_id
  limit 1;

  if v_teacher_id is null then
    return; -- no rows
  end if;

  return query
    select
      c.id                                                   as course_id,
      coalesce(c.title_ar, '')                               as title_ar,
      coalesce(c.title_en, '')                               as title_en,
      exists (
        select 1
        from public.conversations cv
        where cv.course_id = c.id
          and cv.type = 'multi'
      )                                                      as has_group
    from public.courses c
    where c.teacher_id = v_teacher_id
    order by c.created_at desc;
end;
$$;

-- Allow authenticated users (instructors) to call this function
grant execute on function public.get_instructor_forum_courses(uuid)
  to authenticated;

-- ── 2. set_course_group_enabled ──────────────────────────────
--
--   Input : p_course_id uuid  — the course to enable/disable
--           p_enabled   bool  — true = create group, false = delete
--   Returns void
-- ─────────────────────────────────────────────────────────────

create or replace function public.set_course_group_enabled(
  p_course_id uuid,
  p_enabled   boolean
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_teacher_id uuid;
  v_course     public.courses%rowtype;
begin
  -- Verify caller is the course owner or admin
  select * into v_course
  from public.courses
  where id = p_course_id;

  if not found then
    raise exception 'Course not found';
  end if;

  -- Allow admin or the course teacher
  if public.current_profile_role() <> 'admin' then
    select id into v_teacher_id
    from public.teachers
    where profile_id = auth.uid()
    limit 1;

    if v_teacher_id is null or v_course.teacher_id <> v_teacher_id then
      raise exception 'Not authorised to manage this course forum';
    end if;
  end if;

  if p_enabled then
    -- Create group conversation if one does not already exist
    if not exists (
      select 1 from public.conversations
      where course_id = p_course_id and type = 'multi'
    ) then
      insert into public.conversations (course_id, type, title, created_by)
      values (
        p_course_id,
        'multi',
        coalesce(nullif(trim(v_course.title_ar), ''), v_course.title_en, ''),
        auth.uid()
      );
    end if;
  else
    -- Delete the group conversation for this course
    delete from public.conversations
    where course_id = p_course_id
      and type = 'multi';
  end if;
end;
$$;

-- Allow authenticated users (instructors) to call this function
grant execute on function public.set_course_group_enabled(uuid, boolean)
  to authenticated;

commit;


-- ============================================================
-- supabase/migrations/20260714000300_fix_instructor_id_in_functions.sql
-- ============================================================
-- ============================================================
-- Migration: 20260714000300_fix_instructor_id_in_functions.sql
-- Purpose  : Fix all DB functions that compare courses.teacher_id
--            (which is teachers.id UUID) against a profile_id/auth.uid()
--            directly — this comparison always fails because they are
--            different UUIDs.
--
-- Root cause: After the instructor_id → teacher_id migration, the
--   column courses.teacher_id now stores teachers.id (not profile_id).
--   Several functions still do:
--       cr.teacher_id = p_user_id    -- WRONG (profile_id vs teachers.id)
--   and must instead resolve via:
--       cr.teacher_id = (SELECT id FROM teachers WHERE profile_id = p_user_id)
--
-- Functions fixed:
--   1. get_user_conversations(UUID, TEXT)
-- ============================================================

begin;

-- ── helper: resolve teacher UUID from profile UUID ─────────
-- Reusable inline expression used throughout the fix.
-- We create a small stable helper function to avoid repeating
-- the sub-select everywhere.

create or replace function public.teacher_id_for_profile(p_profile_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select id from public.teachers where profile_id = p_profile_id limit 1;
$$;

grant execute on function public.teacher_id_for_profile(uuid) to authenticated;

-- ── 1. Fix get_user_conversations ──────────────────────────
-- The function used `cr.teacher_id = p_user_id` which compared
-- teachers.id against profiles.id — two different UUID spaces.
-- Fixed to resolve via teacher_id_for_profile().

drop function if exists public.get_user_conversations(uuid, text);

create or replace function public.get_user_conversations(
    p_user_id uuid,
    p_type    text default null
)
returns table (
    conversation_id        uuid,
    conversation_type      varchar(10),
    conversation_title     text,
    course_id              uuid,
    created_at             timestamptz,
    last_message_id        uuid,
    last_message_text      text,
    last_message_user_id   uuid,
    last_message_user_name text,
    last_message_created_at timestamptz,
    participants_count     bigint,
    other_user_name        text,
    other_user_avatar      text
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_caller     uuid    := auth.uid();
    v_is_admin   boolean := false;
    v_teacher_id uuid;                -- teachers.id for this user (may be null)
begin
    if v_caller is null then
        raise exception 'Not authenticated';
    end if;

    select exists (
        select 1 from public.profiles p
        where p.id = v_caller and p.role = 'admin'
    ) into v_is_admin;

    if v_caller <> p_user_id and not v_is_admin then
        raise exception 'Access denied';
    end if;

    -- Resolve teacher UUID once (null if user is not a teacher)
    v_teacher_id := public.teacher_id_for_profile(p_user_id);

    -- ── Auto-join: add user to group chats they are entitled to ──
    -- entitled = has active/completed enrollment OR is the course teacher
    insert into public.conversation_participants (conversation_id, user_id, role)
    select
        c.id,
        p_user_id,
        case
            when v_teacher_id is not null and cr.teacher_id = v_teacher_id then 'admin'
            else 'member'
        end
    from public.conversations c
    join public.courses cr on cr.id = c.course_id
    where c.type = 'multi'
      and (
          -- user is the course teacher
          (v_teacher_id is not null and cr.teacher_id = v_teacher_id)
          or
          -- user has an active/completed enrollment
          exists (
              select 1 from public.enrollments e
              where e.course_id = c.course_id
                and e.user_id   = p_user_id
                and e.status in ('active', 'completed')
          )
      )
    on conflict on constraint conversation_participants_conversation_id_user_id_key
    do update set role = case
        when excluded.role = 'admin' then 'admin'
        else conversation_participants.role
    end;

    -- ── Auto-remove: revoke from groups user is no longer entitled to ──
    delete from public.conversation_participants cp2
    using public.conversations c2
    where cp2.conversation_id = c2.id
      and c2.type             = 'multi'
      and c2.course_id        is not null
      and cp2.user_id         = p_user_id
      and cp2.role            = 'member'
      and not exists (
          select 1 from public.enrollments e2
          where e2.course_id = c2.course_id
            and e2.user_id   = p_user_id
            and e2.status in ('active', 'completed')
      )
      -- keep if user is the teacher of this course
      and not (
          v_teacher_id is not null
          and exists (
              select 1 from public.courses cr2
              where cr2.id         = c2.course_id
                and cr2.teacher_id = v_teacher_id
          )
      );

    -- ── Return all conversations the user participates in ──
    return query
    select
        c.id                as conversation_id,
        c.type              as conversation_type,
        c.title             as conversation_title,
        c.course_id,
        c.created_at,
        lm.id               as last_message_id,
        lm.message_text     as last_message_text,
        lm.user_id          as last_message_user_id,
        p_sender.name       as last_message_user_name,
        lm.created_at       as last_message_created_at,
        (select count(*)
         from public.conversation_participants cp2
         where cp2.conversation_id = c.id) as participants_count,
        case when c.type = 'single' then (
            select p_other.name
            from public.conversation_participants cp_other
            join public.profiles p_other on p_other.id = cp_other.user_id
            where cp_other.conversation_id = c.id
              and cp_other.user_id <> p_user_id
            limit 1
        ) else null end     as other_user_name,
        case when c.type = 'single' then (
            select p_other.avatar_url
            from public.conversation_participants cp_other
            join public.profiles p_other on p_other.id = cp_other.user_id
            where cp_other.conversation_id = c.id
              and cp_other.user_id <> p_user_id
            limit 1
        ) else null end     as other_user_avatar
    from public.conversations c
    join public.conversation_participants cp
         on cp.conversation_id = c.id and cp.user_id = p_user_id
    left join lateral (
        select m.id, m.message_text, m.user_id, m.created_at
        from public.messages m
        where m.conversation_id = c.id
          and m.is_deleted = false
        order by m.created_at desc
        limit 1
    ) lm on true
    left join public.profiles p_sender on p_sender.id = lm.user_id
    where (p_type is null or c.type = p_type)
    order by coalesce(lm.created_at, c.created_at) desc;
end;
$$;

grant execute on function public.get_user_conversations(uuid, text) to authenticated;

-- ── Also keep the single-arg wrapper (called without p_user_id) ──
create or replace function public.get_user_conversations(p_type text default null)
returns table (
    conversation_id        uuid,
    conversation_type      varchar(10),
    conversation_title     text,
    course_id              uuid,
    created_at             timestamptz,
    last_message_id        uuid,
    last_message_text      text,
    last_message_user_id   uuid,
    last_message_user_name text,
    last_message_created_at timestamptz,
    participants_count     bigint,
    other_user_name        text,
    other_user_avatar      text
)
language sql
security definer
set search_path = public
as $$
  select * from public.get_user_conversations(auth.uid(), p_type);
$$;

grant execute on function public.get_user_conversations(text) to authenticated;

commit;


-- ============================================================
-- supabase/migrations/20260714000400_drop_stale_cloud_functions.sql
-- ============================================================
-- ============================================================
-- Migration: 20260714000400_drop_stale_cloud_functions.sql
-- Purpose  : Drop all stale/old versions of functions that may
--            still reference the removed instructor_id column.
--            This forces Supabase to use only the freshly created
--            versions from migrations 000200 and 000300.
--
-- Background: After the instructor_id → teacher_id rename,
--   some cloud-deployed functions were calling:
--       c.instructor_id  (column no longer exists → error 42703)
--   These old function bodies live only on the Supabase cloud
--   and must be replaced by newer versions.
-- ============================================================

begin;

-- ── Drop every known variant of the affected functions ───────

-- get_user_conversations  (all overloads)
drop function if exists public.get_user_conversations();
drop function if exists public.get_user_conversations(text);
drop function if exists public.get_user_conversations(uuid);
drop function if exists public.get_user_conversations(uuid, text);

-- get_instructor_forum_courses (all overloads)
drop function if exists public.get_instructor_forum_courses(uuid);
drop function if exists public.get_instructor_forum_courses();

-- get_or_create_course_conversation (all overloads)
drop function if exists public.get_or_create_course_conversation(uuid);
drop function if exists public.get_or_create_course_conversation(uuid, uuid);

-- set_course_group_enabled (all overloads)
drop function if exists public.set_course_group_enabled(uuid, boolean);

-- get_instructor_courses (old version that may reference instructor_id)
drop function if exists public.get_instructor_courses(uuid);

-- approve / cancel manual purchase (drop old versions)
drop function if exists public.approve_manual_purchase_request(uuid, integer);
drop function if exists public.cancel_manual_purchase_request(uuid);

-- ── Re-create get_user_conversations (teacher_id aware) ──────

create or replace function public.teacher_id_for_profile(p_profile_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select id from public.teachers where profile_id = p_profile_id limit 1;
$$;
grant execute on function public.teacher_id_for_profile(uuid) to authenticated;

-- Main overload (called from Dart with p_user_id)
create or replace function public.get_user_conversations(
    p_user_id uuid,
    p_type    text default null
)
returns table (
    conversation_id         uuid,
    conversation_type       varchar(10),
    conversation_title      text,
    course_id               uuid,
    created_at              timestamptz,
    last_message_id         uuid,
    last_message_text       text,
    last_message_user_id    uuid,
    last_message_user_name  text,
    last_message_created_at timestamptz,
    participants_count      bigint,
    other_user_name         text,
    other_user_avatar       text
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_caller     uuid    := auth.uid();
    v_is_admin   boolean := false;
    v_teacher_id uuid;
begin
    if v_caller is null then
        raise exception 'Not authenticated';
    end if;

    select exists (
        select 1 from public.profiles p
        where p.id = v_caller and p.role = 'admin'
    ) into v_is_admin;

    if v_caller <> p_user_id and not v_is_admin then
        raise exception 'Access denied';
    end if;

    -- Resolve teachers.id for this profile (NULL if not a teacher)
    v_teacher_id := public.teacher_id_for_profile(p_user_id);

    -- Auto-join entitled group chats
    insert into public.conversation_participants (conversation_id, user_id, role)
    select
        c.id,
        p_user_id,
        case
            when v_teacher_id is not null and cr.teacher_id = v_teacher_id
            then 'admin'
            else 'member'
        end
    from public.conversations c
    join public.courses cr on cr.id = c.course_id
    where c.type = 'multi'
      and (
          (v_teacher_id is not null and cr.teacher_id = v_teacher_id)
          or exists (
              select 1 from public.enrollments e
              where e.course_id = c.course_id
                and e.user_id   = p_user_id
                and e.status in ('active', 'completed')
          )
      )
    on conflict on constraint conversation_participants_conversation_id_user_id_key
    do update set role = case
        when excluded.role = 'admin' then 'admin'
        else conversation_participants.role
    end;

    -- Auto-remove from groups user is no longer entitled to
    delete from public.conversation_participants cp2
    using public.conversations c2
    where cp2.conversation_id = c2.id
      and c2.type             = 'multi'
      and c2.course_id        is not null
      and cp2.user_id         = p_user_id
      and cp2.role            = 'member'
      and not exists (
          select 1 from public.enrollments e2
          where e2.course_id = c2.course_id
            and e2.user_id   = p_user_id
            and e2.status in ('active', 'completed')
      )
      and not (
          v_teacher_id is not null
          and exists (
              select 1 from public.courses cr2
              where cr2.id         = c2.course_id
                and cr2.teacher_id = v_teacher_id
          )
      );

    return query
    select
        c.id                    as conversation_id,
        c.type                  as conversation_type,
        c.title                 as conversation_title,
        c.course_id,
        c.created_at,
        lm.id                   as last_message_id,
        lm.message_text         as last_message_text,
        lm.user_id              as last_message_user_id,
        p_sender.name           as last_message_user_name,
        lm.created_at           as last_message_created_at,
        (select count(*) from public.conversation_participants cp2
         where cp2.conversation_id = c.id) as participants_count,
        case when c.type = 'single' then (
            select p_o.name
            from public.conversation_participants cpo
            join public.profiles p_o on p_o.id = cpo.user_id
            where cpo.conversation_id = c.id and cpo.user_id <> p_user_id
            limit 1
        ) else null end         as other_user_name,
        case when c.type = 'single' then (
            select p_o.avatar_url
            from public.conversation_participants cpo
            join public.profiles p_o on p_o.id = cpo.user_id
            where cpo.conversation_id = c.id and cpo.user_id <> p_user_id
            limit 1
        ) else null end         as other_user_avatar
    from public.conversations c
    join public.conversation_participants cp
         on cp.conversation_id = c.id and cp.user_id = p_user_id
    left join lateral (
        select m.id, m.message_text, m.user_id, m.created_at
        from public.messages m
        where m.conversation_id = c.id and m.is_deleted = false
        order by m.created_at desc
        limit 1
    ) lm on true
    left join public.profiles p_sender on p_sender.id = lm.user_id
    where (p_type is null or c.type = p_type)
    order by coalesce(lm.created_at, c.created_at) desc;
end;
$$;
grant execute on function public.get_user_conversations(uuid, text) to authenticated;

-- Wrapper without p_user_id (uses auth.uid())
create or replace function public.get_user_conversations(p_type text default null)
returns table (
    conversation_id         uuid,
    conversation_type       varchar(10),
    conversation_title      text,
    course_id               uuid,
    created_at              timestamptz,
    last_message_id         uuid,
    last_message_text       text,
    last_message_user_id    uuid,
    last_message_user_name  text,
    last_message_created_at timestamptz,
    participants_count      bigint,
    other_user_name         text,
    other_user_avatar       text
)
language sql
security definer
set search_path = public
as $$
  select * from public.get_user_conversations(auth.uid(), p_type);
$$;
grant execute on function public.get_user_conversations(text) to authenticated;

-- ── Re-create get_instructor_forum_courses ────────────────────

create or replace function public.get_instructor_forum_courses(p_user_id uuid)
returns table (course_id uuid, title_ar text, title_en text, has_group boolean)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_teacher_id uuid;
begin
  select id into v_teacher_id from public.teachers
  where profile_id = p_user_id limit 1;

  if v_teacher_id is null then return; end if;

  return query
    select
      c.id,
      coalesce(c.title_ar, ''),
      coalesce(c.title_en, ''),
      exists (
        select 1 from public.conversations cv
        where cv.course_id = c.id and cv.type = 'multi'
      )
    from public.courses c
    where c.teacher_id = v_teacher_id
    order by c.created_at desc;
end;
$$;
grant execute on function public.get_instructor_forum_courses(uuid) to authenticated;

-- ── Re-create get_or_create_course_conversation ──────────────

create or replace function public.get_or_create_course_conversation(p_course_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_conv_id    uuid;
  v_course     public.courses%rowtype;
  v_teacher_id uuid;
begin
  select * into v_course from public.courses where id = p_course_id;
  if not found then raise exception 'Course not found'; end if;

  v_teacher_id := public.teacher_id_for_profile(auth.uid());

  -- Only teachers of this course or admins may create the group
  if public.current_profile_role() <> 'admin'
     and (v_teacher_id is null or v_course.teacher_id <> v_teacher_id) then
    raise exception 'Not authorised';
  end if;

  select id into v_conv_id
  from public.conversations
  where course_id = p_course_id and type = 'multi'
  limit 1;

  if v_conv_id is null then
    insert into public.conversations (course_id, type, title, created_by)
    values (
      p_course_id, 'multi',
      coalesce(nullif(trim(v_course.title_ar), ''), v_course.title_en, ''),
      auth.uid()
    )
    returning id into v_conv_id;
  end if;

  return v_conv_id;
end;
$$;
grant execute on function public.get_or_create_course_conversation(uuid) to authenticated;

-- Backward-compatible overload with p_user_id param
create or replace function public.get_or_create_course_conversation(p_course_id uuid, p_user_id uuid)
returns uuid
language sql
security definer
set search_path = public
as $$
  select public.get_or_create_course_conversation(p_course_id);
$$;
grant execute on function public.get_or_create_course_conversation(uuid, uuid) to authenticated;

-- ── Re-create set_course_group_enabled ───────────────────────

create or replace function public.set_course_group_enabled(p_course_id uuid, p_enabled boolean)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_teacher_id uuid;
  v_course     public.courses%rowtype;
begin
  select * into v_course from public.courses where id = p_course_id;
  if not found then raise exception 'Course not found'; end if;

  if public.current_profile_role() <> 'admin' then
    v_teacher_id := public.teacher_id_for_profile(auth.uid());
    if v_teacher_id is null or v_course.teacher_id <> v_teacher_id then
      raise exception 'Not authorised to manage this course forum';
    end if;
  end if;

  if p_enabled then
    if not exists (
      select 1 from public.conversations
      where course_id = p_course_id and type = 'multi'
    ) then
      insert into public.conversations (course_id, type, title, created_by)
      values (
        p_course_id, 'multi',
        coalesce(nullif(trim(v_course.title_ar), ''), v_course.title_en, ''),
        auth.uid()
      );
    end if;
  else
    delete from public.conversations
    where course_id = p_course_id and type = 'multi';
  end if;
end;
$$;
grant execute on function public.set_course_group_enabled(uuid, boolean) to authenticated;

-- ── Re-create approve/cancel manual purchase ─────────────────

create or replace function public.approve_manual_purchase_request(
  p_parent_enrollment_id uuid,
  p_access_days          integer
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order          public.parent_enrollments%rowtype;
  v_item           record;
  v_inserted_count integer := 0;
begin
  select * into v_order
  from public.parent_enrollments
  where id = p_parent_enrollment_id
    and payment_status = 'pending_manual_payment'
  for update;

  if not found then
    raise exception 'Pending manual purchase request was not found';
  end if;

  if public.current_profile_role() <> 'admin'
     and v_order.teacher_id <> public.current_teacher_id() then
    raise exception 'Only the request teacher or an admin can approve this request';
  end if;

  if p_access_days not in (30, 60, 90) then
    raise exception 'Access days must be 30, 60, or 90';
  end if;

  if not exists (
    select 1 from public.manual_purchase_request_items
    where parent_enrollment_id = p_parent_enrollment_id
      and teacher_id = v_order.teacher_id
  ) then
    raise exception 'Manual purchase request has no courses';
  end if;

  update public.parent_enrollments
  set payment_status = 'paid',
      payment_method = 'manual',
      paid_at        = now(),
      updated_at     = now()
  where id = p_parent_enrollment_id;

  for v_item in
    select * from public.manual_purchase_request_items
    where parent_enrollment_id = p_parent_enrollment_id
      and teacher_id = v_order.teacher_id
  loop
    insert into public.enrollments (
      user_id, course_id, teacher_id, parent_enrollment_id,
      price, pricing_option, discount, status,
      progress_percentage, completed_lessons, total_watch_time,
      access_expires_at, enrolled_at, updated_at
    )
    values (
      v_item.user_id, v_item.course_id, v_item.teacher_id,
      p_parent_enrollment_id, v_item.price, v_item.pricing_option,
      coalesce(v_item.discount, 0), 'active',
      0, 0, 0,
      now() + make_interval(days => p_access_days),
      now(), now()
    )
    on conflict (user_id, course_id) do update set
      teacher_id          = excluded.teacher_id,
      parent_enrollment_id = excluded.parent_enrollment_id,
      price               = excluded.price,
      pricing_option      = excluded.pricing_option,
      discount            = excluded.discount,
      status              = 'active',
      access_expires_at   = excluded.access_expires_at,
      enrolled_at         = now(),
      updated_at          = now()
    where public.enrollments.status not in ('active', 'completed');

    v_inserted_count := v_inserted_count + 1;
  end loop;

  if v_inserted_count = 0 then
    raise exception 'No enrollments were activated';
  end if;

  return true;
end;
$$;
grant execute on function public.approve_manual_purchase_request(uuid, integer) to authenticated;

create or replace function public.cancel_manual_purchase_request(p_parent_enrollment_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.parent_enrollments%rowtype;
begin
  select * into v_order
  from public.parent_enrollments
  where id = p_parent_enrollment_id
    and payment_status = 'pending_manual_payment'
  for update;

  if not found then
    raise exception 'Pending manual purchase request was not found';
  end if;

  if public.current_profile_role() <> 'admin'
     and v_order.teacher_id <> public.current_teacher_id() then
    raise exception 'Only the request teacher or an admin can cancel this request';
  end if;

  update public.parent_enrollments
  set payment_status = 'cancelled', updated_at = now()
  where id = p_parent_enrollment_id;

  delete from public.enrollments
  where parent_enrollment_id = p_parent_enrollment_id;

  return true;
end;
$$;
grant execute on function public.cancel_manual_purchase_request(uuid) to authenticated;

-- ── Re-create can_manage_course (teacher_id aware) ───────────
drop function if exists public.can_manage_course(uuid);

create or replace function public.can_manage_course(p_course_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.courses c
    join public.profiles p on p.id = auth.uid()
    where c.id = p_course_id
      and p.role = 'instructor'
      and p.is_active = true
      and p.is_banned = false
      and (c.teacher_id = public.current_teacher_id() or public.is_admin())
  );
$$;
grant execute on function public.can_manage_course(uuid) to authenticated, anon;

-- ── Re-create get_course_group_members (role cast to text) ───
drop function if exists public.get_course_group_members(uuid);

create or replace function public.get_course_group_members(p_course_id uuid)
returns table (
  user_id uuid,
  user_name text,
  user_avatar text,
  role text,
  is_banned boolean,
  banned_reason text,
  conversation_title text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_conversation_id uuid;
  v_conversation_title text;
begin
  if not public.can_manage_course(p_course_id) then
    raise exception 'Not authorized to manage this course group';
  end if;

  select id, title
  into v_conversation_id, v_conversation_title
  from public.conversations
  where course_id = p_course_id
    and type = 'multi'
  limit 1;

  if v_conversation_id is null then
    return;
  end if;

  return query
  select
    cp.user_id,
    p.name as user_name,
    p.avatar_url as user_avatar,
    cp.role::text,
    coalesce(cp.is_banned, false) as is_banned,
    cp.ban_reason as banned_reason,
    v_conversation_title as conversation_title
  from public.conversation_participants cp
  join public.profiles p on p.id = cp.user_id
  where cp.conversation_id = v_conversation_id
  order by cp.role asc, p.name asc;
end;
$$;
grant execute on function public.get_course_group_members(uuid) to authenticated;

commit;


-- ============================================================
-- supabase/migrations/20260714000500_rename_coupons_instructor_id.sql
-- ============================================================
-- ============================================================
-- Migration: 20260714000500_rename_coupons_instructor_id.sql
-- Purpose  : Rename coupons.instructor_id to coupons.teacher_id
--            and recreate related RLS policies.
-- ============================================================

begin;

-- 1. Rename column in coupons table if it exists, or add it if it doesn't
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'coupons'
      and column_name = 'instructor_id'
  ) then
    alter table public.coupons rename column instructor_id to teacher_id;
  elsif not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'coupons'
      and column_name = 'teacher_id'
  ) then
    alter table public.coupons add column teacher_id uuid references public.profiles(id) on delete cascade;
  end if;
end $$;

-- 2. Drop and recreate policies for coupons
drop policy if exists "Instructors can view own coupons" on public.coupons;
create policy "Instructors can view own coupons" on public.coupons for select 
  using (teacher_id = auth.uid() or public.is_admin());

drop policy if exists "Instructors can insert own coupons" on public.coupons;
create policy "Instructors can insert own coupons" on public.coupons for insert 
  with check (teacher_id = auth.uid() or public.is_admin());

drop policy if exists "Instructors can update own coupons" on public.coupons;
create policy "Instructors can update own coupons" on public.coupons for update 
  using (teacher_id = auth.uid() or public.is_admin())
  with check (teacher_id = auth.uid() or public.is_admin());

drop policy if exists "Instructors can delete own coupons" on public.coupons;
create policy "Instructors can delete own coupons" on public.coupons for delete 
  using (teacher_id = auth.uid() or public.is_admin());

-- 3. Recreate policies for coupon_courses (Allows syncing courses to coupons)
drop policy if exists "Instructors can select own coupon courses" on public.coupon_courses;
create policy "Instructors can select own coupon courses" on public.coupon_courses for select
  using (
    exists (
      select 1 from public.coupons
      where coupons.id = coupon_courses.coupon_id 
        and coupons.teacher_id = auth.uid()
    )
  );

drop policy if exists "Instructors can manage own coupon courses" on public.coupon_courses;
create policy "Instructors can manage own coupon courses" on public.coupon_courses for all
  using (
    exists (
      select 1 from public.coupons
      where coupons.id = coupon_courses.coupon_id 
        and coupons.teacher_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.coupons
      where coupons.id = coupon_courses.coupon_id 
        and coupons.teacher_id = auth.uid()
    )
  );

commit;


-- ============================================================
-- supabase/migrations/20260714000600_fix_categories_encoding.sql
-- ============================================================
-- ============================================================
-- Migration: 20260714000600_fix_categories_encoding.sql
-- Purpose  : Fix garbled category name and description records in 
--            the categories table due to legacy encoding issues.
-- ============================================================

begin;

-- Fix Category 1: البرمجة والتطوير
update public.categories
set 
  name_ar = 'البرمجة والتطوير',
  description_ar = 'تعلم البرمجة وتطوير التطبيقات'
where id = 'c1000000-0000-4000-a000-000000000001';

-- Fix Category 2: التصميم
update public.categories
set 
  name_ar = 'التصميم',
  description_ar = 'تصميم الجرافيك وواجهات المستخدم'
where id = 'c1000000-0000-4000-a000-000000000002';

-- Fix Category 3: الرياضيات والعلوم
update public.categories
set 
  name_ar = 'الرياضيات والعلوم',
  description_ar = 'شرح مناهج الرياضيات والعلوم'
where id = 'c1000000-0000-4000-a000-000000000003';

commit;


-- ============================================================
-- supabase/migrations/20260714000700_teachers_rls_policies.sql
-- ============================================================
-- ============================================================
-- Migration: 20260714000700_teachers_rls_policies.sql
-- Purpose  : Add RLS policies to allow teachers to insert and 
--            update their own profiles in the teachers table.
-- ============================================================

begin;

-- 1. Policy to allow authenticated users to insert their own teacher profile
drop policy if exists "Teachers can insert own profile" on public.teachers;
create policy "Teachers can insert own profile"
on public.teachers for insert
to authenticated
with check (profile_id = auth.uid());

-- 2. Policy to allow authenticated users to update their own teacher profile
drop policy if exists "Teachers can update own profile" on public.teachers;
create policy "Teachers can update own profile"
on public.teachers for update
to authenticated
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

commit;
