-- Create Buckets
insert into storage.buckets (id, name, public)
values
  ('transaction-proofs', 'transaction-proofs', false),
  ('gift-cards', 'gift-cards', false)
on conflict (id) do nothing;



-- Policy: Users can upload their own proofs
drop policy if exists "Users can upload their own proofs" on storage.objects;
create policy "Users can upload their own proofs"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'transaction-proofs'
    and (string_to_array(name, '/'))[1] = auth.uid()::text
  );

-- Policy: Users can view their own proofs
drop policy if exists "Users can view their own proofs" on storage.objects;
create policy "Users can view their own proofs"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'transaction-proofs'
    and (string_to_array(name, '/'))[1] = auth.uid()::text
  );

-- Policy: Admins can view all proofs
drop policy if exists "Admins can view all proofs" on storage.objects;
create policy "Admins can view all proofs"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'transaction-proofs'
    and exists (
      select 1 from public.user_roles where id = auth.uid() and role = 'admin'
    )
  );


-- Policy: Users can upload their own gift cards (for selling)
drop policy if exists "Users can upload their own gift cards" on storage.objects;
create policy "Users can upload their own gift cards"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'gift-cards'
    and (string_to_array(name, '/'))[1] = auth.uid()::text
  );

-- Policy: Users can view their own gift cards
drop policy if exists "Users can view their own gift cards" on storage.objects;
create policy "Users can view their own gift cards"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'gift-cards'
    and (string_to_array(name, '/'))[1] = auth.uid()::text
  );

-- Policy: Admins can view all gift cards
drop policy if exists "Admins can view all gift cards" on storage.objects;
create policy "Admins can view all gift cards"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'gift-cards'
    and exists (
      select 1 from public.user_roles where id = auth.uid() and role = 'admin'
    )
  );
