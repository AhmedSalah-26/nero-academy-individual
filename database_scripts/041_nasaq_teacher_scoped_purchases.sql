-- Nasaq teacher-scoped purchase workflow.
-- Run after the Ahmed/Shehab commerce migrations and 040_nasaq_app_schema.sql.

begin;

alter table public.parent_enrollments
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

alter table public.manual_purchase_request_items
  add column if not exists teacher_id uuid references public.teachers(id) on delete set null;

update public.parent_enrollments pe
set teacher_id = t.id
from public.manual_purchase_request_items item
join public.teachers t on t.profile_id = item.instructor_id
where pe.id = item.parent_enrollment_id
  and pe.teacher_id is null;

update public.manual_purchase_request_items item
set teacher_id = t.id
from public.teachers t
where item.teacher_id is null
  and item.instructor_id = t.profile_id;

create index if not exists idx_parent_enrollments_teacher_manual
on public.parent_enrollments(teacher_id, payment_status, created_at desc)
where payment_method = 'manual';

create index if not exists idx_manual_purchase_items_teacher
on public.manual_purchase_request_items(teacher_id, created_at desc);

drop policy if exists "Teachers can view own manual parent enrollments"
on public.parent_enrollments;
create policy "Teachers can view own manual parent enrollments"
on public.parent_enrollments
for select
to authenticated
using (
  user_id = auth.uid()
  or public.current_profile_role() = 'admin'
  or teacher_id = public.current_teacher_id()
);

drop policy if exists "Teachers can view own manual request items"
on public.manual_purchase_request_items;
create policy "Teachers can view own manual request items"
on public.manual_purchase_request_items
for select
to authenticated
using (
  user_id = auth.uid()
  or public.current_profile_role() = 'admin'
  or teacher_id = public.current_teacher_id()
);

drop policy if exists "Users can create teacher scoped manual request items"
on public.manual_purchase_request_items;
create policy "Users can create teacher scoped manual request items"
on public.manual_purchase_request_items
for insert
to authenticated
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.parent_enrollments pe
    where pe.id = parent_enrollment_id
      and pe.user_id = auth.uid()
      and pe.teacher_id = manual_purchase_request_items.teacher_id
      and pe.payment_method = 'manual'
      and pe.payment_status = 'pending_manual_payment'
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

  if not exists (
    select 1
    from public.manual_purchase_request_items
    where parent_enrollment_id = p_parent_enrollment_id
      and teacher_id = v_order.teacher_id
  ) then
    raise exception 'Manual purchase request has no courses';
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
      instructor_id,
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
      v_item.instructor_id,
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
      instructor_id = excluded.instructor_id,
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

create or replace function public.cancel_manual_purchase_request(
  p_parent_enrollment_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.parent_enrollments%rowtype;
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
    raise exception 'Only the request teacher or an admin can cancel this request';
  end if;

  update public.parent_enrollments
  set payment_status = 'cancelled',
      updated_at = now()
  where id = p_parent_enrollment_id;

  delete from public.enrollments
  where parent_enrollment_id = p_parent_enrollment_id;

  return true;
end;
$$;

grant execute on function public.approve_manual_purchase_request(uuid, integer) to authenticated;
grant execute on function public.cancel_manual_purchase_request(uuid) to authenticated;

commit;
