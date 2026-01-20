-- =====================================================
-- FIX: Storage Upload Permissions for Super Admin
-- Run this in Supabase SQL Editor
-- =====================================================

BEGIN;

-- 1. Ensure the bucket exists (idempotent)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('gift-card-images', 'gift-card-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Drop existing restrictive policies
DROP POLICY IF EXISTS "Anyone can view gift card images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload gift card images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update gift card images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete gift card images" ON storage.objects;

-- 3. Re-create policies allowing 'admin' AND 'super_admin'

-- Policy 1: Public Read Access
CREATE POLICY "Anyone can view gift card images"
ON storage.objects FOR SELECT
USING ( bucket_id = 'gift-card-images' );

-- Policy 2: Admin/SuperAdmin Upload Access
CREATE POLICY "Admins can upload gift card images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'gift-card-images' AND
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_roles.id = auth.uid() 
        AND user_roles.role IN ('admin', 'super_admin')
    )
);

-- Policy 3: Admin/SuperAdmin Update Access
CREATE POLICY "Admins can update gift card images"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'gift-card-images' AND
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_roles.id = auth.uid() 
        AND user_roles.role IN ('admin', 'super_admin')
    )
)
WITH CHECK (
    bucket_id = 'gift-card-images' AND
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_roles.id = auth.uid() 
        AND user_roles.role IN ('admin', 'super_admin')
    )
);

-- Policy 4: Admin/SuperAdmin Delete Access
CREATE POLICY "Admins can delete gift card images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'gift-card-images' AND
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_roles.id = auth.uid() 
        AND user_roles.role IN ('admin', 'super_admin')
    )
);

COMMIT;
