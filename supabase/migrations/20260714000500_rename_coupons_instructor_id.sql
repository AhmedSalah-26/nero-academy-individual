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
