import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../data/social.dart';
import '../data/tea_repository.dart';
import '../theme/tokens.dart';
import '../widgets/drink_visit_facts.dart';
import '../widgets/grade_circle.dart';
import '../widgets/grade_wash_surface.dart';
import '../widgets/shop_name_text.dart';
import '../widgets/taste_stats_card.dart';
import '../widgets/tea_skeleton.dart';
import '../widgets/topping_chip.dart';
import '../widgets/with_companions_line.dart';
import 'home_screen.dart';

class FriendTasteScreen extends StatefulWidget {
  const FriendTasteScreen({
    super.key,
    required this.repo,
    required this.userId,
  });

  final TeaRepository repo;
  final String userId;

  @override
  State<FriendTasteScreen> createState() => _FriendTasteScreenState();
}

class _FriendTasteScreenState extends State<FriendTasteScreen> {
  bool _loading = true;
  Object? _error;
  TasteProfile? _data;
  String _username = 'Friend';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final directory = await widget.repo.loadDirectory();
      DirectoryProfile? person;
      for (final p in directory) {
        if (p.id == widget.userId) person = p;
      }
      final data = await widget.repo.fetchFriendTaste(widget.userId);
      if (!mounted) return;
      setState(() {
        _username = person?.username.trim().isNotEmpty == true
            ? person!.username
            : 'Friend';
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return HomeLoadError(onRetry: _load, message: kFriendErrorCopy);
    }
    if (_loading || _data == null) {
      return _FriendSkeleton(username: _username);
    }
    final data = _data!;
    final recent = lastDrinks(data.entries);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 24, 32),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => context.go('/social'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  _username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  kFriendTasteTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TasteStatsCard(data: data),
                const SizedBox(height: 28),
                Text(
                  kFriendLastDrinksTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (recent.isEmpty)
                  const Text(
                    kFriendNoDrinksCopy,
                    style: TextStyle(color: AppColors.chocolate),
                  )
                else
                  for (final drink in recent) ...[
                    FriendDrinkCard(drink: drink),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FriendDrinkCard extends StatelessWidget {
  const FriendDrinkCard({super.key, required this.drink});

  final DrinkEntryRow drink;

  @override
  Widget build(BuildContext context) {
    final letter = drink.letter?.letter ?? '—';
    return GradeWashSurface(
      mark: drink.letter?.letter,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  if (drink.shop != null) ...[
                    const SizedBox(height: 4),
                    ShopNameText(
                      shop: drink.shop!,
                      nameStyle: const TextStyle(
                        color: AppColors.chocolate,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  DrinkVisitFacts(drink: drink),
                  if (drink.companions.isNotEmpty)
                    WithCompanionsLine(
                      companions: drink.companions,
                      onTapLinked: (c) => context.push(
                        '/social/friends/${c.userId}/drinks/${c.peerDrinkId}',
                      ),
                    ),
                  if (drink.toppings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in drink.toppings)
                          ToppingChip.fromRow(t, compact: true),
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

class _FriendSkeleton extends StatelessWidget {
  const _FriendSkeleton({required this.username});
  final String username;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: TeaSkeleton(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(username, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text(
              kFriendLoadingCopy,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.chocolate,
              ),
            ),
            const SizedBox(height: 20),
            const TeaBone(height: 120),
            const SizedBox(height: 16),
            const TeaBone(height: 88),
            const SizedBox(height: 12),
            const TeaBone(height: 88),
          ],
        ),
      ),
    );
  }
}
