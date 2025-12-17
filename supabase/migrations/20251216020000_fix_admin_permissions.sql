-- 1. Create user_roles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID REFERENCES auth.users(id) NOT NULL PRIMARY KEY,
    role TEXT NOT NULL CHECK (role IN ('admin', 'user')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable RLS on user_roles
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 3. Allow users to read their own role (Critical for client-side checks)
DROP POLICY IF EXISTS "Users can read own role" ON public.user_roles;
CREATE POLICY "Users can read own role" ON public.user_roles
    FOR SELECT USING (auth.uid() = id);

-- 4. Create a secure function to check if current user is admin
-- SECURITY DEFINER means it runs with permissions of creator (db admin), bypassing RLS recursion issues
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Add Admin Policies to kyc_requests table

-- Admin UPDATE Policy
DROP POLICY IF EXISTS "Admins can update kyc" ON public.kyc_requests;
CREATE POLICY "Admins can update kyc" ON public.kyc_requests
    FOR UPDATE USING (public.is_admin());

-- Admin SELECT Policy (View All)
DROP POLICY IF EXISTS "Admins can view all kyc" ON public.kyc_requests;
CREATE POLICY "Admins can view all kyc" ON public.kyc_requests
    FOR SELECT USING (public.is_admin());

-- 6. Helper: INSERT your own user as admin (Replace EMAIL with your login email)
-- Uncomment the lines below and run in SQL Editor with your email:

-- INSERT INTO public.user_roles (id, role)
-- VALUES (
--   (SELECT id FROM auth.users WHERE email = 'your_email@example.com' LIMIT 1),
--   'admin'
-- )
-- ON CONFLICT (id) DO UPDATE SET role = 'admin';
