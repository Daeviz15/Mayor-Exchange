-- Supabase Storage RLS Policies for profile-images bucket
-- Run this script in your Supabase SQL Editor to set up the storage policies

-- Step 1: Ensure RLS is enabled on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if they exist (optional, for clean setup)
DROP POLICY IF EXISTS "Users can upload their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Public can read profile images" ON storage.objects;

-- Step 3: Create INSERT policy - Allow authenticated users to upload files to their own folder
-- Using multiple approaches to ensure it works
CREATE POLICY "Users can upload their own profile images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' 
  AND (
    -- Check if path starts with user ID followed by /
    name LIKE auth.uid()::text || '/%'
    OR
    -- Alternative: extract first folder from path
    (string_to_array(name, '/'))[1] = auth.uid()::text
  )
);

-- Step 4: Create UPDATE policy - Allow authenticated users to update their own files
CREATE POLICY "Users can update their own profile images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (
    name LIKE auth.uid()::text || '/%'
    OR
    (string_to_array(name, '/'))[1] = auth.uid()::text
  )
)
WITH CHECK (
  bucket_id = 'profile-images' 
  AND (
    name LIKE auth.uid()::text || '/%'
    OR
    (string_to_array(name, '/'))[1] = auth.uid()::text
  )
);

-- Step 5: Create DELETE policy - Allow authenticated users to delete their own files
CREATE POLICY "Users can delete their own profile images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (
    name LIKE auth.uid()::text || '/%'
    OR
    (string_to_array(name, '/'))[1] = auth.uid()::text
  )
);

-- Step 6: Create SELECT policy - Allow public read access to all profile images
CREATE POLICY "Public can read profile images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- Verify policies were created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname;

