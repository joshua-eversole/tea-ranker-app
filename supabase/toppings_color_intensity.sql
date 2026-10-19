-- =============================================================================
-- Tea Ranker — topping chip intensity
-- Paste in the Supabase SQL Editor as the project owner.
-- =============================================================================
-- Additive. Does NOT delete topping rows or rewrite color_hex.
-- color_intensity is 0–100 (100 = full hue). Lower values mix the hue toward
-- cream in the app. RLS stays owner-only (toppings_all_own). No service_role.
-- Safe after supabase/toppings_color_hex.sql.
-- =============================================================================

BEGIN;

ALTER TABLE public.toppings
  ADD COLUMN IF NOT EXISTS color_intensity smallint;

UPDATE public.toppings
SET color_intensity = 100
WHERE color_intensity IS NULL;

ALTER TABLE public.toppings
  ALTER COLUMN color_intensity SET DEFAULT 100;

ALTER TABLE public.toppings
  ALTER COLUMN color_intensity SET NOT NULL;

ALTER TABLE public.toppings
  DROP CONSTRAINT IF EXISTS toppings_color_intensity_chk;

ALTER TABLE public.toppings
  ADD CONSTRAINT toppings_color_intensity_chk
  CHECK (color_intensity BETWEEN 0 AND 100);

COMMENT ON COLUMN public.toppings.color_intensity IS
  'Chip fill strength 0–100. 100 is the stored color_hex; lower mixes toward cream.';

COMMIT;
