import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'data/tea_repository.dart';
import 'screens/drink_logger_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/shop_detail_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/social_screen.dart';
import 'theme/tokens.dart';
import 'widgets/app_shell.dart';

class AuthRefresh extends ChangeNotifier {
  AuthRefresh() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class TeaRankerApp extends StatefulWidget {
  const TeaRankerApp({super.key});

  @override
  State<TeaRankerApp> createState() => _TeaRankerAppState();
}

class _TeaRankerAppState extends State<TeaRankerApp> {
  TeaRepository? _repo;
  AuthRefresh? _auth;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    if (!AppConfig.isConfigured) return;
    _repo = TeaRepository(Supabase.instance.client);
    _auth = AuthRefresh();
    _router = _buildRouter(_repo!, _auth!);
    if (Supabase.instance.client.auth.currentSession != null) {
      _repo!.onSignedIn();
    }
    _auth!.addListener(() {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _repo!.onSignedIn();
      }
    });
  }

  @override
  void dispose() {
    _auth?.dispose();
    _repo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return MaterialApp(
        title: 'Tea Ranker',
        theme: buildTeaTheme(),
        home: const SetupScreen(),
      );
    }
    return MaterialApp.router(
      title: 'Tea Ranker',
      theme: buildTeaTheme(),
      routerConfig: _router!,
    );
  }
}

GoRouter _buildRouter(TeaRepository repo, AuthRefresh auth) {
  // Default hash URLs (`/#/login`) on web — required for GitHub Pages
  // (static hosting, no SPA rewrite). Do not call usePathUrlStrategy().
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      final loc = state.matchedLocation;
      final authing = loc == '/login' || loc == '/signup';
      if (!loggedIn && !authing) return '/login';
      if (loggedIn && authing) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: HomeScreen(repo: repo),
            ),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MapScreen(),
            ),
          ),
          GoRoute(
            path: '/social',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SocialScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: ProfileScreen(repo: repo),
            ),
          ),
          GoRoute(
            path: '/log',
            builder: (_, _) => DrinkLoggerScreen(repo: repo),
          ),
          GoRoute(
            path: '/shops/:id',
            builder: (_, state) => ShopDetailScreen(
              repo: repo,
              shopId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
}
