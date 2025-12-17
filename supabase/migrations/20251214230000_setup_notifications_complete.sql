-- 1. Create the table if it doesn't exist
create table if not exists public.notifications (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  message text not null,
  type text not null default 'info', -- 'transaction', 'system', 'promo'
  related_id uuid null,
  is_read boolean not null default false,
  created_at timestamp with time zone not null default now(),
  constraint notifications_pkey primary key (id)
);

-- 2. Enable RLS (Safe to run multiple times)
alter table public.notifications enable row level security;

-- 3. Create Policies (Drop first to avoid conflicts if they exist partially)

drop policy if exists "Users can view their own notifications" on public.notifications;
create policy "Users can view their own notifications" on public.notifications
  for select using (auth.uid() = user_id);

drop policy if exists "Users can update their own notifications" on public.notifications;
create policy "Users can update their own notifications" on public.notifications
  for update using (auth.uid() = user_id);

-- This was the missing critical policy for Admins/System to send notifications
drop policy if exists "Enable insert for authenticated users" on public.notifications;
create policy "Enable insert for authenticated users" on public.notifications
  for insert to authenticated
  with check (true);
