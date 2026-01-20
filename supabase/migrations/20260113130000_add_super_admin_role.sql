-- Add super_admin role support
-- Super admins can: view admin performance, manage admins, access sensitive settings

-- First, add 'super_admin' to the app_role enum
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'super_admin';

-- Create a function to check if user is super_admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE id = auth.uid()
    AND role = 'super_admin'
  );
$$;

-- Update user_roles policies to allow super_admin management
DROP POLICY IF EXISTS "Super admins can manage roles" ON public.user_roles;
CREATE POLICY "Super admins can manage roles"
  ON public.user_roles
  FOR ALL
  USING ( public.is_super_admin() );

-- Grant super_admin access to all admin functions too (super_admin is a superset of admin)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE id = auth.uid()
    AND role IN ('admin', 'super_admin')
  );
$$;
