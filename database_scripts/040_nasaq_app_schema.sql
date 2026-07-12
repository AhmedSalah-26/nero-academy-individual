-- Nasaq app schema foundation.
-- This migration keeps the existing LMS shape and adds teacher-scoped app flow.

begin;

create extension if not exists pgcrypto;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'payment_request_status'
  ) then
    create type payment_request_status as enum (
      'pending',
      'approved',
      'rejected',
      'cancelled'
    );
  end if;
end $$;

create table if not exists public.teachers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  display_name text not null,
  avatar_url text,
  bio text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(profile_id)
);

create table if not exists public.teacher_settings (
  teacher_id uuid primary key references public.teachers(id) on delete cascade,
  allow_public_profile boolean not null default true,
  allow_student_switching boolean not null default true,
  manual_payment_instructions text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.teacher_themes (
  teacher_id uuid primary key references public.teachers(id) on delete cascade,
  primary_color text not null default '#20E5DC',
  secondary_color text not null default '#117CFF',
  background_color text not null default '#01060B',
  logo_url text,
  welcome_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.teachers (profile_id, display_name, avatar_url)
select p.id, coalesce(p.name, 'مدرس'), p.avatar_url
from public.profiles p
where p.role::text = 'instructor'
on conflict (profile_id) do nothing;

insert into public.teacher_settings (teacher_id)
select id
from public.teachers
on conflict (teacher_id) do nothing;

insert into public.teacher_themes (teacher_id)
select id
from public.teachers
on conflict (teacher_id) do nothing;

alter table public.profiles
  add column if not exists active_teacher_id uuid references public.teachers(id) on delete set null;

alter table public.courses
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

update public.courses c
set teacher_id = t.id
from public.teachers t
where c.teacher_id is null
  and c.instructor_id = t.profile_id;

create table if not exists public.student_teacher_links (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  is_active boolean not null default false,
  selected_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(student_id, teacher_id)
);

create unique index if not exists student_teacher_links_one_active_idx
  on public.student_teacher_links(student_id)
  where is_active = true;

create table if not exists public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  parent_enrollment_id uuid references public.parent_enrollments(id) on delete set null,
  course_id uuid references public.courses(id) on delete set null,
  amount numeric(10, 2) not null default 0,
  currency text not null default 'EGP',
  status payment_request_status not null default 'pending',
  payment_method text,
  proof_image_url text,
  student_note text,
  teacher_note text,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists payment_requests_student_idx
  on public.payment_requests(student_id, created_at desc);

create index if not exists payment_requests_teacher_idx
  on public.payment_requests(teacher_id, status, created_at desc);

create index if not exists payment_requests_parent_enrollment_idx
  on public.payment_requests(parent_enrollment_id);

create index if not exists courses_teacher_idx
  on public.courses(teacher_id, is_published);

create or replace function public.current_profile_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role::text from public.profiles where id = auth.uid()),
    'student'
  );
$$;

create or replace function public.current_teacher_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.teachers where profile_id = auth.uid() limit 1;
$$;

