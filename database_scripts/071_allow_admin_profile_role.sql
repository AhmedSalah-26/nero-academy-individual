-- Allow demo/admin accounts to use the same role field the Flutter app reads.
-- Run this before scripts/reset_demo_users.mjs if your database still rejects role = 'admin'.

begin;

alter table public.profiles
  drop constraint if exists profiles_role_check;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('student', 'instructor', 'admin', 'parent'));

commit;
