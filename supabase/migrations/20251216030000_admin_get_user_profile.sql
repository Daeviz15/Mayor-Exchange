-- Secure function for Admins to fetch user details (Name, Email, Metadata)
-- This avoids exposing the entire auth.users table directly.

CREATE OR REPLACE FUNCTION public.get_user_profile(target_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_is_admin BOOLEAN;
  result JSONB;
BEGIN
  -- 1. Check if the caller is an admin
  SELECT public.is_admin() INTO current_is_admin;
  
  IF NOT current_is_admin THEN
    RAISE EXCEPTION 'Access Denied: Only Admins can fetch user profiles.';
  END IF;

  -- 2. Fetch the user details
  SELECT jsonb_build_object(
    'id', id,
    'email', email,
    'full_name', COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', raw_user_meta_data->>'fullName'),
    'phone', raw_user_meta_data->>'phone_number',
    'created_at', created_at
  ) INTO result
  FROM auth.users
  WHERE id = target_user_id;

  RETURN result;
END;
$$;
