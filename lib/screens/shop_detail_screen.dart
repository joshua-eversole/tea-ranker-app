import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../data/shop_brands.dart';
import '../data/tea_repository.dart';
import '../theme/tokens.dart';
import '../widgets/drink_visit_facts.dart';
import '../widgets/grade_circle.dart';
import '../widgets/grade_wash_surface.dart';
import '../widgets/logo_color_picker.dart';
import '../widgets/shop_logo_circle.dart';
import '../widgets/shop_name_text.dart';
import '../widgets/topping_chip.dart';
import '../widgets/with_companions_line.dart';
import 'home_screen.dart';

const kDeleteVisitConfirmMessage = 'Are you sure you want to delete this?';

Future<bool> confirmDeleteVisit(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Delete visit'),
        content: const Text(kDeleteVisitConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return result == true;
}

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

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({super.key, required this.repo, required this.shopId});

  final TeaRepository repo;
  final String shopId;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  Future<void> _openChromeSheet(ShopRow shop) async {
    final result = await showShopChromeSheet(
      context: context,
      shop: shop,
      brand: widget.repo.brandFor(shop),
    );
    if (result == null || !mounted) return;
    try {
      await widget.repo.updateShopNames(
        shopId: shop.id,
        name: result.name,
        nameZh: result.nameZh,
      );
      if (!mounted) return;
      final latest = widget.repo.feedItem(shop.id)?.shop ?? shop;
      await widget.repo.saveShopBrandSettings(
        shop: latest,
        bytes: result.bytes,
        contentType: result.contentType,
        paletteHex: result.paletteHex,
        selectedHex: result.selectedHex,
        tintHome: result.tintHome,
        tintStrength: result.tintStrength,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn’t save shop settings. $kShopLogosSqlHint'),
        ),
      );
    }
  }

  Future<void> _editNotes(ShopRow shop) async {
    final notes = TextEditingController(text: shop.notes ?? '');
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.cream,
            title: const Text(kShopNotesTitle),
            content: TextField(
              controller: notes,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: kAddShopNotesHint,
                alignLabelWithHint: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      if (saved != true || !mounted) return;
      await widget.repo.updateShopNotes(shopId: shop.id, notes: notes.text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Couldn’t save shop notes. Paste supabase/zh_only_shops_and_profile_defaults.sql in the Supabase SQL editor.',
          ),
        ),
      );
    } finally {
      notes.dispose();
    }
  }

  Future<void> _editVisit(DrinkEntryRow drink) async {
    await context.push('/log/${drink.id}');
  }

  Future<void> _deleteVisit(DrinkEntryRow drink) async {
    final ok = await confirmDeleteVisit(context);
    if (!ok || !mounted) return;
    try {
      await widget.repo.deleteDrink(drink.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t delete that visit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        final item = widget.repo.feedItem(widget.shopId);
        final drinks = widget.repo.drinksForShop(widget.shopId);
        final hasDrinks = item != null && drinks.isNotEmpty;
        final phase = shopDetailPhase(
          loading: widget.repo.loading,
          loadError: widget.repo.loadError,
          hasProfile: widget.repo.profile != null,
          hasDrinks: hasDrinks,
        );

        switch (phase) {
          case ShopDetailPhase.error:
            return HomeLoadError(onRetry: widget.repo.refresh);
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
        final brand = widget.repo.brandFor(feed.shop);
        return ColoredBox(
          color: shopDetailsPageWash(brand: brand, band: feed.band),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      Expanded(child: ShopNameText(shop: feed.shop)),
                      SizedBox(
                        width: AppLayout.minTap,
                        height: AppLayout.minTap,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: kEditShopTooltip,
                          onPressed: () => _openChromeSheet(feed.shop),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                      ShopLogoCircle(
                        size: AppLayout.shopHeaderGradeSize,
                        band: feed.band,
                        brand: brand,
                        logoUrl: widget.repo.publicLogoUrl(brand),
                        showGradeMark: true,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${feed.visitCount} ${feed.visitCount == 1 ? 'visit' : 'visits'}',
                      style: const TextStyle(color: AppColors.chocolate),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      ShopNotesBlock(
                        notes: feed.shop.notes,
                        onTap: () => _editNotes(feed.shop),
                      ),
                      const SizedBox(height: 12),
                      for (final drink in drinks) ...[
                        DrinkVisitCard(
                          drink: drink,
                          onEdit: () => _editVisit(drink),
                          onDelete: () => _deleteVisit(drink),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
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

class ShopNotesBlock extends StatelessWidget {
  const ShopNotesBlock({super.key, required this.notes, required this.onTap});

  final String? notes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = notes?.trim();
    final empty = text == null || text.isEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppLayout.minTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Text(
              empty ? kAddShopNotesHint : text,
              style: TextStyle(
                color: AppColors.chocolate,
                fontSize: 13,
                fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DrinkVisitCard extends StatelessWidget {
  const DrinkVisitCard({
    super.key,
    required this.drink,
    required this.onEdit,
    required this.onDelete,
  });

  final DrinkEntryRow drink;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final letter = drink.letter?.letter ?? '—';
    return GradeWashSurface(
      mark: drink.letter?.letter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
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
            SizedBox(
              width: AppLayout.minTap,
              height: AppLayout.minTap,
              child: PopupMenuButton<String>(
                tooltip: 'Edit or delete this visit',
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

