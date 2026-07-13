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

alter table public.enrollments
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

update public.enrollments e
set teacher_id = c.teacher_id
from public.courses c
where e.teacher_id is null
  and e.course_id = c.id;

alter table public.manual_purchase_request_items
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

update public.manual_purchase_request_items item
set teacher_id = c.teacher_id
from public.courses c
where item.teacher_id is null
  and item.course_id = c.id;

alter table public.parent_enrollments
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

update public.parent_enrollments pe
set teacher_id = item.teacher_id
from public.manual_purchase_request_items item
where pe.teacher_id is null
  and pe.id = item.parent_enrollment_id;

alter table public.courses
  alter column teacher_id set not null;

create index if not exists idx_courses_teacher
  on public.courses(teacher_id);

create index if not exists idx_enrollments_teacher
  on public.enrollments(teacher_id);

create index if not exists idx_manual_purchase_items_teacher
  on public.manual_purchase_request_items(teacher_id);

drop policy if exists "Users can create their manual request items"
on public.manual_purchase_request_items;

drop policy if exists "Users can create teacher scoped manual request items"
on public.manual_purchase_request_items;

create policy "Users can create teacher scoped manual request items"
on public.manual_purchase_request_items
for insert
to authenticated
with check (
  user_id = auth.uid()
  and teacher_id is not null
  and exists (
    select 1
    from public.parent_enrollments pe
    where pe.id = parent_enrollment_id
      and pe.user_id = auth.uid()
      and pe.teacher_id = manual_purchase_request_items.teacher_id
      and pe.payment_method = 'manual'
      and pe.payment_status = 'pending_manual_payment'
  )
  and exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.teacher_id = manual_purchase_request_items.teacher_id
  )
);

create or replace function public.approve_manual_purchase_request(
  p_parent_enrollment_id uuid,
  p_access_days integer
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.parent_enrollments%rowtype;
  v_item record;
  v_inserted_count integer := 0;
begin
  select *
  into v_order
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

  update public.parent_enrollments
  set payment_status = 'paid',
      payment_method = 'manual',
      paid_at = now(),
      updated_at = now()
  where id = p_parent_enrollment_id;

  for v_item in
    select *
    from public.manual_purchase_request_items
    where parent_enrollment_id = p_parent_enrollment_id
      and teacher_id = v_order.teacher_id
  loop
    insert into public.enrollments (
      user_id,
      course_id,
      teacher_id,
      parent_enrollment_id,
      price,
      pricing_option,
      discount,
      status,
      progress_percentage,
      completed_lessons,
      total_watch_time,
      access_expires_at,
      enrolled_at,
      updated_at
    )
    values (
      v_item.user_id,
      v_item.course_id,
      v_item.teacher_id,
      p_parent_enrollment_id,
      v_item.price,
      v_item.pricing_option,
      coalesce(v_item.discount, 0),
      'active',
      0,
      0,
      0,
      now() + make_interval(days => p_access_days),
      now(),
      now()
    )
    on conflict (user_id, course_id)
    do update set
      teacher_id = excluded.teacher_id,
      parent_enrollment_id = excluded.parent_enrollment_id,
      price = excluded.price,
      pricing_option = excluded.pricing_option,
      discount = excluded.discount,
      status = 'active',
      access_expires_at = excluded.access_expires_at,
      enrolled_at = now(),
      updated_at = now()
    where public.enrollments.status not in ('active', 'completed');

    v_inserted_count := v_inserted_count + 1;
  end loop;

  if v_inserted_count = 0 then
    raise exception 'No enrollments were activated';
  end if;

  return true;
end;
$$;

drop policy if exists courses_insert_own on public.courses;
drop policy if exists courses_update_own on public.courses;
drop policy if exists courses_delete_own on public.courses;
drop policy if exists sections_manage_own on public.sections;
drop policy if exists lessons_manage_own on public.lessons;
drop policy if exists lesson_attachments_manage_own on public.lesson_attachments;
drop policy if exists certificates_select_instructor on public.certificates;
drop policy if exists quizzes_manage_own on public.quizzes;
drop policy if exists quiz_questions_manage_own on public.quiz_questions;
drop policy if exists quiz_attempts_select_instructor on public.quiz_attempts;
drop policy if exists "Enrolled users can manage reviews" on public.course_reviews;

create policy courses_insert_own
on public.courses
for insert
to authenticated
with check (
  teacher_id = public.current_teacher_id()
  or public.current_profile_role() = 'admin'
);

create policy courses_update_own
on public.courses
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

create policy courses_delete_own
on public.courses
for delete
to authenticated
using (
  teacher_id = public.current_teacher_id()
  or public.current_profile_role() = 'admin'
);

create policy sections_manage_own
on public.sections
for all
to authenticated
using (
  public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.courses c
    where c.id = sections.course_id
      and c.teacher_id = public.current_teacher_id()
  )
)
with check (
  public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.courses c
    where c.id = sections.course_id
      and c.teacher_id = public.current_teacher_id()
  )
);

