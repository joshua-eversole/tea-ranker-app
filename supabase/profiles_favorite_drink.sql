-- =============================================================================
-- Tea Ranker — Profile favorite drink (additive). Paste in the SQL Editor
-- as project owner.
-- =============================================================================
-- Does NOT drop rows. Does NOT use service_role.
-- Keeps Joshua’s drink_entries / shops / toppings / profile username.
--
-- profiles.favorite_drink: short string each user sets on their own Profile.
-- Not inferred from the log. Empty = NULL.
-- Writes stay own-row (profiles_update_own). Signed-in users (including
-- accepted friends) may SELECT the column via profiles_select_authenticated
-- (same directory SELECT as usernames). Anon still has no table grant.
-- =============================================================================

BEGIN;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS favorite_drink text;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_favorite_drink_len_chk;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_favorite_drink_len_chk
  CHECK (
    favorite_drink IS NULL
    OR (
      char_length(btrim(favorite_drink)) BETWEEN 1 AND 80
    )
  );

COMMENT ON COLUMN public.profiles.favorite_drink IS
  'User-set short favorite drink on Profile. Not inferred. Empty is NULL. Friends SELECT; only the owner writes.';

-- Own-write stays. Recreate so this paste is enough if older policies drifted.
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Friends (and the username directory) SELECT favorite_drink with username.
-- Same signed-in SELECT as supabase/friendships_status_and_rls.sql.
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
DROP POLICY IF EXISTS profiles_select_authenticated ON public.profiles;
CREATE POLICY profiles_select_authenticated
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

COMMIT;
