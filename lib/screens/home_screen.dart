import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../data/shop_brands.dart';
import '../data/tea_repository.dart';
import '../theme/tokens.dart';
import '../widgets/grade_circle.dart';
import '../widgets/grade_wash_surface.dart';
import '../widgets/shop_logo_circle.dart';
import '../widgets/shop_name_text.dart';
import '../widgets/tea_skeleton.dart';

/// Shown with skeleton shop cards until the first successful Home fetch.
const kHomeLoadingCopy = 'Loading your log…';

enum HomePhase { loading, error, empty, ready }

/// Empty copy only after a successful fetch with zero drinks.
HomePhase homePhase({
  required bool loading,
  required Object? loadError,
  required bool hasProfile,
  required bool hasDrinks,
}) {
  if (loadError != null) return HomePhase.error;
  if (!hasProfile || (loading && !hasDrinks)) {
    return HomePhase.loading;
  }
  if (!hasDrinks) return HomePhase.empty;
  return HomePhase.ready;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.repo});

  final TeaRepository repo;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final username = repo.account?.username.trim();
        final hello = (username == null || username.isEmpty)
            ? 'Welcome back'
            : 'Welcome back, $username';
        final data = repo.profile;
        final phase = homePhase(
          loading: repo.loading,
          loadError: repo.loadError,
          hasProfile: data != null,
          hasDrinks: data != null && data.entries.isNotEmpty,
        );
        switch (phase) {
          case HomePhase.loading:
            return HomeLoadSkeleton(
              welcome: hello,
              loadingCopy: kHomeLoadingCopy,
            );
          case HomePhase.error:
            return HomeLoadError(onRetry: repo.refresh);
          case HomePhase.empty:
            return _HomeEmpty(welcome: hello);
          case HomePhase.ready:
            return _HomeLoaded(welcome: hello, data: data!, repo: repo);
        }
      },
    );
  }
}

class _HomeEmpty extends StatelessWidget {
  const _HomeEmpty({required this.welcome});
  final String welcome;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(welcome, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            const Center(
              child: Text(
                'No drinks yet.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.boba,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: () => context.push('/log'),
                child: const Text('Log your first drink'),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class HomeLoadError extends StatelessWidget {
  const HomeLoadError({
    super.key,
    required this.onRetry,
    this.message = 'Couldn’t load your log.',
  });
  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeLoadSkeleton extends StatelessWidget {
  const HomeLoadSkeleton({
    super.key,
    this.welcome = 'Welcome back',
    this.loadingCopy,
  });
  final String welcome;
  final String? loadingCopy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: TeaSkeleton(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(welcome, style: Theme.of(context).textTheme.titleLarge),
            if (loadingCopy != null) ...[
              const SizedBox(height: 12),
              Text(
                loadingCopy!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.chocolate,
                ),
              ),
            ],
            const SizedBox(height: 20),
            const TeaBone(height: 20, width: 80),
            const SizedBox(height: 12),
            const _ShopBone(),
            const SizedBox(height: 12),
            const _ShopBone(),
            const SizedBox(height: 12),
            const _ShopBone(),
          ],
        ),
      ),
    );
  }
}

class _ShopBone extends StatelessWidget {
  const _ShopBone();

  @override
  Widget build(BuildContext context) {
    return const GradeWashSurface(
      mark: null,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TeaBone(height: 16, width: 140),
                  SizedBox(height: 10),
                  TeaBone(height: 12, width: 72),
                ],
              ),
            ),
            TeaBone(height: AppLayout.historyGradeSize, circle: true),
          ],
        ),
      ),
    );
  }
}

class _HomeLoaded extends StatelessWidget {
  const _HomeLoaded({
    required this.welcome,
    required this.data,
    required this.repo,
  });
  final String welcome;
  final TasteProfile data;
  final TeaRepository repo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(welcome, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Text('Shops', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in data.shopFeed) ...[
            _ShopCard(item: item, repo: repo),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.item, required this.repo});
  final ShopFeedItem item;
  final TeaRepository repo;

  @override
  Widget build(BuildContext context) {
    final brand = repo.brandFor(item.shop);
    final wash = homeRowWash(brand: brand, gradeMark: item.band?.label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          GradeWashSurface(
            mark: item.band?.label,
            wash: wash,
            onTap: () => context.push('/shops/${item.shop.id}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                kHomeLogoTextInset,
                14,
                16,
                14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShopNameText(shop: item.shop),
                        const SizedBox(height: 4),
                        Text(
                          '${item.visitCount} ${item.visitCount == 1 ? 'visit' : 'visits'}',
                          style: const TextStyle(color: AppColors.chocolate),
                        ),
                      ],
                    ),
                  ),
                  GradeOrDash(
                    band: item.band,
                    size: AppLayout.historyGradeSize,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: IgnorePointer(
                child: ShopLogoCircle(
                  size: kHomeLogoCircleSize,
                  band: item.band,
                  brand: brand,
                  logoUrl: repo.publicLogoUrl(brand),
                  showBobaIcon: true,
                  fill: homeLogoCircleFill(item.band?.label),
                  iconColor: wash,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
