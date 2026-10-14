-- =============================================================================
-- Tea Ranker — bilingual shop names + shop-level notes
-- Paste in the Supabase SQL Editor as the project owner.
-- =============================================================================
-- Additive only. Does NOT delete or rewrite existing shops, drinks, or toppings.
-- Does NOT use service_role. RLS stays owner-only; new columns inherit the
-- existing shops policies (authenticated, user_id = auth.uid()).
--
-- After this runs, new-user seed can store English in `name` and Chinese in
-- `name_zh`. Shop details Notes tab writes `shops.notes` (not drink notes).
-- =============================================================================

BEGIN;

ALTER TABLE public.shops
  ADD COLUMN IF NOT EXISTS name_zh text;

ALTER TABLE public.shops
  ADD COLUMN IF NOT EXISTS notes text;

COMMENT ON COLUMN public.shops.name IS
  'Primary display name (English).';
COMMENT ON COLUMN public.shops.name_zh IS
  'Optional Chinese name. Existing rows stay NULL until the owner edits them.';
COMMENT ON COLUMN public.shops.notes IS
  'Shop-level notes (not drink_entries.notes).';

COMMIT;
