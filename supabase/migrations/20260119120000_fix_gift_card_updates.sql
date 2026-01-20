-- =====================================================
-- FIX: Gift Card Rate Updates Not Saving
-- Run this in Supabase SQL Editor
-- =====================================================

BEGIN;

-- 1. Ensure all required columns exist
ALTER TABLE public.gift_cards ADD COLUMN IF NOT EXISTS buy_rate numeric DEFAULT 0;
ALTER TABLE public.gift_cards ADD COLUMN IF NOT EXISTS physical_rate numeric DEFAULT 0;
ALTER TABLE public.gift_cards ADD COLUMN IF NOT EXISTS ecode_rate numeric DEFAULT 0;
ALTER TABLE public.gift_cards ADD COLUMN IF NOT EXISTS min_value numeric DEFAULT 5;
ALTER TABLE public.gift_cards ADD COLUMN IF NOT EXISTS max_value numeric DEFAULT 500;
ALTER TABLE public.gift_cards ADD COLUMN IF NOT EXISTS allowed_denominations numeric[] DEFAULT '{}';

-- 2. Fix RLS Policy - Allow both admin AND super_admin to manage
DROP POLICY IF EXISTS "Admins can manage gift cards" ON public.gift_cards;

CREATE POLICY "Admins can manage gift cards"
    ON public.gift_cards
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles
            WHERE user_roles.id = auth.uid()
            AND user_roles.role IN ('admin', 'super_admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_roles
            WHERE user_roles.id = auth.uid()
            AND user_roles.role IN ('admin', 'super_admin')
        )
    );

-- 3. Enable Realtime for gift_cards table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'gift_cards'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.gift_cards;
  END IF;
END $$;

COMMIT;

-- Verify: Check if realtime is now enabled
SELECT tablename FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' AND tablename = 'gift_cards';
