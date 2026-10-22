-- =============================================================================
-- Tea Ranker — per-brand Home tint (additive). Paste as project owner.
-- =============================================================================
-- Does NOT drop rows. Does NOT use service_role. Does not wipe Joshua’s log.
-- Requires shop_brands from supabase/shop_brands_and_logos.sql.
--
-- profiles.tint_home_with_logos: default ON (true). Existing null/false → true.
-- shop_brands.tint_home: this shop’s Home card wash, default true.
-- Off = this brand’s Home row stays grade wash even though tint defaults on.
-- =============================================================================

BEGIN;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS tint_home_with_logos boolean;

UPDATE public.profiles
SET tint_home_with_logos = true
WHERE tint_home_with_logos IS NULL
   OR tint_home_with_logos = false;

ALTER TABLE public.profiles
  ALTER COLUMN tint_home_with_logos SET DEFAULT true;

ALTER TABLE public.profiles
  ALTER COLUMN tint_home_with_logos SET NOT NULL;

ALTER TABLE public.shop_brands
  ADD COLUMN IF NOT EXISTS tint_home boolean;

UPDATE public.shop_brands
SET tint_home = true
WHERE tint_home IS NULL;

ALTER TABLE public.shop_brands
  ALTER COLUMN tint_home SET DEFAULT true;

ALTER TABLE public.shop_brands
  ALTER COLUMN tint_home SET NOT NULL;

COMMIT;
