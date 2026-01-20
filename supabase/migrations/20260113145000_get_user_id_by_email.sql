-- Create an RPC function to get user ID from email address
-- This is needed because auth.users is not directly accessible from client

CREATE OR REPLACE FUNCTION public.get_user_id_by_email(user_email text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  found_user_id uuid;
BEGIN
  SELECT id INTO found_user_id
  FROM auth.users
  WHERE email = lower(trim(user_email))
  LIMIT 1;
  
  RETURN found_user_id;
END;
$$;

-- Grant execute permission to authenticated users (super admins will use this)
GRANT EXECUTE ON FUNCTION public.get_user_id_by_email(text) TO authenticated;
