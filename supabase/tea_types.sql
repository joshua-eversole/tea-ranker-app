-- Additive: per-user tea type catalog + optional type/note on drinks.
-- Paste as the project owner. Does not rewrite or delete existing drink rows.
-- Seeds are inserted by the app when a user's catalog is empty. No service_role.

CREATE TABLE IF NOT EXISTS public.tea_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id),
  name text NOT NULL,
  is_primary boolean NOT NULL DEFAULT false,
  is_user_added boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS tea_types_user_id_name_key
  ON public.tea_types (user_id, name);

ALTER TABLE public.drink_entries
  ADD COLUMN IF NOT EXISTS tea_type_id uuid REFERENCES public.tea_types (id);

ALTER TABLE public.drink_entries
  ADD COLUMN IF NOT EXISTS tea_type_note text;

ALTER TABLE public.drink_entries
  DROP CONSTRAINT IF EXISTS drink_entries_tea_type_note_chk;

ALTER TABLE public.drink_entries
  ADD CONSTRAINT drink_entries_tea_type_note_chk
  CHECK (tea_type_note IS NULL OR tea_type_id IS NOT NULL);

COMMENT ON TABLE public.tea_types IS
  'Per-user tea types. Seeds: Black/Green/Oolong primary; Matcha/Hojicha/Pu’er/White secondary.';
COMMENT ON COLUMN public.drink_entries.tea_type_id IS
  'Optional tea type. Null when the drink has no type.';
COMMENT ON COLUMN public.drink_entries.tea_type_note IS
  'Optional variety note (Assam, Jasmine). Only when tea_type_id is set.';

ALTER TABLE public.tea_types ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.tea_types FROM anon, PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.tea_types TO authenticated;

DROP POLICY IF EXISTS tea_types_all_own ON public.tea_types;
CREATE POLICY tea_types_all_own
  ON public.tea_types
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS tea_types_select_accepted_friends ON public.tea_types;
CREATE POLICY tea_types_select_accepted_friends
  ON public.tea_types
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.friendships f
      WHERE f.status = 'accepted'
        AND (
          (f.user_id = auth.uid() AND f.friend_id = tea_types.user_id)
          OR (f.friend_id = auth.uid() AND f.user_id = tea_types.user_id)
        )
    )
  );