create policy lessons_manage_own
on public.lessons
for all
to authenticated
using (
  public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.courses c
    where c.id = lessons.course_id
      and c.teacher_id = public.current_teacher_id()
  )
)
with check (
  public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.courses c
    where c.id = lessons.course_id
      and c.teacher_id = public.current_teacher_id()
  )
);

create policy lesson_attachments_manage_own
on public.lesson_attachments
for all
to authenticated
using (
  public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.lessons l
    join public.courses c on c.id = l.course_id
    where l.id = lesson_attachments.lesson_id
      and c.teacher_id = public.current_teacher_id()
  )
)
with check (
  public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.lessons l
    join public.courses c on c.id = l.course_id
    where l.id = lesson_attachments.lesson_id
      and c.teacher_id = public.current_teacher_id()
  )
);

create policy certificates_select_instructor
on public.certificates
for select
to authenticated
using (
  public.current_profile_role() = 'admin'
  or user_id = auth.uid()
  or exists (
    select 1
    from public.courses c
    where c.id = certificates.course_id
      and c.teacher_id = public.current_teacher_id()
  )
);

create policy quizzes_manage_own
on public.quizzes
for all
to authenticated
using (
  public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.courses c
    where c.id = quizzes.course_id
      and c.teacher_id = public.current_teacher_id()
  )
)
with check (
  public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.courses c
    where c.id = quizzes.course_id
      and c.teacher_id = public.current_teacher_id()
  )
);

create policy quiz_questions_manage_own
on public.quiz_questions
for all
to authenticated
using (
  public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.quizzes q
    join public.courses c on c.id = q.course_id
    where q.id = quiz_questions.quiz_id
      and c.teacher_id = public.current_teacher_id()
  )
)
with check (
  public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.quizzes q
    join public.courses c on c.id = q.course_id
    where q.id = quiz_questions.quiz_id
      and c.teacher_id = public.current_teacher_id()
  )
);

create policy quiz_attempts_select_instructor
on public.quiz_attempts
for select
to authenticated
using (
  public.current_profile_role() = 'admin'
  or user_id = auth.uid()
  or exists (
    select 1
    from public.quizzes q
    join public.courses c on c.id = q.course_id
    where q.id = quiz_attempts.quiz_id
      and c.teacher_id = public.current_teacher_id()
  )
);

create policy "Enrolled users can manage reviews"
on public.course_reviews
for all
to authenticated
using (
  user_id = auth.uid()
  or public.current_profile_role() = 'admin'
  or exists (
    select 1
    from public.courses c
    where c.id = course_reviews.course_id
      and c.teacher_id = public.current_teacher_id()
  )
)
with check (
  user_id = auth.uid()
  or public.current_profile_role() = 'admin'
);

drop table if exists public.instructor_earnings cascade;

do $$
declare
  policy_row record;
begin
  for policy_row in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and (
        coalesce(qual, '') ilike '%instructor_id%'
        or coalesce(with_check, '') ilike '%instructor_id%'
      )
  loop
    execute format(
      'drop policy if exists %I on %I.%I',
      policy_row.policyname,
      policy_row.schemaname,
      policy_row.tablename
    );
  end loop;
end $$;

do $$
declare
  trigger_row record;
begin
  for trigger_row in
    select event_object_schema, event_object_table, trigger_name
    from information_schema.triggers
    where event_object_schema = 'public'
      and action_statement ilike '%instructor_id%'
  loop
    execute format(
      'drop trigger if exists %I on %I.%I',
      trigger_row.trigger_name,
      trigger_row.event_object_schema,
      trigger_row.event_object_table
    );
  end loop;
end $$;

alter table public.manual_purchase_request_items
  drop column if exists instructor_id;

alter table public.courses
  drop column if exists instructor_id;

drop trigger if exists trigger_auto_instructor_earning on public.enrollments;
drop policy if exists enrollments_select_instructor on public.enrollments;
drop policy if exists enrollments_select_teacher on public.enrollments;

create policy enrollments_select_teacher
on public.enrollments
for select
to authenticated
using (
  user_id = auth.uid()
  or public.current_profile_role() = 'admin'
  or teacher_id = public.current_teacher_id()
);

alter table public.enrollments
  drop column if exists instructor_id;

do $$
declare
  column_row record;
begin
  for column_row in
    select table_schema, table_name
    from information_schema.columns
    where table_schema = 'public'
      and column_name = 'instructor_id'
  loop
    execute format(
      'alter table %I.%I drop column if exists instructor_id cascade',
      column_row.table_schema,
      column_row.table_name
    );
  end loop;
end $$;

commit;
