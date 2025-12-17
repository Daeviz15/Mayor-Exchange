-- Fix infinite recursion in user_roles policy by using a SECURITY DEFINER function

-- 1. Create a secure function to check admin status (bypasses RLS)
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public -- Secure search path
as $$
  select exists (
    select 1 from public.user_roles
    where id = auth.uid()
    and role = 'admin'
  );
$$;

-- 2. Drop the recursive policy if it exists
drop policy if exists "Admins can read all roles" on public.user_roles;

-- 3. Re-create the policy using the secure function
create policy "Admins can read all roles"
  on public.user_roles
  for select
  using ( public.is_admin() );

-- 4. Also update transaction policies to use the safe function (optimization)
drop policy if exists "Admins can view all transactions" on public.transactions;
create policy "Admins can view all transactions"
  on public.transactions for select
  using ( public.is_admin() );

drop policy if exists "Admins can update all transactions" on public.transactions;
create policy "Admins can update all transactions"
  on public.transactions for update
  using ( public.is_admin() );

drop policy if exists "Admins can view all logs" on public.transaction_logs;
create policy "Admins can view all logs"
  on public.transaction_logs for select
  using ( public.is_admin() );
