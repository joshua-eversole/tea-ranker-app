import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/tea_repository.dart';
import '../theme/tokens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.repo});

  final TeaRepository repo;

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '—';
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final username = repo.account?.username ?? '—';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Username',
                          style: TextStyle(color: AppColors.chocolate),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Email',
                          style: TextStyle(color: AppColors.chocolate),
                        ),
                        const SizedBox(height: 4),
                        Text(email),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    await repo.signOut();
                    if (context.mounted) context.go('/login');
                  },
                  child: const Text('Sign out'),
                ),
                const Spacer(),
                const Center(
                  child: Text(
                    'Tea Ranker · PWA',
                    style: TextStyle(
                      color: AppColors.chocolate,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
