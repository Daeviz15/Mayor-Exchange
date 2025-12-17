-- Create Enums safely
do $$ begin
  create type public.transaction_type as enum (
    'buy_crypto',
    'sell_crypto',
    'buy_giftcard',
    'sell_giftcard'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.transaction_status as enum (
    'pending',
    'claimed',
    'payment_pending',
    'verification_pending',
    'completed',
    'rejected',
    'cancelled'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.app_role as enum (
    'admin',
    'user'
  );
exception
  when duplicate_object then null;
end $$;

-- Create User Roles table (Simple RBAC)
create table if not exists public.user_roles (
  id uuid references auth.users on delete cascade not null primary key,
  role public.app_role default 'user'::public.app_role not null,
  created_at timestamptz default now() not null
);

-- Enable RLS on user_roles
alter table public.user_roles enable row level security;

drop policy if exists "Users can read their own role" on public.user_roles;
create policy "Users can read their own role"
  on public.user_roles for select
  using (auth.uid() = id);

drop policy if exists "Admins can read all roles" on public.user_roles;
create policy "Admins can read all roles"
  on public.user_roles for select
  using (
    exists (
      select 1 from public.user_roles
      where id = auth.uid() and role = 'admin'
    )
  );


-- Create Transactions Table
create table if not exists public.transactions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  admin_id uuid references auth.users on delete set null, -- Nullable until claimed
  type public.transaction_type not null,
  status public.transaction_status default 'pending'::public.transaction_status not null,
  amount_fiat numeric(20, 2) not null,
  amount_crypto numeric(20, 8), -- High precision for crypto
  currency_pair text not null, -- e.g. "BTC/USD", "USDT/NGN"
  details jsonb default '{}'::jsonb not null, -- Stores variable data (bank details, wallet addr)
  proof_image_path text, -- Path in storage bucket
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- Indexes for performance
create index transactions_user_id_idx on public.transactions(user_id);
create index transactions_admin_id_idx on public.transactions(admin_id);
create index transactions_status_idx on public.transactions(status);

-- Enable RLS
alter table public.transactions enable row level security;

-- Policies
drop policy if exists "Users can view their own transactions" on public.transactions;
create policy "Users can view their own transactions"
  on public.transactions for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own transactions" on public.transactions;
create policy "Users can insert their own transactions"
  on public.transactions for insert
  with check (auth.uid() = user_id);

drop policy if exists "Admins can view all transactions" on public.transactions;
create policy "Admins can view all transactions"
  on public.transactions for select
  using (
    exists (
      select 1 from public.user_roles
      where id = auth.uid() and role = 'admin'
    )
  );

drop policy if exists "Admins can update all transactions" on public.transactions;
create policy "Admins can update all transactions"
  on public.transactions for update
  using (
    exists (
      select 1 from public.user_roles
      where id = auth.uid() and role = 'admin'
    )
  );


-- Create Transaction Logs Table
create table if not exists public.transaction_logs (
  id uuid default gen_random_uuid() primary key,
  transaction_id uuid references public.transactions on delete cascade not null,
  actor_id uuid references auth.users on delete set null not null, -- Who did it
  previous_status public.transaction_status,
  new_status public.transaction_status not null,
  note text,
  created_at timestamptz default now() not null
);

-- Index
create index transaction_logs_transaction_id_idx on public.transaction_logs(transaction_id);

-- Enable RLS
alter table public.transaction_logs enable row level security;

-- Policies
drop policy if exists "Users can view logs for their transactions" on public.transaction_logs;
create policy "Users can view logs for their transactions"
  on public.transaction_logs for select
  using (
    exists (
      select 1 from public.transactions
      where id = transaction_logs.transaction_id
      and user_id = auth.uid()
    )
  );

drop policy if exists "Admins can view all logs" on public.transaction_logs;
create policy "Admins can view all logs"
  on public.transaction_logs for select
  using (
    exists (
      select 1 from public.user_roles
      where id = auth.uid() and role = 'admin'
    )
  );

drop policy if exists "Admins and Users can insert logs" on public.transaction_logs;
create policy "Admins and Users can insert logs"
  on public.transaction_logs for insert
  with check (auth.uid() = actor_id);


-- Function to automatically update transactions.updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_transaction_updated on public.transactions;
create trigger on_transaction_updated
  before update on public.transactions
  for each row execute procedure public.handle_updated_at();
