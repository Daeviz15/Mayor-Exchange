-- Verification Script for Supabase Storage Setup
-- Run this to check if everything is configured correctly

-- 1. Check if bucket exists
SELECT 
  name as bucket_name,
  public as is_public,
  created_at
FROM storage.buckets
WHERE name = 'profile-images';

-- 2. Check if RLS is enabled
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'storage' AND tablename = 'objects';

-- 3. List all policies on storage.objects
SELECT 
  policyname,
  cmd as operation,
  roles,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname;

-- 4. Check current user authentication
SELECT 
  auth.uid() as current_user_id,
  auth.role() as current_role;

-- Expected Results:
-- 1. Should show 1 row with bucket 'profile-images' and is_public = true
-- 2. Should show rls_enabled = true
-- 3. Should show 4 policies (INSERT, UPDATE, DELETE, SELECT)
-- 4. Should show your user ID and role 'authenticated' (if logged in)

