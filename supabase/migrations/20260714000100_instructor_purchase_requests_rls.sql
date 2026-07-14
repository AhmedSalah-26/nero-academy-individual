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
