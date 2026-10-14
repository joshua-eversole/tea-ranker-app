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
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
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
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Missing URL or publishable key shows an in-app setup screen instead of crashing.

## After signup

Email confirmation is **on**. Confirm the inbox link, then sign in. Existing logs stay in your account (Joshua’s 22 drinks are not wiped by this app).

## Layout

Phone-width UI (max ~430px) on a cream page. Left **Add drink** slot (idle / pressed / watching) plus Home / Social / Profile pills.
