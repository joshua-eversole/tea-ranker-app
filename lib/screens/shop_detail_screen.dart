import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/tea_repository.dart';
import '../theme/tokens.dart';
import '../widgets/grade_circle.dart';
import 'home_screen.dart';

enum ShopDetailPhase { loading, error, empty, ready }

/// Pop Home only after a successful load that shows this shop has zero drinks.
ShopDetailPhase shopDetailPhase({
  required bool loading,
  required Object? loadError,
  required bool hasProfile,
  required bool hasDrinks,
}) {
  if (loadError != null) return ShopDetailPhase.error;
  if (!hasProfile || (loading && !hasDrinks)) {
    return ShopDetailPhase.loading;
  }
  if (!hasDrinks) return ShopDetailPhase.empty;
  return ShopDetailPhase.ready;
}

class ShopDetailScreen extends StatelessWidget {
  const ShopDetailScreen({
    super.key,
    required this.repo,
    required this.shopId,
  });

  final TeaRepository repo;
  final String shopId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final item = repo.feedItem(shopId);
        final drinks = repo.drinksForShop(shopId);
        final hasDrinks = item != null && drinks.isNotEmpty;
        final phase = shopDetailPhase(
          loading: repo.loading,
          loadError: repo.loadError,
          hasProfile: repo.profile != null,
          hasDrinks: hasDrinks,
        );

        switch (phase) {
          case ShopDetailPhase.error:
            return HomeLoadError(onRetry: repo.refresh);
          case ShopDetailPhase.loading:
            return const HomeLoadSkeleton();
          case ShopDetailPhase.empty:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/');
            });
            return const SizedBox.shrink();
          case ShopDetailPhase.ready:
            break;
        }
        final feed = item!;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      feed.shop.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  GradeOrDash(
                    band: feed.band,
                    size: AppLayout.shopHeaderGradeSize,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 16),
                child: Text(
                  '${feed.visitCount} ${feed.visitCount == 1 ? 'visit' : 'visits'}',
                  style: const TextStyle(color: AppColors.chocolate),
                ),
              ),
              for (final drink in drinks) ...[
                _DrinkCard(drink: drink),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DrinkCard extends StatelessWidget {
  const _DrinkCard({required this.drink});
  final DrinkEntryRow drink;

  @override
  Widget build(BuildContext context) {
    final letter = drink.letter?.letter ?? '—';
    final date = DateFormat.yMMMd().format(drink.loggedAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (drink.letter != null)
              GradeCircle(mark: letter, size: AppLayout.historyGradeSize)
            else
              const GradeOrDash(band: null, size: AppLayout.historyGradeSize),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drink.teaName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _IconFact(
                        icon: Icons.water_drop_outlined,
                        text: '${drink.sugarLevel}%',
                      ),
                      _IconFact(
                        icon: Icons.ac_unit,
                        text: '${drink.iceLevel}%',
                      ),
                      _IconFact(icon: Icons.calendar_today_outlined, text: date),
                    ],
                  ),
                  if (drink.toppings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in drink.toppings)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.seed,
                              borderRadius: BorderRadius.all(
                                Radius.circular(AppRadii.chip),
                              ),
                            ),
                            child: Text(t.name, style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconFact extends StatelessWidget {
  const _IconFact({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.chocolate),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.chocolate)),
      ],
    );
  }
}
