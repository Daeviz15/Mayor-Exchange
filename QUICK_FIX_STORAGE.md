# Quick Fix: Storage RLS Policy Error

## The Error
```
StorageException: new row violates row-level security policy (403 Unauthorized)
```

## Quick Fix (2 Minutes)

### Step 1: Verify Your Setup
1. Go to **Supabase Dashboard** → **SQL Editor**
2. Copy and paste the contents of `verify_storage_setup.sql`
3. Click **Run**
4. Check the results:
   - ✅ Bucket exists and is public
   - ✅ RLS is enabled
   - ✅ 4 policies exist
   - ✅ You're authenticated

### Step 2: Fix Missing Policies
If policies are missing or incorrect:

**Option A: Simple Fix (Recommended First)**
1. Copy contents of `supabase_storage_policies_simple.sql`
2. Paste in SQL Editor
3. Click **Run**
4. Try uploading profile picture again

**Option B: Secure Fix (After Option A Works)**
1. Copy contents of `supabase_storage_policies.sql`
2. Paste in SQL Editor
3. Click **Run**
4. This restricts users to their own folders

### Step 3: Verify Bucket Settings
1. Go to **Storage** → **profile-images**
2. Click **Settings**
3. Ensure **"Public bucket"** toggle is **ON**
4. If bucket doesn't exist, create it:
   - Click **New bucket**
   - Name: `profile-images`
   - Toggle **Public bucket** to **ON**
   - Click **Create bucket**

### Step 4: Test
1. Go back to your app
2. Try uploading a profile picture
3. Should work now! ✅

## Still Not Working?

1. **Check you're logged in**: The error only happens for authenticated users
2. **Check bucket name**: Must be exactly `profile-images` (case-sensitive)
3. **Re-run the SQL script**: Sometimes policies need to be recreated
4. **Check Supabase logs**: Go to Dashboard → Logs → Storage to see detailed errors

## Files Reference
- `supabase_storage_policies_simple.sql` - Simple policies (all authenticated users)
- `supabase_storage_policies.sql` - Secure policies (folder-based)
- `verify_storage_setup.sql` - Verification script
- `SUPABASE_STORAGE_SETUP.md` - Full detailed guide

