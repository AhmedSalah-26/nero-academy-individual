begin;

alter table public.courses
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'courses'
      and column_name = 'instructor_id'
  ) then
    update public.courses c
    set teacher_id = t.id
    from public.teachers t
    where c.teacher_id is null
      and c.instructor_id = t.profile_id;
  end if;
end $$;

alter table public.courses
  alter column teacher_id set not null;

drop index if exists idx_courses_instructor;
create index if not exists idx_courses_teacher
  on public.courses(teacher_id);

create index if not exists courses_teacher_published_idx
  on public.courses(teacher_id, is_published, created_at desc);

commit;
