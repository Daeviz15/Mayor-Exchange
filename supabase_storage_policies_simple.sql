-- SIMPLIFIED Supabase Storage RLS Policies for profile-images bucket
-- This version allows all authenticated users to upload/update/delete in the bucket
-- Use this if the folder-based policies don't work
-- Run this script in your Supabase SQL Editor

-- Step 1: Ensure RLS is enabled on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if they exist
DROP POLICY IF EXISTS "Authenticated users can upload profile images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update profile images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete profile images" ON storage.objects;
DROP POLICY IF EXISTS "Public can read profile images" ON storage.objects;

-- Step 3: Create INSERT policy - Allow ALL authenticated users to upload to bucket
CREATE POLICY "Authenticated users can upload profile images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile-images');

-- Step 4: Create UPDATE policy - Allow ALL authenticated users to update files in bucket
CREATE POLICY "Authenticated users can update profile images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'profile-images')
WITH CHECK (bucket_id = 'profile-images');

-- Step 5: Create DELETE policy - Allow ALL authenticated users to delete files in bucket
CREATE POLICY "Authenticated users can delete profile images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'profile-images');

-- Step 6: Create SELECT policy - Allow public read access to all profile images
CREATE POLICY "Public can read profile images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- Verify policies were created
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname;

