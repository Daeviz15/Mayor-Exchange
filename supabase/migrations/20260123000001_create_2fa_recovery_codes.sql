-- Create a table for recovery codes
CREATE TABLE IF NOT EXISTS public.user_2fa_recovery_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    code_hash TEXT NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_2fa_recovery_codes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see their own codes (hashes)
CREATE POLICY "Users can see their own recovery codes" 
    ON public.user_2fa_recovery_codes 
    FOR SELECT 
    USING (auth.uid() = user_id);

-- Policy: Users can manage their own codes
CREATE POLICY "Users can manage their own recovery codes" 
    ON public.user_2fa_recovery_codes 
    FOR ALL 
    USING (auth.uid() = user_id);
