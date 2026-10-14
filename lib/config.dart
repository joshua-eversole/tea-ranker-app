/// Compile-time keys. Never put `service_role` here.
///
/// ```
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
/// flutter run --dart-define-from-file=.env.json
/// ```
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Public origin for auth emails. Default is the live GitHub Pages PWA.
  /// Override with `--dart-define=APP_URL=...` for a custom host.
  /// Do not default this to localhost — confirmation links would break on the live app.
  static const appUrl = String.fromEnvironment(
    'APP_URL',
    defaultValue: 'https://joshua-eversole.github.io/tea-ranker-app/',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Origin passed as `emailRedirectTo` on sign-up.
  ///
  /// Hash-free: GitHub Pages uses hash routes (`/#/login`), and GoTrue
  /// attaches PKCE `?code=` or implicit `#access_token=`. A hash in the
  /// redirect URL would collide with the token fragment.
  static String get emailRedirectTo => authRedirectOrigin(appUrl);
}

/// Strips a hash, then ensures a trailing slash.
String authRedirectOrigin(String raw) {
  var url = raw.trim();
  if (url.isEmpty) {
    url = 'https://joshua-eversole.github.io/tea-ranker-app/';
  }
  final hash = url.indexOf('#');
  if (hash != -1) {
    url = url.substring(0, hash);
  }
  if (!url.endsWith('/')) {
    url = '$url/';
  }
  return url;
}
