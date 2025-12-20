-- Function to simulate a deposit (admin or dev tool)
create or replace function public.add_deposit(
  user_id uuid,
  amount numeric
)
returns void as $$
begin
  insert into public.transactions (
    user_id,
    type,
    status,
    amount_fiat,
    currency_pair,
    details
  ) values (
    user_id,
    'deposit',
    'completed',
    amount,
    'NGN',
    '{"method": "manual_credit"}'::jsonb
  );
end;
$$ language plpgsql;
