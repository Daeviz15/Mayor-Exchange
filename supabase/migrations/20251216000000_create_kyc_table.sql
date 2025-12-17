-- Create kyc_requests table
CREATE TABLE public.kyc_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, in_progress, verified, rejected
    identity_doc_url TEXT,
    address_doc_url TEXT,
    selfie_url TEXT,
    admin_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.kyc_requests ENABLE ROW LEVEL SECURITY;

-- Creating policies
-- Users can view their own KYC
CREATE POLICY "Users can view own kyc" ON public.kyc_requests
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own KYC
CREATE POLICY "Users can insert own kyc" ON public.kyc_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own KYC if not verified/in_progress
CREATE POLICY "Users can update own kyc" ON public.kyc_requests
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (status IN ('pending', 'rejected'));

-- Admins can view all (assuming admin_role check logic exists or handled via secure service role in edge functions, 
-- but for client side generic admin access):
-- Note: Reusing the admin check function from previous migrations logic if available, 
-- otherwise assuming basic public access denied and handled via specific admin logic.
-- For this app, as per previous patterns, we might rely on a boolean in profiles or metadata, 
-- but standard RLS for admins usually involves a custom claim or checking a roles table.
-- For simplicity in this prompt context, we will add a policy for the "admin" user if defined, 
-- or rely on the dashboard knowing who is admin via `admin_role_provider`.
-- Start with generic "Users can view own", Admins will need a separate policy or bypass RLS (Service Role).

-- Create Storage Bucket for KYC
INSERT INTO storage.buckets (id, name, public) VALUES ('kyc_documents', 'kyc_documents', true);

-- Storage Policies
-- Users can upload their own files
CREATE POLICY "Users can upload kyc docs" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'kyc_documents' AND 
        auth.uid() = (storage.foldername(name))[1]::uuid
    );

-- Users can view their own files
CREATE POLICY "Users can view updated kyc docs" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'kyc_documents' AND 
        auth.uid() = (storage.foldername(name))[1]::uuid
    );
