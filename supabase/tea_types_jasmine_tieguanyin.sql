-- =============================================================================
-- Tea Ranker — Jasmine + Tieguanyin seeds, pastel Black/Green/Oolong
-- Paste in the Supabase SQL Editor as the project owner.
-- =============================================================================
-- Additive. Does NOT delete tea_types, extras, or drink rows.
-- Inserts Jasmine / Tieguanyin for users who already have a catalog and
-- lack those names. Empty catalogs are seeded by the app (all nine).
-- Softens Black / Green / Oolong intensity to the grade-wash pastel (16)
-- only when still at the old default 100. Does not rewrite custom hex.
-- Safe after supabase/tea_types.sql and supabase/tea_types_color_hex.sql.
-- No service_role.
-- =============================================================================

BEGIN;

ALTER TABLE public.tea_types
  ADD COLUMN IF NOT EXISTS color_hex text;

ALTER TABLE public.tea_types
  ADD COLUMN IF NOT EXISTS color_intensity smallint;

-- Row 1: keep hue, fade toward cream like Home grade wash / topping mix.
UPDATE public.tea_types
SET color_intensity = 16
WHERE lower(btrim(name)) IN ('black', 'green', 'oolong')
  AND (color_intensity IS NULL OR color_intensity = 100);

-- Jasmine (pale floral yellow-green) for existing catalogs.
INSERT INTO public.tea_types (
  user_id, name, is_primary, is_user_added, color_hex, color_intensity
)
SELECT DISTINCT t.user_id, 'Jasmine', false, false, '#E4EEC0', 100
FROM public.tea_types t
WHERE NOT EXISTS (
  SELECT 1
  FROM public.tea_types x
  WHERE x.user_id = t.user_id
    AND lower(btrim(x.name)) = 'jasmine'
);

-- Tieguanyin (soft olive / iron-goddess) for existing catalogs.
INSERT INTO public.tea_types (
  user_id, name, is_primary, is_user_added, color_hex, color_intensity
)
SELECT DISTINCT t.user_id, 'Tieguanyin', false, false, '#A8B57A', 100
FROM public.tea_types t
WHERE NOT EXISTS (
  SELECT 1
  FROM public.tea_types x
  WHERE x.user_id = t.user_id
    AND lower(btrim(x.name)) = 'tieguanyin'
);

COMMIT;
