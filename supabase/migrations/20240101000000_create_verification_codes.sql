-- Create a table to store verification codes
create table if not exists public.verification_codes (
  id uuid default gen_random_uuid() primary key,
  email text not null,
  code text not null,
  type text not null check (type in ('reset', 'signup')),
  expires_at timestamp with time zone not null,
  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.verification_codes enable row level security;

-- Policies
-- Allow anyone to insert (controlled by Edge Function logic mostly, but needed for public access if we were doing it clientside - here we are doing it via Service Role in Edge Function so RLS is bypassed, but good to have)
-- Actually, since we will access this ONLY from the Edge Function (Service Role), we don't strictly need public policies. 
-- However, we should restrict public access entirely.

drop policy if exists "Service role has full access" on public.verification_codes;

create policy "Service role has full access"
  on public.verification_codes
  for all
  using ( auth.role() = 'service_role' );

-- Index for faster lookups
create index if not exists verification_codes_email_idx on public.verification_codes (email);
create index if not exists verification_codes_code_idx on public.verification_codes (code);

-- RPC to get user ID by email (Security Definer to access auth.users)
create or replace function public.get_user_id_by_email(email_arg text)
returns uuid
language plpgsql
security definer
as $$
declare
  _id uuid;
begin
  select id into _id from auth.users where email = email_arg;
  return _id;
end;
$$;
