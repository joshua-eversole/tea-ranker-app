-- =============================================================================
-- Tea Ranker — Chinese-only shops + personal sugar/ice defaults
-- Paste in the Supabase SQL Editor as the project owner.
-- =============================================================================
-- Additive. Does NOT delete or rewrite existing shops, drinks, toppings, or
-- the live profile username. Does NOT use service_role. RLS stays owner-only.
--
-- Safe to run after supabase/shops_name_zh_and_notes.sql (IF NOT EXISTS).
-- Existing English `name` values stay as they are. New ZH-only shops store
-- NULL English instead of a dummy name.
-- =============================================================================

BEGIN;

ALTER TABLE public.shops
  ADD COLUMN IF NOT EXISTS name_zh text;

ALTER TABLE public.shops
  ADD COLUMN IF NOT EXISTS notes text;

ALTER TABLE public.shops
  ALTER COLUMN name DROP NOT NULL;

ALTER TABLE public.shops
  DROP CONSTRAINT IF EXISTS shops_name_or_zh_chk;

ALTER TABLE public.shops
  ADD CONSTRAINT shops_name_or_zh_chk
  CHECK (
    (name IS NOT NULL AND length(btrim(name)) > 0)
    OR (name_zh IS NOT NULL AND length(btrim(name_zh)) > 0)
  );

DROP INDEX IF EXISTS shops_user_id_name_key;

CREATE UNIQUE INDEX IF NOT EXISTS shops_user_id_name_key
  ON public.shops (user_id, name)
  WHERE name IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS shops_user_id_name_zh_key
  ON public.shops (user_id, name_zh)
  WHERE name_zh IS NOT NULL;

COMMENT ON COLUMN public.shops.name IS
  'English name. Nullable when the shop is Chinese-only.';
COMMENT ON COLUMN public.shops.name_zh IS
  'Chinese name. Nullable when the shop is English-only. At least one of name / name_zh is required.';

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS default_sugar_percent smallint NOT NULL DEFAULT 50;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS default_ice_percent smallint NOT NULL DEFAULT 50;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_default_sugar_percent_chk;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_default_sugar_percent_chk
  CHECK (
    default_sugar_percent BETWEEN 0 AND 100
    AND default_sugar_percent % 10 = 0
  );

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_default_ice_percent_chk;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_default_ice_percent_chk
  CHECK (
    default_ice_percent BETWEEN 0 AND 100
    AND default_ice_percent % 10 = 0
  );

COMMENT ON COLUMN public.profiles.default_sugar_percent IS
  'Logger sugar slider default, 0–100 in 10% steps.';
COMMENT ON COLUMN public.profiles.default_ice_percent IS
  'Logger ice slider default, 0–100 in 10% steps.';

COMMIT;
