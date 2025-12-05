# Supabase Storage Setup Guide

## Profile Images Bucket Configuration

This guide will help you set up the `profile-images` bucket in Supabase Storage to store user profile pictures persistently.

### Step 1: Create the Storage Bucket

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your **Mayor Exchange** project
3. Navigate to **Storage** in the left sidebar
4. Click **New bucket**
5. Enter the bucket name: `profile-images`
6. Set the bucket to **Public** (so profile images can be accessed via public URLs)
7. Click **Create bucket**

### Step 2: Configure Bucket Policies

1. After creating the bucket, click on it to open bucket settings
2. Go to the **Policies** tab
3. Click **New Policy** and create the following policies:

#### Policy 1: Allow authenticated users to upload their own profile images
- **Policy name**: `Users can upload their own profile images`
- **Allowed operation**: `INSERT`
- **Target roles**: `authenticated`
- **Policy definition**:
```sql
bucket_id = 'profile-images' AND (storage.foldername(name))[1] = auth.uid()::text
```

**Alternative (if the above doesn't work, use this):**
```sql
bucket_id = 'profile-images' AND (string_to_array(name, '/'))[1] = auth.uid()::text
```

#### Policy 2: Allow authenticated users to update their own profile images
- **Policy name**: `Users can update their own profile images`
- **Allowed operation**: `UPDATE`
- **Target roles**: `authenticated`
- **Policy definition**:
```sql
bucket_id = 'profile-images' AND (storage.foldername(name))[1] = auth.uid()::text
```

**Alternative:**
```sql
bucket_id = 'profile-images' AND (string_to_array(name, '/'))[1] = auth.uid()::text
```

#### Policy 3: Allow authenticated users to delete their own profile images
- **Policy name**: `Users can delete their own profile images`
- **Allowed operation**: `DELETE`
- **Target roles**: `authenticated`
- **Policy definition**:
```sql
bucket_id = 'profile-images' AND (storage.foldername(name))[1] = auth.uid()::text
```

**Alternative:**
```sql
bucket_id = 'profile-images' AND (string_to_array(name, '/'))[1] = auth.uid()::text
```

#### Policy 4: Allow public read access to profile images
- **Policy name**: `Public can read profile images`
- **Allowed operation**: `SELECT`
- **Target roles**: `public` (or leave empty for public access)
- **Policy definition**:
```sql
bucket_id = 'profile-images'
```

### Step 2.5: Quick Setup via SQL Editor (Recommended - Easiest Method)

**IMPORTANT: If you're getting RLS policy errors, try the SIMPLIFIED version first:**

#### Option A: Simplified Policies (Try This First - Less Secure but Works Immediately)

1. Go to **SQL Editor** in your Supabase Dashboard
2. Copy and paste the contents of `supabase_storage_policies_simple.sql` from the project root
3. Click **Run** to execute the script
4. This allows all authenticated users to upload/update/delete in the bucket (less secure but works)
5. Verify that 4 policies were created

#### Option B: Folder-Based Policies (More Secure - Use After Option A Works)

1. Go to **SQL Editor** in your Supabase Dashboard
2. Copy and paste the contents of `supabase_storage_policies.sql` from the project root
3. Click **Run** to execute the script
4. This restricts users to only their own folder (more secure)
5. Verify that 4 policies were created

**OR manually run these SQL commands:**

```sql
-- Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow authenticated users to INSERT their own files
CREATE POLICY "Users can upload their own profile images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' 
  AND (string_to_array(name, '/'))[1] = auth.uid()::text
);

-- Policy 2: Allow authenticated users to UPDATE their own files
CREATE POLICY "Users can update their own profile images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (string_to_array(name, '/'))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'profile-images' 
  AND (string_to_array(name, '/'))[1] = auth.uid()::text
);

-- Policy 3: Allow authenticated users to DELETE their own files
CREATE POLICY "Users can delete their own profile images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (string_to_array(name, '/'))[1] = auth.uid()::text
);

-- Policy 4: Allow public SELECT (read) access
CREATE POLICY "Public can read profile images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-images');
```

### Step 3: Verify Configuration

1. The bucket structure will be: `profile-images/{userId}/{timestamp}.jpg`
2. Each user's images are stored in their own folder (identified by their user ID)
3. Images are publicly accessible via the public URL returned by Supabase Storage

### How It Works

- When a user uploads a profile picture:
  1. The image is compressed locally
  2. Uploaded to Supabase Storage in the `profile-images` bucket
  3. The public URL is stored in the user's metadata (`avatar_url`)
  4. The URL is cached locally for offline access

- When a user logs in:
  1. The app checks user metadata for `avatar_url`
  2. If found, displays the image from Supabase Storage
  3. Falls back to local cache if available

- Images persist across logins because they're stored in Supabase Storage and the URL is saved in user metadata.

### Troubleshooting

**Issue**: `StorageException: new row violates row-level security policy (403 Unauthorized)`
- **Cause**: RLS policies are not configured or are incorrectly set up
- **Solution**: 
  1. **FIRST**: Verify your setup by running `verify_storage_setup.sql` in SQL Editor
  2. **If bucket doesn't exist**: Create it in Storage → New bucket → Name: `profile-images` → Set to Public
  3. **If policies don't exist**: 
     - Try `supabase_storage_policies_simple.sql` first (easier, works immediately)
     - If that works, you can upgrade to `supabase_storage_policies.sql` for folder-based security
  4. **Verify policies were created**: Run the verification script or:
     ```sql
     SELECT policyname FROM pg_policies 
     WHERE tablename = 'objects' AND schemaname = 'storage';
     ```
     You should see 4 policies listed
  5. **Check bucket is public**: Go to Storage → profile-images → Settings → Ensure "Public bucket" is enabled
  6. **Ensure you're authenticated**: The app must be logged in (check auth.uid() is not null)

**Issue**: Images not uploading
- **Solution**: 
  1. Check that the bucket policies are correctly configured (use SQL script above)
  2. Verify the bucket is set to **Public**
  3. Ensure you're authenticated (check `auth.uid()` is not null)
  4. Verify the file path format matches: `{userId}/{timestamp}.jpg`

**Issue**: Images not displaying
- **Solution**: 
  1. Verify that the public read policy is enabled
  2. Check that the bucket is set to **Public**
  3. Verify the public URL is correctly formatted

**Issue**: Permission denied errors (403)
- **Solution**: 
  1. Run the SQL policies script again
  2. Ensure the user is authenticated
  3. Check that `auth.uid()` matches the folder name in the file path
  4. Verify RLS is enabled: `ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;`

**Issue**: Still getting errors after setting up policies
- **Solution**:
  1. Check Supabase Dashboard → Storage → Policies tab
  2. Verify all 4 policies exist and are enabled
  3. Try deleting and recreating the policies using the SQL script
  4. Ensure the bucket name is exactly `profile-images` (case-sensitive)

