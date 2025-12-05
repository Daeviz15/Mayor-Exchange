# Supabase OAuth Setup Guide

## Issues Fixed

✅ **Password visibility toggle** - Now functional on both login and registration screens
✅ **Email registration error handling** - Improved error messages and prevents blank screens
✅ **Google OAuth error handling** - Better error messages and redirect URL configuration
✅ **"Already have an account? Login"** - Added to registration screen

## Required Supabase Configuration

### 1. Enable Google Provider

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your **Mayor Exchange** project
3. Navigate to **Authentication** → **Providers**
4. Find **Google** in the list
5. Click **Enable** toggle
6. Make sure your **Google OAuth Client ID** and **Client Secret** are filled in (you mentioned you already did this ✅)

### 2. Configure Redirect URLs (branded deep link)

1. In Supabase Dashboard, go to **Authentication** → **URL Configuration**
2. Under **Redirect URLs**, add these URLs:

   **For Android & iOS (custom scheme, matches code):**
   ```
   mayorexchange://login-callback
   ```

   **For Web (if applicable):**
   ```
   http://localhost:3000/auth/callback
   https://yourdomain.com/auth/callback
   ```

3. Click **Save**

### 3. Configure Google OAuth Credentials

Make sure in your Google Cloud Console:

1. **Authorized redirect URIs** includes:
   ```
   https://[YOUR_SUPABASE_PROJECT_REF].supabase.co/auth/v1/callback
   ```

   Replace `[YOUR_SUPABASE_PROJECT_REF]` with your actual Supabase project reference (found in your Supabase project URL).

2. **Authorized JavaScript origins** includes:
   ```
   https://[YOUR_SUPABASE_PROJECT_REF].supabase.co
   ```

### 4. Environment Variables (.env file)

Make sure your `.env` file has:

   ```env
   SUPABASE_URL=https://[YOUR_PROJECT_REF].supabase.co
   SUPABASE_ANON_KEY=your_anon_key_here
   SUPABASE_REDIRECT_URL=mayorexchange://login-callback
   ```

**Note:** The `SUPABASE_REDIRECT_URL` is optional. If not set, Supabase Flutter will use the default mobile redirect URL.

## Testing

1. **Email Sign-Up:**
   - Fill in email, password, and confirm password
   - Click "Sign Up"
   - You should see a success message
   - Check your email for verification (if email confirmation is enabled)
   - User should appear in Supabase Dashboard → Authentication → Users

2. **Google Sign-In:**
   - Click the Google sign-in button
   - Browser should open for Google authentication
   - After successful authentication, you should be redirected back to the app
   - User should appear in Supabase Dashboard → Authentication → Users

## Troubleshooting

### "Provider is not enabled" Error
- **Solution:** Make sure Google provider is enabled in Supabase Dashboard → Authentication → Providers

### Blank Screen After Sign-Up
- **Fixed:** Improved error handling now shows clear error messages
- If you still see issues, check the console/logs for detailed error messages

### Google OAuth Not Redirecting Back
- **Check:** Redirect URLs are configured correctly in Supabase (include `mayorexchange://login-callback`)
- **Check:** Google OAuth credentials have the correct redirect URI
- **Check:** Deep link configuration in AndroidManifest.xml and Info.plist (already configured ✅)

### User Not Appearing in Supabase
- **Check:** Email confirmation might be required - check your email
- **Check:** Supabase Dashboard → Authentication → Users
- **Check:** Authentication → Policies might be blocking user creation

## Package Name

Your current Android package name is: `com.example.mayor_exchange`

If you change this, update:
1. `android/app/build.gradle.kts` - `applicationId`
2. `android/app/src/main/AndroidManifest.xml` - deep link scheme
3. `ios/Runner/Info.plist` - URL scheme
4. Supabase redirect URLs
5. `.env` file - `SUPABASE_REDIRECT_URL`

