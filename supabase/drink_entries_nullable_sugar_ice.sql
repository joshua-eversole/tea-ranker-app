-- Additive: Fixed sugar / ice (unassigned) on drink_entries.
-- Paste as the project owner. Does not rewrite or delete existing rows.
-- Existing 10/30/50 (and other) values stay. No service_role.

ALTER TABLE public.drink_entries
  ALTER COLUMN sugar_level DROP NOT NULL;

ALTER TABLE public.drink_entries
  ALTER COLUMN ice_level DROP NOT NULL;

ALTER TABLE public.drink_entries
  DROP CONSTRAINT IF EXISTS drink_entries_sugar_level_chk;

ALTER TABLE public.drink_entries
  ADD CONSTRAINT drink_entries_sugar_level_chk
  CHECK (
    sugar_level IS NULL
    OR (sugar_level BETWEEN 0 AND 100 AND sugar_level % 10 = 0)
  );

ALTER TABLE public.drink_entries
  DROP CONSTRAINT IF EXISTS drink_entries_ice_level_chk;

ALTER TABLE public.drink_entries
  ADD CONSTRAINT drink_entries_ice_level_chk
  CHECK (
    ice_level IS NULL
    OR (ice_level BETWEEN 0 AND 100 AND ice_level % 10 = 0)
  );

COMMENT ON COLUMN public.drink_entries.sugar_level IS
  '0–100 in steps of 10. NULL = Fixed / unassigned (shop specials).';
COMMENT ON COLUMN public.drink_entries.ice_level IS
  '0–100 in steps of 10. NULL = Fixed / unassigned (shop specials).';
