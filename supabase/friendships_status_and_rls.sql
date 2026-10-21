-- =============================================================================
-- Tea Ranker — Social slice (additive). Paste in the SQL Editor as project owner.
-- =============================================================================
-- Does NOT drop rows. Does NOT use service_role.
-- Keeps Joshua’s drink_entries / shops / toppings. drink_companions stays unused.
--
-- friendships: requester = user_id, target = friend_id, status pending|accepted|declined.
-- Search: signed-in users can SELECT other profiles (id + username via RLS; client
-- selects those columns only — email stays on auth.users).
-- Friends (accepted) can SELECT the other person’s drink_entries / shops /
-- toppings / drink_toppings. Anon still has no table grants. Not a public diary.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. friendships.status + guards
-- -----------------------------------------------------------------------------
ALTER TABLE public.friendships
  ADD COLUMN IF NOT EXISTS status text;

-- Existing edges (if any) were implicit friends before this slice.
UPDATE public.friendships
SET status = 'accepted'
WHERE status IS NULL;

ALTER TABLE public.friendships
  ALTER COLUMN status SET DEFAULT 'pending';

ALTER TABLE public.friendships
  ALTER COLUMN status SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'friendships_status_chk'
  ) THEN
    ALTER TABLE public.friendships
      ADD CONSTRAINT friendships_status_chk
      CHECK (status IN ('pending', 'accepted', 'declined'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'friendships_not_self_chk'
  ) THEN
    ALTER TABLE public.friendships
      ADD CONSTRAINT friendships_not_self_chk
      CHECK (user_id <> friend_id);
  END IF;
END $$;

-- One active directed request/friendship. Declined rows are kept but hidden in UI
-- and do not block a later request.
CREATE UNIQUE INDEX IF NOT EXISTS friendships_directed_active_uidx
  ON public.friendships (user_id, friend_id)
  WHERE status IN ('pending', 'accepted');

-- One active edge per pair (A→B and B→A cannot both be pending/accepted).
CREATE UNIQUE INDEX IF NOT EXISTS friendships_pair_active_uidx
  ON public.friendships (LEAST(user_id, friend_id), GREATEST(user_id, friend_id))
  WHERE status IN ('pending', 'accepted');

CREATE OR REPLACE FUNCTION public.friendships_immutable_endpoints()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.user_id IS DISTINCT FROM OLD.user_id
     OR NEW.friend_id IS DISTINCT FROM OLD.friend_id THEN
    RAISE EXCEPTION 'friendship user_id and friend_id cannot change';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS friendships_immutable_endpoints_trg ON public.friendships;
CREATE TRIGGER friendships_immutable_endpoints_trg
  BEFORE UPDATE ON public.friendships
  FOR EACH ROW
  EXECUTE PROCEDURE public.friendships_immutable_endpoints();

-- -----------------------------------------------------------------------------
-- 2. Replace friendships write policies (target accepts/declines)
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS friendships_insert_as_self ON public.friendships;
DROP POLICY IF EXISTS friendships_update_as_self ON public.friendships;
DROP POLICY IF EXISTS friendships_delete_as_self ON public.friendships;
DROP POLICY IF EXISTS friendships_update_target ON public.friendships;
DROP POLICY IF EXISTS friendships_update_resend ON public.friendships;
DROP POLICY IF EXISTS friendships_delete_pending_own ON public.friendships;

-- Insert: only as requester, never self, always pending.
CREATE POLICY friendships_insert_as_self
  ON public.friendships
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND friend_id <> auth.uid()
    AND status = 'pending'
  );

-- Target of a pending request may accept or decline.
CREATE POLICY friendships_update_target
  ON public.friendships
  FOR UPDATE
  TO authenticated
  USING (friend_id = auth.uid() AND status = 'pending')
  WITH CHECK (friend_id = auth.uid() AND status IN ('accepted', 'declined'));

-- Requester may turn a declined row back into pending (re-request) if a
-- composite primary key blocks a second insert.
CREATE POLICY friendships_update_resend
  ON public.friendships
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid() AND status = 'declined')
  WITH CHECK (user_id = auth.uid() AND status = 'pending');

-- Requester may cancel a still-pending request (not used in v1 UI).
CREATE POLICY friendships_delete_pending_own
  ON public.friendships
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid() AND status = 'pending');

-- -----------------------------------------------------------------------------
-- 3. Directory search: authenticated SELECT of profiles (usernames)
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
DROP POLICY IF EXISTS profiles_select_authenticated ON public.profiles;

CREATE POLICY profiles_select_authenticated
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- -----------------------------------------------------------------------------
-- 4. Accepted friends: limited diary read (not the world, not hangouts)
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS drink_entries_select_accepted_friends ON public.drink_entries;
CREATE POLICY drink_entries_select_accepted_friends
  ON public.drink_entries
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.friendships f
      WHERE f.status = 'accepted'
        AND (
          (f.user_id = auth.uid() AND f.friend_id = drink_entries.user_id)
          OR (f.friend_id = auth.uid() AND f.user_id = drink_entries.user_id)
        )
    )
  );

DROP POLICY IF EXISTS shops_select_accepted_friends ON public.shops;
CREATE POLICY shops_select_accepted_friends
  ON public.shops
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.friendships f
      WHERE f.status = 'accepted'
        AND (
          (f.user_id = auth.uid() AND f.friend_id = shops.user_id)
          OR (f.friend_id = auth.uid() AND f.user_id = shops.user_id)
        )
    )
  );

DROP POLICY IF EXISTS toppings_select_accepted_friends ON public.toppings;
CREATE POLICY toppings_select_accepted_friends
  ON public.toppings
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.friendships f
      WHERE f.status = 'accepted'
        AND (
          (f.user_id = auth.uid() AND f.friend_id = toppings.user_id)
          OR (f.friend_id = auth.uid() AND f.user_id = toppings.user_id)
        )
    )
  );

DROP POLICY IF EXISTS drink_toppings_select_accepted_friends ON public.drink_toppings;
CREATE POLICY drink_toppings_select_accepted_friends
  ON public.drink_toppings
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.drink_entries e
      JOIN public.friendships f ON f.status = 'accepted'
        AND (
          (f.user_id = auth.uid() AND f.friend_id = e.user_id)
          OR (f.friend_id = auth.uid() AND f.user_id = e.user_id)
        )
      WHERE e.id = drink_toppings.drink_id
    )
  );

COMMIT;
