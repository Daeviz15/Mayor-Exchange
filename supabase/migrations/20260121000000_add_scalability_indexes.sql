-- =====================================================
-- Add Missing Indexes for Scalability
-- Run this in Supabase SQL Editor or via migration
-- =====================================================

-- 1. Notifications table - heavily queried by user_id
CREATE INDEX IF NOT EXISTS notifications_user_id_idx 
  ON public.notifications(user_id);

-- 2. Notifications - composite index for common pattern (user's unread notifications)
CREATE INDEX IF NOT EXISTS notifications_user_read_idx 
  ON public.notifications(user_id, is_read);

-- 3. Gift card denomination rates - queried by variant_id
CREATE INDEX IF NOT EXISTS denomination_rates_variant_id_idx 
  ON public.gift_card_denomination_rates(variant_id);

-- 4. Transactions - for sorting by updated_at (admin dashboard, history)
CREATE INDEX IF NOT EXISTS transactions_updated_at_idx 
  ON public.transactions(updated_at DESC);

-- 5. Transactions - composite index for user's transactions by status
CREATE INDEX IF NOT EXISTS transactions_user_status_idx 
  ON public.transactions(user_id, status);

-- 6. KYC requests - user lookups
CREATE INDEX IF NOT EXISTS kyc_requests_user_id_idx 
  ON public.kyc_requests(user_id);

-- 7. Gift card variants - for efficient variant lookups by parent
CREATE INDEX IF NOT EXISTS variants_parent_card_idx 
  ON public.gift_card_variants(parent_card_id);
