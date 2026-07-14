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
