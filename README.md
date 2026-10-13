# Tea Ranker

A personal Pokédex for boba and tea. Log each drink (sugar, ice, toppings, letter grade) and see taste insights grouped by shop.

V1 ships as a Flutter **PWA** (web first). Social is a coming-soon tab. The diary is per-user in Supabase.

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

Missing URL or publishable key shows an in-app setup screen instead of crashing.

## After signup

Email confirmation is **on**. Confirm the inbox link, then sign in. Existing logs stay in your account (Joshua’s 22 drinks are not wiped by this app).

## Layout

Phone-width UI (max ~430px) on a cream page (`#FAF3E0`). Nunito Regular / SemiBold / ExtraBold (grades). Left **Add drink** slot (idle / pressed / watching, 64px with ~12px overhang) plus Home / Social / Profile pills. Prices display as `NT$ 65`.
