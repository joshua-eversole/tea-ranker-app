import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/config.dart';

void main() {
  test('default APP_URL is the live GitHub Pages origin, not localhost', () {
    expect(AppConfig.appUrl, 'https://joshua-eversole.github.io/tea-ranker-app/');
    expect(AppConfig.emailRedirectTo, isNot(contains('localhost')));
    expect(AppConfig.emailRedirectTo, isNot(contains('127.0.0.1')));
    expect(AppConfig.emailRedirectTo, 'https://joshua-eversole.github.io/tea-ranker-app/');
  });

  test('authRedirectOrigin strips hash routes and adds a trailing slash', () {
    expect(
      authRedirectOrigin('https://joshua-eversole.github.io/tea-ranker-app'),
      'https://joshua-eversole.github.io/tea-ranker-app/',
    );
    expect(
      authRedirectOrigin(
        'https://joshua-eversole.github.io/tea-ranker-app/#/login',
      ),
      'https://joshua-eversole.github.io/tea-ranker-app/',
    );
    expect(authRedirectOrigin(''), 'https://joshua-eversole.github.io/tea-ranker-app/');
  });
}
