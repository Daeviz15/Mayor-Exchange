-- Enable Realtime for admin_rates table so the app receives live updates
begin;
  -- Check if table is already in publication to avoid errors (postgres doesn't have 'add if not exists' for publication tables easily, but direct add is safe enough usually as it effectively is idempotent or throws specific error we can ignore in migration script if we wrapped it, but here we just run it).
  -- Actually, cleanest way is just to run it.
  alter publication supabase_realtime add table public.admin_rates;
commit;
