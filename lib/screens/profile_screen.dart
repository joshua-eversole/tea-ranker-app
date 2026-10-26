import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';
import '../data/tea_repository.dart';
import '../data/tea_types.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';
import '../widgets/percent_slider.dart';
import '../widgets/taste_stats_card.dart';
import '../widgets/topping_chip.dart';
import '../widgets/topping_color_picker.dart';

/// Hardcoded display; bump `v. 0.{PR}` on every new Origin PR.
const kAppDisplayVersion = 'v. 0.24';

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
        final data = repo.profile;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      'Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const ProfileVersionLabel(),
                ],
              ),
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
              if (data != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Taste Profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TasteStatsCard(data: data),
              ],
              const SizedBox(height: 24),
              Text(
                'Drink defaults',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _DefaultSliders(
                key: ValueKey(
                  '${repo.account?.defaultSugarPercent}-${repo.account?.defaultIcePercent}',
                ),
                repo: repo,
                sugar: repo.account?.defaultSugarPercent ?? 50,
                ice: repo.account?.defaultIcePercent ?? 50,
              ),
              const SizedBox(height: 24),
              Text(
                'Topping colors',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _ToppingColorSettings(repo: repo),
              const SizedBox(height: 24),
              Text(
                'Tea type colors',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _TeaTypeColorSettings(repo: repo),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await repo.signOut();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Sign out'),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Tea Ranker · PWA',
                  style: TextStyle(color: AppColors.chocolate, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileVersionLabel extends StatelessWidget {
  const ProfileVersionLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      kAppDisplayVersion,
      style: TextStyle(
        color: AppColors.chocolate.withValues(alpha: 0.7),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
    );
  }
}

class _DefaultSliders extends StatefulWidget {
  const _DefaultSliders({
    super.key,
    required this.repo,
    required this.sugar,
    required this.ice,
  });

  final TeaRepository repo;
  final int sugar;
  final int ice;

  @override
  State<_DefaultSliders> createState() => _DefaultSlidersState();
}

class _DefaultSlidersState extends State<_DefaultSliders> {
  late double _sugar;
  late double _ice;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sugar = widget.sugar.toDouble();
    _ice = widget.ice.toDouble();
  }

  Future<void> _persist() async {
    try {
      await widget.repo.updateTasteDefaults(
        sugarPercent: _sugar.round(),
        icePercent: _ice.round(),
      );
      if (mounted) setState(() => _error = null);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Couldn’t save defaults. Paste supabase/zh_only_shops_and_profile_defaults.sql in the Supabase SQL editor.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New logs start at these sugar and ice levels.',
              style: TextStyle(color: AppColors.chocolate),
            ),
            PercentGradientSlider(
              label: 'Default sugar',
              value: _sugar,
              strongColor: AppColors.sugarRed,
              onChanged: (v) => setState(() => _sugar = v),
              onChangeEnd: (_) => _persist(),
            ),
            PercentGradientSlider(
              label: 'Default ice',
              value: _ice,
              strongColor: AppColors.iceBlue,
              onChanged: (v) => setState(() => _ice = v),
              onChangeEnd: (_) => _persist(),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.gradeD)),
          ],
        ),
      ),
    );
  }
}

class _ToppingColorSettings extends StatelessWidget {
  const _ToppingColorSettings({required this.repo});

  final TeaRepository repo;

  Future<void> _edit(BuildContext context, ToppingRow topping) async {
    final picked = await showToppingColorPicker(
      context: context,
      toppingName: topping.name,
      initialHex: normalizeColorHex(topping.colorHex),
      initialIntensity: snapIntensity(topping.colorIntensity),
    );
    if (picked == null) return;
    try {
      await repo.updateToppingColor(
        toppingId: topping.id,
        colorHex: picked.colorHex,
        colorIntensity: picked.intensity,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t save that color. Paste supabase/toppings_color_hex.sql and supabase/toppings_color_intensity.sql in the Supabase SQL editor.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final toppings = repo.toppings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tap a chip to change its background. The same fill shows on the logger and visit cards.',
              style: TextStyle(color: AppColors.chocolate),
            ),
            const SizedBox(height: 12),
            if (toppings.isEmpty)
              const Text('No toppings yet. Add one when you log a drink.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in toppings)
                    ToppingChip.fromRow(t, onTap: () => _edit(context, t)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TeaTypeColorSettings extends StatelessWidget {
  const _TeaTypeColorSettings({required this.repo});

  final TeaRepository repo;

  Future<void> _edit(BuildContext context, TeaTypeRow type) async {
    final picked = await showToppingColorPicker(
      context: context,
      toppingName: type.name,
      initialHex: normalizeColorHex(effectiveTeaTypeColorHex(type)),
      initialIntensity: snapIntensity(type.colorIntensity),
    );
    if (picked == null) return;
    try {
      await repo.updateTeaTypeColor(
        teaTypeId: type.id,
        colorHex: picked.colorHex,
        colorIntensity: picked.intensity,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t save that color. Paste supabase/tea_types_color_hex.sql in the Supabase SQL editor.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = secondaryTeaTypes(repo.teaTypes);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matcha, Hojicha, Pu’er, White, and extras. Tap a chip to change its fill. Black, Green, and Oolong stay the suggested tile colors.',
              style: TextStyle(color: AppColors.chocolate),
            ),
            const SizedBox(height: 12),
            if (types.isEmpty)
              const Text('No extra types yet. Add one when you log a drink.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in types)
                    ToppingChip(
                      label: t.name,
                      colorHex: effectiveTeaTypeColorHex(t),
                      intensity: t.colorIntensity,
                      onTap: () => _edit(context, t),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