create or replace function public.admin_upsert_teacher(
  p_profile_id uuid,
  p_display_name text default null,
  p_is_active boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_teacher_id uuid;
begin
  if public.current_profile_role() <> 'admin' then
    raise exception 'Only admins can manage teachers';
  end if;

  insert into public.teachers (profile_id, display_name, is_active)
  values (
    p_profile_id,
    coalesce(
      nullif(trim(p_display_name), ''),
      (select coalesce(name, email, 'مدرس') from public.profiles where id = p_profile_id),
      'مدرس'
    ),
    p_is_active
  )
  on conflict (profile_id)
  do update set
    display_name = coalesce(nullif(trim(p_display_name), ''), public.teachers.display_name),
    is_active = p_is_active,
    updated_at = now()
  returning id into v_teacher_id;

  update public.profiles
  set role = 'instructor',
      updated_at = now()
  where id = p_profile_id;

  insert into public.teacher_settings (teacher_id)
  values (v_teacher_id)
  on conflict (teacher_id) do nothing;

  insert into public.teacher_themes (teacher_id)
  values (v_teacher_id)
  on conflict (teacher_id) do nothing;

  return v_teacher_id;
end;
$$;

grant execute on function public.admin_upsert_teacher(uuid, text, boolean) to authenticated;

create or replace function public.approve_payment_request(request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  request_row public.payment_requests%rowtype;
  request_teacher_profile_id uuid;
begin
  select *
  into request_row
  from public.payment_requests
  where id = request_id
  for update;

  if not found then
    raise exception 'Payment request not found';
  end if;

  if public.current_profile_role() <> 'admin'
     and request_row.teacher_id <> public.current_teacher_id() then
    raise exception 'Not allowed';
  end if;

  select profile_id
  into request_teacher_profile_id
  from public.teachers
  where id = request_row.teacher_id;

  update public.payment_requests
  set status = 'approved',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      updated_at = now()
  where id = request_id;

  update public.enrollments
  set status = 'active',
      updated_at = now()
  where user_id = request_row.student_id
    and status = 'pending'
    and (
      parent_enrollment_id = request_row.parent_enrollment_id
      or (
        instructor_id = request_teacher_profile_id
        and (
          request_row.course_id is null
          or course_id = request_row.course_id
        )
      )
    );

  update public.parent_enrollments
  set payment_status = 'paid',
      paid_at = now(),
      updated_at = now()
  where id = request_row.parent_enrollment_id;
end;
$$;

create or replace function public.reject_payment_request(
  request_id uuid,
  note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  request_row public.payment_requests%rowtype;
begin
  select *
  into request_row
  from public.payment_requests
  where id = request_id
  for update;

  if not found then
    raise exception 'Payment request not found';
  end if;

  if public.current_profile_role() <> 'admin'
     and request_row.teacher_id <> public.current_teacher_id() then
    raise exception 'Not allowed';
  end if;

  update public.payment_requests
  set status = 'rejected',
      teacher_note = note,
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      updated_at = now()
  where id = request_id;
end;
$$;

alter table public.teachers enable row level security;
alter table public.teacher_settings enable row level security;
alter table public.teacher_themes enable row level security;
alter table public.student_teacher_links enable row level security;
alter table public.payment_requests enable row level security;

drop policy if exists "Teachers are visible to authenticated users" on public.teachers;
create policy "Teachers are visible to authenticated users"
on public.teachers for select
to authenticated
using (is_active = true or profile_id = auth.uid() or public.current_profile_role() = 'admin');

drop policy if exists "Admins manage teachers" on public.teachers;
create policy "Admins manage teachers"
on public.teachers for all
to authenticated
using (public.current_profile_role() = 'admin')
with check (public.current_profile_role() = 'admin');

drop policy if exists "Teachers manage own settings" on public.teacher_settings;
create policy "Teachers manage own settings"
on public.teacher_settings for all
to authenticated
using (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin')
with check (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin');

drop policy if exists "Teacher themes are visible" on public.teacher_themes;
create policy "Teacher themes are visible"
on public.teacher_themes for select
to authenticated
using (true);

drop policy if exists "Teachers manage own themes" on public.teacher_themes;
create policy "Teachers manage own themes"
on public.teacher_themes for all
to authenticated
using (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin')
with check (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin');

drop policy if exists "Students view own teacher links" on public.student_teacher_links;
create policy "Students view own teacher links"
on public.student_teacher_links for select
to authenticated
using (
  student_id = auth.uid()
  or teacher_id = public.current_teacher_id()
  or public.current_profile_role() = 'admin'
);

drop policy if exists "Students choose own teachers" on public.student_teacher_links;
create policy "Students choose own teachers"
on public.student_teacher_links for insert
to authenticated
with check (student_id = auth.uid());

drop policy if exists "Students update own active teacher" on public.student_teacher_links;
create policy "Students update own active teacher"
on public.student_teacher_links for update
to authenticated
using (student_id = auth.uid() or public.current_profile_role() = 'admin')
with check (student_id = auth.uid() or public.current_profile_role() = 'admin');

drop policy if exists "Payment requests scoped select" on public.payment_requests;
create policy "Payment requests scoped select"
on public.payment_requests for select
to authenticated
using (
  student_id = auth.uid()
  or teacher_id = public.current_teacher_id()
  or public.current_profile_role() = 'admin'
);

drop policy if exists "Students create own payment requests" on public.payment_requests;
create policy "Students create own payment requests"
on public.payment_requests for insert
to authenticated
with check (student_id = auth.uid());

drop policy if exists "Teachers review own payment requests" on public.payment_requests;
create policy "Teachers review own payment requests"
on public.payment_requests for update
to authenticated
using (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin')
with check (teacher_id = public.current_teacher_id() or public.current_profile_role() = 'admin');

commit;
