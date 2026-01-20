-- Create a function to safely fetch user display name from auth.users metadata
-- This is needed because RLS prevents direct access to auth.users from client

CREATE OR REPLACE FUNCTION public.get_user_display_info(user_id uuid)
RETURNS TABLE(
  display_name text,
  email text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(
      raw_user_meta_data->>'full_name',
      raw_user_meta_data->>'name',
      CONCAT(raw_user_meta_data->>'firstName', ' ', raw_user_meta_data->>'lastName'),
      split_part(users.email, '@', 1)
    )::text as display_name,
    users.email::text
  FROM auth.users
  WHERE id = user_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_user_display_info(uuid) TO authenticated;
