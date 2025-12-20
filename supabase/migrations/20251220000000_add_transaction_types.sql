-- Add new values to the enum
ALTER TYPE public.transaction_type ADD VALUE IF NOT EXISTS 'deposit';
ALTER TYPE public.transaction_type ADD VALUE IF NOT EXISTS 'withdrawal';
