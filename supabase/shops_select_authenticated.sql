-- =============================================================================
-- Tea Ranker — logger can see shop names created by other users
-- Paste in the Supabase SQL Editor as the project owner.
-- =============================================================================
-- Additive. Does NOT delete or rewrite drink_entries, shops, toppings, or
-- profiles. Does NOT use service_role.
--
-- Writes on shops stay owner-only (insert/update/delete still require
-- user_id = auth.uid()). Signed-in users may SELECT other users’ shop rows
-- so the logger can attach to an existing name instead of inserting a
-- duplicate that hits UNIQUE shops.name (leftover global catalog) and/or
-- UNIQUE (user_id, name) / (user_id, name_zh). Anon still has no table grant.
-- Does not add a second uniqueness rule and does not drop existing indexes.
-- =============================================================================

BEGIN;

DROP POLICY IF EXISTS shops_select_authenticated ON public.shops;
CREATE POLICY shops_select_authenticated
  ON public.shops
  FOR SELECT
  TO authenticated
  USING (true);

COMMIT;
