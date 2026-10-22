-- =============================================================================
-- Tea Ranker — chain logos (additive). Paste in the SQL Editor as project owner.
-- =============================================================================
-- Does NOT drop rows. Does NOT use service_role. Does not wipe Joshua’s log.
--
-- shop_brands: shared name/name_zh keys, logo_path, palette_hex[], selected_hex.
-- profiles.tint_home_with_logos: Home row wash toggle, default false.
-- Storage bucket shop-logos: public read, authenticated insert/update.
-- If the storage.buckets INSERT errors, create a public bucket named
-- shop-logos in the dashboard, then re-run this script for the policies.
-- =============================================================================

BEGIN;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS tint_home_with_logos boolean;

UPDATE public.profiles
SET tint_home_with_logos = false
WHERE tint_home_with_logos IS NULL;

ALTER TABLE public.profiles
  ALTER COLUMN tint_home_with_logos SET DEFAULT false;

ALTER TABLE public.profiles
  ALTER COLUMN tint_home_with_logos SET NOT NULL;

CREATE TABLE IF NOT EXISTS public.shop_brands (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  name_zh text,
  logo_path text,
  palette_hex text[],
  selected_hex text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT shop_brands_name_or_zh_chk
    CHECK (
      (name IS NOT NULL AND length(btrim(name)) > 0)
      OR (name_zh IS NOT NULL AND length(btrim(name_zh)) > 0)
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS shop_brands_name_lower_uidx
  ON public.shop_brands (lower(name))
  WHERE name IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS shop_brands_name_zh_lower_uidx
  ON public.shop_brands (lower(name_zh))
  WHERE name_zh IS NOT NULL;

ALTER TABLE public.shop_brands ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.shop_brands FROM anon, PUBLIC;
GRANT SELECT, INSERT, UPDATE ON TABLE public.shop_brands TO authenticated;

DROP POLICY IF EXISTS shop_brands_select_authenticated ON public.shop_brands;
CREATE POLICY shop_brands_select_authenticated
  ON public.shop_brands
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS shop_brands_insert_authenticated ON public.shop_brands;
CREATE POLICY shop_brands_insert_authenticated
  ON public.shop_brands
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS shop_brands_update_authenticated ON public.shop_brands;
CREATE POLICY shop_brands_update_authenticated
  ON public.shop_brands
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Public bucket + object policies (owner SQL Editor can write storage.*).
INSERT INTO storage.buckets (id, name, public)
VALUES ('shop-logos', 'shop-logos', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

DROP POLICY IF EXISTS shop_logos_public_read ON storage.objects;
CREATE POLICY shop_logos_public_read
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'shop-logos');

DROP POLICY IF EXISTS shop_logos_authenticated_insert ON storage.objects;
CREATE POLICY shop_logos_authenticated_insert
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'shop-logos');

DROP POLICY IF EXISTS shop_logos_authenticated_update ON storage.objects;
CREATE POLICY shop_logos_authenticated_update
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'shop-logos')
  WITH CHECK (bucket_id = 'shop-logos');

COMMIT;
