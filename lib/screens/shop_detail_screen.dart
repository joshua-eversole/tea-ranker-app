import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/shop_brands.dart';
import '../data/tea_repository.dart';
import '../theme/tokens.dart';
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
  int _tab = 0;
  final _notes = TextEditingController();
  String? _notesShopId;
  bool _savingNotes = false;
  String? _notesError;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _syncNotes(ShopRow shop) {
    if (_notesShopId == shop.id) return;
    _notesShopId = shop.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _notesShopId != shop.id) return;
      _notes.text = shop.notes ?? '';
    });
  }

  Future<void> _saveNotes(ShopRow shop) async {
    setState(() {
      _savingNotes = true;
      _notesError = null;
    });
    try {
      await widget.repo.updateShopNotes(shopId: shop.id, notes: _notes.text);
      if (mounted) {
        setState(() => _savingNotes = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _savingNotes = false;
          _notesError =
              'Couldn’t save shop notes. Paste supabase/zh_only_shops_and_profile_defaults.sql in the Supabase SQL editor.';
        });
      }
    }
  }

  Future<void> _editNames(ShopRow shop) async {
    final name = TextEditingController(text: shop.name ?? '');
    final zh = TextEditingController(text: shop.nameZh ?? '');
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.cream,
            title: const Text('Shop names'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'English'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: zh,
                  decoration: const InputDecoration(labelText: '中文'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (name.text.trim().isEmpty && zh.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      if (saved != true || !mounted) return;
      await widget.repo.updateShopNames(
        shopId: shop.id,
        name: name.text,
        nameZh: zh.text,
      );
    } finally {
      name.dispose();
      zh.dispose();
    }
  }

  Future<void> _openLogoSheet(ShopRow shop) async {
    final result = await showShopLogoSheet(
      context: context,
      brand: widget.repo.brandFor(shop),
    );
    if (result == null || !mounted) return;
    try {
      await widget.repo.saveShopBrandSettings(
        shop: shop,
        bytes: result.bytes,
        contentType: result.contentType,
        paletteHex: result.paletteHex,
        selectedHex: result.selectedHex,
        tintHome: result.tintHome,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn’t save that logo. $kShopLogosSqlHint'),
        ),
      );
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
        _syncNotes(feed.shop);
        final brand = widget.repo.brandFor(feed.shop);
        return ColoredBox(
          color: shopDetailsPageWash(brand: brand, band: feed.band),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                  child: Row(
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
                      IconButton(
                        tooltip: 'Edit names',
                        onPressed: () => _editNames(feed.shop),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      ShopLogoCircle(
                        size: AppLayout.shopHeaderGradeSize,
                        band: feed.band,
                        brand: brand,
                        logoUrl: widget.repo.publicLogoUrl(brand),
                        showGradeMark: true,
                        tooltip: kAddOrReplaceLogoTooltip,
                        onTap: () => _openLogoSheet(feed.shop),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _DetailTab(
                        label: 'Visits',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      const SizedBox(width: 8),
                      _DetailTab(
                        label: 'Notes',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _tab == 0
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            for (final drink in drinks) ...[
                              DrinkVisitCard(
                                drink: drink,
                                onEdit: () => _editVisit(drink),
                                onDelete: () => _deleteVisit(drink),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        )
                      : _ShopNotesTab(
                          controller: _notes,
                          saving: _savingNotes,
                          error: _notesError,
                          onSave: () => _saveNotes(feed.shop),
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

class _DetailTab extends StatelessWidget {
  const _DetailTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.boba : AppColors.seed,
      borderRadius: BorderRadius.circular(AppRadii.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.boba,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopNotesTab extends StatelessWidget {
  const _ShopNotesTab({
    required this.controller,
    required this.saving,
    required this.error,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool saving;
  final String? error;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text(
          'Notes about this shop — parking, regular order, hours. Drink notes stay on each log.',
          style: TextStyle(color: AppColors.chocolate),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          minLines: 6,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'Add a shop note',
            alignLabelWithHint: true,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.gradeD)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: saving ? null : onSave,
          child: Text(saving ? 'Saving…' : 'Save notes'),
        ),
      ],
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
    final date = DateFormat.yMMMd().format(drink.loggedAt);
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
                      _IconFact(
                        icon: Icons.calendar_today_outlined,
                        text: date,
                      ),
                    ],
                  ),
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
