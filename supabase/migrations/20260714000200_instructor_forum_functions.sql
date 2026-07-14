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
