-- =============================================================================
-- Tea Ranker — Hangouts (additive). Paste in the SQL Editor as project owner.
-- =============================================================================
-- Does NOT drop rows. Does NOT use service_role.
-- Keeps Joshua’s drink_entries / shops / toppings. No trip table.
--
-- drink_entries.hangout_id: shared uuid across linked drinks (nullable).
-- drink_companions: requester tags accepted friends on THEIR drink immediately.
--   peer_drink_id = the other person’s drink when known.
--   invite_status = pending | accepted | declined | linked
-- Decline hides the invite for the tagged friend; the sender’s row stays.
-- Tagged friend may SELECT those rows and UPDATE invite_status / peer_drink_id.
-- Owner CRUD on own drinks stays. pending_label unused in UI.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. Columns
-- -----------------------------------------------------------------------------
ALTER TABLE public.drink_entries
  ADD COLUMN IF NOT EXISTS hangout_id uuid;

ALTER TABLE public.drink_companions
  ADD COLUMN IF NOT EXISTS peer_drink_id uuid;

ALTER TABLE public.drink_companions
  ADD COLUMN IF NOT EXISTS invite_status text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'drink_companions_peer_drink_fkey'
  ) THEN
    ALTER TABLE public.drink_companions
      ADD CONSTRAINT drink_companions_peer_drink_fkey
      FOREIGN KEY (peer_drink_id) REFERENCES public.drink_entries (id)
      ON DELETE SET NULL;
  END IF;
END $$;

UPDATE public.drink_companions
SET invite_status = 'pending'
WHERE invite_status IS NULL AND peer_drink_id IS NULL;

UPDATE public.drink_companions
SET invite_status = 'linked'
WHERE invite_status IS NULL AND peer_drink_id IS NOT NULL;

ALTER TABLE public.drink_companions
  ALTER COLUMN invite_status SET DEFAULT 'pending';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'drink_companions_invite_status_chk'
  ) THEN
    ALTER TABLE public.drink_companions
      ADD CONSTRAINT drink_companions_invite_status_chk
      CHECK (
        invite_status IS NULL
        OR invite_status IN ('pending', 'accepted', 'declined', 'linked')
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS drink_entries_hangout_id_idx
  ON public.drink_entries (hangout_id)
  WHERE hangout_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- 2. Tagged friend SELECT + limited UPDATE; reverse-row INSERT for link/accept
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS drink_companions_select_tagged ON public.drink_companions;
CREATE POLICY drink_companions_select_tagged
  ON public.drink_companions
  FOR SELECT
  TO authenticated
  USING (friend_user_id = auth.uid());

-- Companions on an accepted friend’s drinks (With line on last 3 / hangout drink).
DROP POLICY IF EXISTS drink_companions_select_friend_entry ON public.drink_companions;
CREATE POLICY drink_companions_select_friend_entry
  ON public.drink_companions
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
      WHERE e.id = drink_companions.drink_entry_id
    )
  );

DROP POLICY IF EXISTS drink_companions_update_tagged ON public.drink_companions;
CREATE POLICY drink_companions_update_tagged
  ON public.drink_companions
  FOR UPDATE
  TO authenticated
  USING (friend_user_id = auth.uid())
  WITH CHECK (friend_user_id = auth.uid());

-- Reverse companion on the friend’s drink (peer_drink_id both ways).
DROP POLICY IF EXISTS drink_companions_insert_reverse ON public.drink_companions;
CREATE POLICY drink_companions_insert_reverse
  ON public.drink_companions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    friend_user_id = auth.uid()
    AND invite_status IN ('accepted', 'linked')
    AND EXISTS (
      SELECT 1
      FROM public.drink_entries e
      JOIN public.friendships f ON f.status = 'accepted'
        AND (
          (f.user_id = auth.uid() AND f.friend_id = e.user_id)
          OR (f.friend_id = auth.uid() AND f.user_id = e.user_id)
        )
      WHERE e.id = drink_companions.drink_entry_id
    )
  );

CREATE OR REPLACE FUNCTION public.drink_companions_tagged_update_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  owner_id uuid;
BEGIN
  SELECT e.user_id INTO owner_id
  FROM public.drink_entries e
  WHERE e.id = OLD.drink_entry_id;

  IF owner_id = auth.uid() THEN
    RETURN NEW;
  END IF;

  IF NEW.friend_user_id IS DISTINCT FROM OLD.friend_user_id
     OR NEW.drink_entry_id IS DISTINCT FROM OLD.drink_entry_id
     OR NEW.pending_label IS DISTINCT FROM OLD.pending_label THEN
    RAISE EXCEPTION 'tagged friend may only update invite_status and peer_drink_id';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS drink_companions_tagged_update_guard_trg ON public.drink_companions;
CREATE TRIGGER drink_companions_tagged_update_guard_trg
  BEFORE UPDATE ON public.drink_companions
  FOR EACH ROW
  EXECUTE PROCEDURE public.drink_companions_tagged_update_guard();

-- Accepted friend may copy hangout_id onto the peer drink (linked attach).
DROP POLICY IF EXISTS drink_entries_update_hangout_by_friend ON public.drink_entries;
CREATE POLICY drink_entries_update_hangout_by_friend
  ON public.drink_entries
  FOR UPDATE
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
  )
  WITH CHECK (
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

CREATE OR REPLACE FUNCTION public.drink_entries_friend_hangout_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.user_id = auth.uid() THEN
    RETURN NEW;
  END IF;

  IF NEW.user_id IS DISTINCT FROM OLD.user_id
     OR NEW.shop_id IS DISTINCT FROM OLD.shop_id
     OR NEW.tea_name IS DISTINCT FROM OLD.tea_name
     OR NEW.drink_type IS DISTINCT FROM OLD.drink_type
     OR NEW.sugar_level IS DISTINCT FROM OLD.sugar_level
     OR NEW.ice_level IS DISTINCT FROM OLD.ice_level
     OR NEW.price IS DISTINCT FROM OLD.price
     OR NEW.grade IS DISTINCT FROM OLD.grade
     OR NEW.overall_grade IS DISTINCT FROM OLD.overall_grade
     OR NEW.notes IS DISTINCT FROM OLD.notes
     OR NEW.logged_at IS DISTINCT FROM OLD.logged_at
     OR NEW.photo_url IS DISTINCT FROM OLD.photo_url THEN
    RAISE EXCEPTION 'friends may only set hangout_id on a peer drink';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS drink_entries_friend_hangout_guard_trg ON public.drink_entries;
CREATE TRIGGER drink_entries_friend_hangout_guard_trg
  BEFORE UPDATE ON public.drink_entries
  FOR EACH ROW
  EXECUTE PROCEDURE public.drink_entries_friend_hangout_guard();

COMMIT;
