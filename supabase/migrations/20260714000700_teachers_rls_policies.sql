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
