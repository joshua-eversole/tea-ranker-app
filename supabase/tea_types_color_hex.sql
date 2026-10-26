-- =============================================================================
-- Tea Ranker — tea type chip / tile colors
-- Paste in the Supabase SQL Editor as the project owner.
-- =============================================================================
-- Additive. Does NOT delete tea_types or drink rows.
-- Sets color_hex only when it is currently NULL. Intensity defaults to 100
-- and does not rewrite hues. Reuses the topping mix (hex + 0–100 intensity).
-- RLS stays owner + accepted-friends SELECT. No service_role.
-- Safe after supabase/tea_types.sql.
-- =============================================================================

BEGIN;

ALTER TABLE public.tea_types
  ADD COLUMN IF NOT EXISTS color_hex text;

ALTER TABLE public.tea_types
  ADD COLUMN IF NOT EXISTS color_intensity smallint;

COMMENT ON COLUMN public.tea_types.color_hex IS
  'Tile/chip fill as #RRGGBB. Mixed toward cream by color_intensity.';
COMMENT ON COLUMN public.tea_types.color_intensity IS
  'Fill strength 0–100. 100 is the stored color_hex; lower mixes toward cream.';

-- Named seeds (case-insensitive). Skip if already set.
UPDATE public.tea_types SET color_hex = '#3E2723'
  WHERE lower(btrim(name)) = 'black' AND color_hex IS NULL;
UPDATE public.tea_types SET color_hex = '#43A047'
  WHERE lower(btrim(name)) = 'green' AND color_hex IS NULL;
UPDATE public.tea_types SET color_hex = '#E6B422'
  WHERE lower(btrim(name)) = 'oolong' AND color_hex IS NULL;
UPDATE public.tea_types SET color_hex = '#8BC34A'
  WHERE lower(btrim(name)) = 'matcha' AND color_hex IS NULL;
UPDATE public.tea_types SET color_hex = '#795548'
  WHERE lower(btrim(name)) = 'hojicha' AND color_hex IS NULL;
UPDATE public.tea_types SET color_hex = '#C4A484'
  WHERE lower(btrim(name)) IN ('pu’er', 'pu''er', 'puer') AND color_hex IS NULL;
UPDATE public.tea_types SET color_hex = '#FFF8E1'
  WHERE lower(btrim(name)) = 'white' AND color_hex IS NULL;

-- User extras without a color: seed beige (same historic chip fill).
UPDATE public.tea_types
SET color_hex = '#D4B59E'
WHERE color_hex IS NULL;

ALTER TABLE public.tea_types
  ALTER COLUMN color_hex SET DEFAULT '#D4B59E';

ALTER TABLE public.tea_types
  ALTER COLUMN color_hex SET NOT NULL;

ALTER TABLE public.tea_types
  DROP CONSTRAINT IF EXISTS tea_types_color_hex_chk;

ALTER TABLE public.tea_types
  ADD CONSTRAINT tea_types_color_hex_chk
  CHECK (color_hex ~ '^#[0-9A-Fa-f]{6}$');

UPDATE public.tea_types
SET color_intensity = 100
WHERE color_intensity IS NULL;

ALTER TABLE public.tea_types
  ALTER COLUMN color_intensity SET DEFAULT 100;

ALTER TABLE public.tea_types
  ALTER COLUMN color_intensity SET NOT NULL;

ALTER TABLE public.tea_types
  DROP CONSTRAINT IF EXISTS tea_types_color_intensity_chk;

ALTER TABLE public.tea_types
  ADD CONSTRAINT tea_types_color_intensity_chk
  CHECK (color_intensity BETWEEN 0 AND 100);

COMMIT;
