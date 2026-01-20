-- =====================================================
-- Apple Gift Card Variants - Database Schema
-- Run this in Supabase SQL Editor
-- =====================================================

BEGIN;

-- 1. Create gift_card_variants table
-- Stores the 4 Apple variants (Normal, Vertical, Ecode, Code)
CREATE TABLE IF NOT EXISTS public.gift_card_variants (
  id TEXT PRIMARY KEY,                              -- e.g., 'apple-normal'
  parent_card_id TEXT REFERENCES public.gift_cards(id) ON DELETE CASCADE,
  name TEXT NOT NULL,                               -- 'AppleCard Normal'
  description TEXT,
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create denomination rates table
-- Stores per-denomination rates for each variant
CREATE TABLE IF NOT EXISTS public.gift_card_denomination_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  variant_id TEXT REFERENCES public.gift_card_variants(id) ON DELETE CASCADE,
  denomination NUMERIC NOT NULL,                    -- e.g., 25, 50, 100
  rate NUMERIC NOT NULL DEFAULT 0,                  -- NGN rate for this denomination
  is_active BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(variant_id, denomination)                  -- One rate per denomination per variant
);

-- 3. Enable RLS
ALTER TABLE public.gift_card_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gift_card_denomination_rates ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for gift_card_variants
-- Anyone can view active variants
CREATE POLICY "Anyone can view active variants" ON public.gift_card_variants
  FOR SELECT USING (is_active = true);

-- Admins can manage variants
CREATE POLICY "Admins can manage variants" ON public.gift_card_variants
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_roles 
      WHERE user_roles.id = auth.uid() 
      AND user_roles.role IN ('admin', 'super_admin')
    )
  );

-- 5. RLS Policies for denomination rates
-- Anyone can view active rates
CREATE POLICY "Anyone can view active rates" ON public.gift_card_denomination_rates
  FOR SELECT USING (is_active = true);

-- Admins can manage rates
CREATE POLICY "Admins can manage rates" ON public.gift_card_denomination_rates
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_roles 
      WHERE user_roles.id = auth.uid() 
      AND user_roles.role IN ('admin', 'super_admin')
    )
  );

-- 6. Enable Realtime for both tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.gift_card_variants;
ALTER PUBLICATION supabase_realtime ADD TABLE public.gift_card_denomination_rates;

-- 7. Add has_variants column to gift_cards table
ALTER TABLE public.gift_cards ADD COLUMN IF NOT EXISTS has_variants BOOLEAN DEFAULT false;

-- 8. Mark Apple card as having variants
UPDATE public.gift_cards SET has_variants = true WHERE id = 'apple';

-- 9. Seed initial Apple variants
INSERT INTO public.gift_card_variants (id, parent_card_id, name, description, display_order) VALUES
  ('apple-normal', 'apple', 'AppleCard Normal', 'Standard physical Apple gift cards', 1),
  ('apple-vertical', 'apple', 'AppleCard Vertical', 'Vertical format Apple gift cards', 2),
  ('apple-ecode', 'apple', 'AppleCard Ecode', 'Digital e-code Apple gift cards', 3),
  ('apple-code', 'apple', 'AppleCard Code', 'Digital code Apple gift cards', 4)
ON CONFLICT (id) DO UPDATE SET 
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  display_order = EXCLUDED.display_order;

-- 10. Seed common denominations for each variant (rates to be set by admin)
-- These are initial denominations, admin can modify rates later
INSERT INTO public.gift_card_denomination_rates (variant_id, denomination, rate) VALUES
  -- AppleCard Normal
  ('apple-normal', 25, 0),
  ('apple-normal', 50, 0),
  ('apple-normal', 100, 0),
  ('apple-normal', 150, 0),
  ('apple-normal', 200, 0),
  ('apple-normal', 250, 0),
  ('apple-normal', 300, 0),
  ('apple-normal', 350, 0),
  ('apple-normal', 400, 0),
  ('apple-normal', 450, 0),
  ('apple-normal', 500, 0),
  -- AppleCard Vertical
  ('apple-vertical', 25, 0),
  ('apple-vertical', 50, 0),
  ('apple-vertical', 100, 0),
  ('apple-vertical', 200, 0),
  ('apple-vertical', 500, 0),
  -- AppleCard Ecode
  ('apple-ecode', 25, 0),
  ('apple-ecode', 50, 0),
  ('apple-ecode', 100, 0),
  ('apple-ecode', 200, 0),
  ('apple-ecode', 500, 0),
  -- AppleCard Code
  ('apple-code', 25, 0),
  ('apple-code', 50, 0),
  ('apple-code', 100, 0),
  ('apple-code', 200, 0),
  ('apple-code', 500, 0)
ON CONFLICT (variant_id, denomination) DO NOTHING;

COMMIT;
