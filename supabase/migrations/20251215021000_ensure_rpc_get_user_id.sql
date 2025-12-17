-- Create a function to get user ID by email securely (security definer to access auth.users)
create or replace function public.get_user_id_by_email(email_arg text)
returns uuid
language plpgsql
security definer
as $$
declare
  user_id_result uuid;
begin
  select id into user_id_result
  from auth.users
  where email = email_arg
  limit 1;
  
  return user_id_result;
end;
$$;
