-- Additive: default shop_brands.tint_strength 75 (was 40).
-- Paste as the project owner. No service_role. Does not wipe Joshua’s log.
-- Rewrites only rows still at the old default (40) or NULL. Custom values stay.

ALTER TABLE public.shop_brands
  ADD COLUMN IF NOT EXISTS tint_strength smallint;

UPDATE public.shop_brands
SET tint_strength = 75
WHERE tint_strength IS NULL OR tint_strength = 40;

ALTER TABLE public.shop_brands
  ALTER COLUMN tint_strength SET DEFAULT 75;

ALTER TABLE public.shop_brands
  ALTER COLUMN tint_strength SET NOT NULL;

ALTER TABLE public.shop_brands
  DROP CONSTRAINT IF EXISTS shop_brands_tint_strength_chk;

ALTER TABLE public.shop_brands
  ADD CONSTRAINT shop_brands_tint_strength_chk
  CHECK (tint_strength BETWEEN 0 AND 100);

COMMENT ON COLUMN public.shop_brands.tint_strength IS
  '0–100 logo wash mix. 0 = barely there, 75 = default, 100 = strongest readable.';
