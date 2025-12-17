-- Create App Settings table for global configurations (e.g. Bank Details)
create table if not exists public.app_settings (
  key text primary key, -- e.g. 'admin_bank_details'
  value jsonb not null, -- e.g. { "bank": "GTBank", "account": "0123456789" }
  updated_at timestamptz default now() not null,
  updated_by uuid references auth.users(id)
);

-- Enable RLS
alter table public.app_settings enable row level security;

-- Policies

-- Everyone can read settings (Authenticated)
drop policy if exists "Authenticated users can read settings" on public.app_settings;
create policy "Authenticated users can read settings"
  on public.app_settings for select
  to authenticated
  using (true);

-- Only Admins can insert/update settings
drop policy if exists "Admins can manage settings" on public.app_settings;
create policy "Admins can manage settings"
  on public.app_settings for all
  using ( public.is_admin() )
  with check ( public.is_admin() );

-- Enable Realtime
alter publication supabase_realtime add table public.app_settings;
