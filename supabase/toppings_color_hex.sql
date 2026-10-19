-- =============================================================================
-- Tea Ranker — unique topping chip colors
-- Paste in the Supabase SQL Editor as the project owner.
-- =============================================================================
-- Additive. Does NOT delete, rename, or rewrite topping rows.
-- Sets color_hex only when it is currently NULL (safe to re-run after a
-- user customizes a chip). Does NOT use service_role. RLS stays owner-only
-- via the existing toppings_all_own policy (user_id = auth.uid()).
-- =============================================================================

BEGIN;

ALTER TABLE public.toppings
  ADD COLUMN IF NOT EXISTS color_hex text;

COMMENT ON COLUMN public.toppings.color_hex IS
  'Chip fill as #RRGGBB. Label text is white when contrast vs #2C1E16 is below 4.5:1.';

-- Joshua’s existing 11 (name match, case-insensitive). Skip if already set.
UPDATE public.toppings SET color_hex = '#E8F5E9'
  WHERE lower(btrim(name)) = 'agar jelly' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#F3E1C6'
  WHERE lower(btrim(name)) = 'almond jelly' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#F0F4C3'
  WHERE lower(btrim(name)) = 'ayou jelly' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#3E2723'
  WHERE lower(btrim(name)) = 'boba' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#A1887F'
  WHERE lower(btrim(name)) = 'coffee' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#C5E1A5'
  WHERE lower(btrim(name)) = 'grape foam' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#FFD54F'
  WHERE lower(btrim(name)) = 'honeycomb coffee mochi' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#E6EE9C'
  WHERE lower(btrim(name)) = 'pear chunks' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#FFF59D'
  WHERE lower(btrim(name)) = 'pineapple chunks' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#1A1A1A'
  WHERE lower(btrim(name)) = 'sesame milk' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#E6C28A'
  WHERE lower(btrim(name)) = 'tea jelly' AND color_hex IS NULL;

-- New-user seed names, if those rows exist for any user.
UPDATE public.toppings SET color_hex = '#FFE082'
  WHERE lower(btrim(name)) = 'pudding' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#1B3D2F'
  WHERE lower(btrim(name)) = 'grass jelly' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#DCEDC8'
  WHERE lower(btrim(name)) = 'aloe' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#E8A598'
  WHERE lower(btrim(name)) = 'red bean' AND color_hex IS NULL;
UPDATE public.toppings SET color_hex = '#FFF3C4'
  WHERE lower(btrim(name)) = 'cheese foam' AND color_hex IS NULL;

-- Any other custom topping: seed beige (same as the historic chip fill).
UPDATE public.toppings
SET color_hex = '#D4B59E'
WHERE color_hex IS NULL;

ALTER TABLE public.toppings
  ALTER COLUMN color_hex SET DEFAULT '#D4B59E';

ALTER TABLE public.toppings
  ALTER COLUMN color_hex SET NOT NULL;

ALTER TABLE public.toppings
  DROP CONSTRAINT IF EXISTS toppings_color_hex_chk;

ALTER TABLE public.toppings
  ADD CONSTRAINT toppings_color_hex_chk
  CHECK (color_hex ~ '^#[0-9A-Fa-f]{6}$');

COMMIT;
