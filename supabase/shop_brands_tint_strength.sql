-- Additive: per-brand logo wash strength (Home + shop-details page).
-- Paste as the project owner. Does not rewrite or delete existing rows.
-- Default 40 matches the previous kLogoWashMix (0.40). No service_role.

ALTER TABLE public.shop_brands
  ADD COLUMN IF NOT EXISTS tint_strength smallint;

UPDATE public.shop_brands
SET tint_strength = 40
WHERE tint_strength IS NULL;

ALTER TABLE public.shop_brands
  ALTER COLUMN tint_strength SET DEFAULT 40;

ALTER TABLE public.shop_brands
  ALTER COLUMN tint_strength SET NOT NULL;

ALTER TABLE public.shop_brands
  DROP CONSTRAINT IF EXISTS shop_brands_tint_strength_chk;

ALTER TABLE public.shop_brands
  ADD CONSTRAINT shop_brands_tint_strength_chk
  CHECK (tint_strength BETWEEN 0 AND 100);

COMMENT ON COLUMN public.shop_brands.tint_strength IS
  '0–100 logo wash mix. 0 = barely there, 40 = previous default, 100 = strongest readable.';
