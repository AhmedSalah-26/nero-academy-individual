-- Delete broken/orphaned old Supabase Auth users.
-- Run this in Supabase SQL Editor.
--
-- These users already have their public.profiles/application data removed.
-- Supabase Admin API returns 500 for them, so deleting from auth.users in SQL
-- is the reliable cleanup path.

begin;

delete from auth.users
where email in (
  'admin.test@nasaq.com',
  'teacher.test@nasaq.com'
);

commit;
