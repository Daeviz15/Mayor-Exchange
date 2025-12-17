-- Create Admin Rates table for dynamic crypto pricing
create table if not exists public.admin_rates (
  asset_symbol text primary key, -- e.g. 'BTC', 'ETH', 'USDT'
  buy_rate numeric(20, 2) not null, -- Rate in NGN when User Buys
  sell_rate numeric(20, 2) not null, -- Rate in NGN when User Sells
  updated_at timestamptz default now() not null,
  updated_by uuid references auth.users(id)
);

-- Enable RLS
alter table public.admin_rates enable row level security;

-- Policies

-- Everyone can read rates
drop policy if exists "Everyone can read rates" on public.admin_rates;
create policy "Everyone can read rates"
  on public.admin_rates for select
  using (true);

-- Only Admins can update rates
drop policy if exists "Admins can update rates" on public.admin_rates;
create policy "Admins can update rates"
  on public.admin_rates for all
  using ( public.is_admin() )
  with check ( public.is_admin() );

-- Seed initial data (approximate values, Admin should update these)
insert into public.admin_rates (asset_symbol, buy_rate, sell_rate)
values
  ('BTC', 165000000.00, 160000000.00),
  ('ETH', 6500000.00, 6000000.00),
  ('USDT', 1650.00, 1600.00),
  ('SOL', 400000.00, 380000.00),
  ('BNB', 1100000.00, 1000000.00)
on conflict (asset_symbol) do nothing;
