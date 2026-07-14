begin;

create table if not exists public.teacher_subscriptions (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  status text not null default 'active'
    check (status in ('active', 'cancelled', 'expired')),
  plan_name text,
  amount numeric(10, 2),
  currency text not null default 'EGP',
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create index if not exists teacher_subscriptions_teacher_idx
  on public.teacher_subscriptions(teacher_id, starts_at desc);

create index if not exists teacher_subscriptions_active_idx
  on public.teacher_subscriptions(teacher_id, status, starts_at, ends_at)
  where status = 'active';

alter table public.teacher_subscriptions enable row level security;

drop policy if exists "Admins manage teacher subscriptions"
  on public.teacher_subscriptions;

create policy "Admins manage teacher subscriptions"
  on public.teacher_subscriptions
  for all
  using (public.current_profile_role() = 'admin')
  with check (public.current_profile_role() = 'admin');

drop policy if exists "Teachers view own subscriptions"
  on public.teacher_subscriptions;

create policy "Teachers view own subscriptions"
  on public.teacher_subscriptions
  for select
  using (
    teacher_id = public.current_teacher_id()
    or public.current_profile_role() = 'admin'
  );

create or replace function public.has_active_teacher_subscription(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.teachers t
    join public.teacher_subscriptions s on s.teacher_id = t.id
    where t.profile_id = p_profile_id
      and t.is_active = true
      and s.status = 'active'
      and s.starts_at <= now()
      and s.ends_at > now()
  );
$$;

grant execute on function public.has_active_teacher_subscription(uuid)
  to authenticated;

commit;
