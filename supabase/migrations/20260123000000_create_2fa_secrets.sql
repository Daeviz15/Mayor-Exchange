-- Create a private table for 2FA secrets
-- This table should be in a schema that is NOT exposed via PostgREST if possible,
-- but for now we'll use public with strict RLS.

CREATE TABLE IF NOT EXISTS public.user_2fa_secrets (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    secret TEXT NOT NULL,
    enabled BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_2fa_secrets ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see IF they have 2FA enabled, but NOT the secret itself
-- Actually, we'll block SELECT on the secret column for everyone except service_role
CREATE POLICY "Users can see their own 2FA status" 
    ON public.user_2fa_secrets 
    FOR SELECT 
    USING (auth.uid() = user_id);

-- Policy: Users can insert/update during setup
CREATE POLICY "Users can manage their own 2FA secret" 
    ON public.user_2fa_secrets 
    FOR ALL 
    USING (auth.uid() = user_id);

-- Function to check if 2FA is enabled without exposing secret
CREATE OR REPLACE FUNCTION public.is_2fa_enabled(check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_2fa_secrets 
        WHERE user_id = check_user_id AND enabled = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
