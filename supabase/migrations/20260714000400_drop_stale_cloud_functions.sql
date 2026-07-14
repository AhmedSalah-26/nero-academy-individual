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
