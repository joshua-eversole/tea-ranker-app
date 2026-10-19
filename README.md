# Tea Ranker

A personal Pokédex for boba and tea. Log each drink (sugar, ice, toppings, letter grade) and see taste insights grouped by shop.

V1 ships as a Flutter **PWA** (web first). Social is a coming-soon tab. The diary is per-user in Supabase.

## Open the live PWA

After GitHub Pages is enabled and the first `Deploy web PWA` workflow on `main` succeeds, the app is at:

**https://joshua-eversole.github.io/tea-ranker-app/**

That URL is the GitHub Pages address for this repo. It is **not** live until the checklist below is done (a 404 means Pages is still off or the workflow has not published yet).

On a phone: open that link in Safari or Chrome, then **Add to Home Screen**. Routes use hash URLs (`/#/login`, `/#/shops/…`) so a static host does not 404 on refresh. The web build sets `--base-href /tea-ranker-app/` to match this project site.

## Enable GitHub Pages (one-time)

Do this on GitHub `joshua-eversole/tea-ranker-app` (not Origin):

1. Merge this hosted-PWA change (and the visual-polish / grade-wash commits) into **`main`**, and make sure GitHub `main` is in sync with Origin `main`.
2. **Settings → Secrets and variables → Actions** — add these two **repository secrets** (publishable/anon only; never `service_role`):

   | Secret name | Value |
   | --- | --- |
   | `SUPABASE_URL` | `https://lqedlqatzlrrmkheoqbr.supabase.co` |
   | `SUPABASE_PUBLISHABLE_KEY` | the project’s **publishable** key (same as local `dart_defines.json`) |

3. **Settings → Pages** — **Source: GitHub Actions** (not “Deploy from a branch”).
4. If GitHub asks to approve the **github-pages** environment, approve it.
5. Push to `main` or run **Actions → Deploy web PWA → Run workflow**. Every later push to `main` republishes.

If the workflow fails with “secret is empty,” the names above are missing or misspelled.

## Run locally

You need the [Flutter SDK](https://docs.flutter.dev/install) with the **web** device enabled.

1. Copy `dart_defines.example.json` to `dart_defines.json` (gitignored).
2. Put the **publishable** (anon) key in `SUPABASE_PUBLISHABLE_KEY`. Never use or commit `service_role`.

```bash
flutter pub get
flutter run -d chrome \
  --dart-define-from-file=dart_defines.json
```

Or pass flags:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://lqedlqatzlrrmkheoqbr.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key \
  --dart-define=APP_URL=https://joshua-eversole.github.io/tea-ranker-app/
```

Web server (uncommon port):

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 43147 \
  --dart-define-from-file=dart_defines.json
```

Release build (same defines the Pages workflow uses):

```bash
flutter build web --release \
  --base-href /tea-ranker-app/ \
  --dart-define=SUPABASE_URL=https://lqedlqatzlrrmkheoqbr.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key \
  --dart-define=APP_URL=https://joshua-eversole.github.io/tea-ranker-app/
```

Missing URL or publishable key shows an in-app setup screen instead of crashing.

## After signup

Email confirmation is **on**. Confirm the inbox link, then sign in. Existing logs stay in your account (Joshua’s 22 drinks are not wiped by this app).

The app passes `emailRedirectTo` from the compile-time **`APP_URL`** dart-define (default `https://joshua-eversole.github.io/tea-ranker-app/`, no hash). That origin works with hash routes (`/#/login`): GoTrue appends `?code=` (PKCE) or `#access_token=` on the Pages path, so a `/#/login` redirect would collide. Do **not** default `APP_URL` or the dashboard Site URL to localhost.

### Supabase Dashboard → Authentication → URL Configuration

Joshua must set these on the live project (`https://lqedlqatzlrrmkheoqbr.supabase.co`). Dashboard only — this app never uses `service_role`.

| Field | Value |
| --- | --- |
| **Site URL** | `https://joshua-eversole.github.io/tea-ranker-app/` |
| **Redirect URLs** | `https://joshua-eversole.github.io/tea-ranker-app/` **and** `https://joshua-eversole.github.io/tea-ranker-app/**` |

Add a localhost redirect only if you are testing confirmation against a local `flutter run`. Leave **Site URL** on the GitHub Pages origin so live signups do not email `localhost` links.

## Layout

Phone-width UI on a cream page. On a real phone / PWA it fills the viewport; on a wide desktop it caps at 480px so it does not become a stretched dashboard. Left **Add drink** slot (idle / pressed / watching) plus evenly spaced Home / Map / Social / Profile pills (Map uses a map icon; Map and Social are “still brewing”). Home greets you by username and lists shops; Taste Profile stats and sugar/ice defaults live on Profile. Shop details have **Visits** and **Notes**. On Visits, the **⋮** menu on each drink **edits** (same logger form) or **deletes** (confirm first). Shop names show on one line as `English / 中文`. New users get bilingual Taiwan chain names; existing shops are never wiped. Chinese-only shop names are valid.

## Shop names + defaults SQL (Supabase)

Paste [`supabase/zh_only_shops_and_profile_defaults.sql`](supabase/zh_only_shops_and_profile_defaults.sql) in the Supabase SQL editor (project owner). It is additive: nullable English `shops.name`, unique `(user_id, name)` and `(user_id, name_zh)` partial indexes, plus `profiles.default_sugar_percent` / `default_ice_percent`. It does not rewrite Joshua’s rows. RLS stays owner-only. Do not use `service_role`.

The earlier [`supabase/shops_name_zh_and_notes.sql`](supabase/shops_name_zh_and_notes.sql) snippet is still safe if you already ran it (`IF NOT EXISTS`).
