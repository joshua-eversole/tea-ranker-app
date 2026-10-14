import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../data/tea_repository.dart';
import '../theme/tokens.dart';
import '../widgets/grade_circle.dart';
import '../widgets/grade_wash_surface.dart';
import '../widgets/shop_name_text.dart';
import '../widgets/tea_skeleton.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.repo});

  final TeaRepository repo;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (repo.loading && repo.profile == null) {
          return const HomeLoadSkeleton();
        }
        if (repo.loadError != null) {
          return HomeLoadError(onRetry: repo.refresh);
        }
        final data = repo.profile;
        if (data == null || data.entries.isEmpty) {
          return const _HomeEmpty();
        }
        return _HomeLoaded(data: data);
      },
    );
  }
}

class _HomeEmpty extends StatelessWidget {
  const _HomeEmpty();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Taste Profile', style: Theme.of(context).textTheme.titleLarge),
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
  const HomeLoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Couldn’t load your log.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
  const HomeLoadSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: TeaSkeleton(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Taste Profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TeaBone(height: 48, width: 72),
                    TeaBone(height: 48, width: 72),
                    TeaBone(height: 48, circle: true),
                  ],
                ),
              ),
            ),
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
  const _HomeLoaded({required this.data});
  final TasteProfile data;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('Taste Profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
            color: AppSurfaces.cardTint,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Wrap(
                alignment: WrapAlignment.spaceAround,
                runSpacing: 12,
                spacing: 12,
                children: [
                  _Stat(
                    label: 'Avg sugar',
                    value: '${data.averageSugarPercent ?? '—'}%',
                  ),
                  _Stat(
                    label: 'Favorite base',
                    value: data.favoriteBase ?? '—',
                  ),
                  _Stat(
                    label: 'Highest shop',
                    value: data.highestRatedShop?.shop.name ?? '—',
                    trailing: GradeOrDash(
                      band: data.highestRatedShop?.band,
                      size: AppLayout.historyGradeSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Shops', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in data.shopFeed) ...[
            _ShopCard(item: item),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.trailing});
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.chocolate, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ?trailing,
          if (trailing == null)
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.item});
  final ShopFeedItem item;

  @override
  Widget build(BuildContext context) {
    return GradeWashSurface(
      mark: item.band?.label,
      onTap: () => context.push('/shops/${item.shop.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            GradeOrDash(band: item.band, size: AppLayout.historyGradeSize),
          ],
        ),
      ),
    );
  }
}
