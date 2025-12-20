-- Add new statuses to the transaction_status enum
DO $$
BEGIN
    ALTER TYPE "public"."transaction_status" ADD VALUE IF NOT EXISTS 'payment_pending';
    ALTER TYPE "public"."transaction_status" ADD VALUE IF NOT EXISTS 'verification_pending';
    ALTER TYPE "public"."transaction_status" ADD VALUE IF NOT EXISTS 'claimed';
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
