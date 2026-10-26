import 'package:flutter/material.dart';

import '../data/shop_brands.dart';
import '../data/tea_types.dart';
import '../theme/tokens.dart';
import 'milk_fruit_icons.dart';

/// Cream/white Milk tile fill.
final kMilkToggleFill = Color.lerp(
  AppColors.cream,
  const Color(0xFFFFFFFF),
  0.55,
)!;

/// Citrus yellow-green Fruit tile fill.
final kFruitToggleFill = Color.lerp(
  AppColors.cream,
  const Color(0xFFC5E1A5),
  0.42,
)!;

/// Light wash for the milk icon (Home no-logo boba treatment).
final kMilkIconWash = Color.lerp(
  AppColors.cream,
  AppColors.seed,
  kHomeLogoCircleWashMix,
)!;

final kFruitIconWash = Color.lerp(
  AppColors.cream,
  const Color(0xFF9CCC65),
  kHomeLogoCircleWashMix,
)!;

class BaseToggles extends StatelessWidget {
  const BaseToggles({
    super.key,
    required this.milk,
    required this.fruit,
    required this.onMilk,
    required this.onFruit,
  });

  final bool milk;
  final bool fruit;
  final ValueChanged<bool> onMilk;
  final ValueChanged<bool> onFruit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BaseToggle(
            label: kMilkToggleLabel,
            selected: milk,
            fill: kMilkToggleFill,
            onTap: () => onMilk(!milk),
            icon: MilkGlassIcon(
              color: kMilkIconWash,
              pearlColor: kMilkToggleFill,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BaseToggle(
            label: kFruitToggleLabel,
            selected: fruit,
            fill: kFruitToggleFill,
            onTap: () => onFruit(!fruit),
            icon: CitrusIcon(
              color: kFruitIconWash,
              pearlColor: kFruitToggleFill,
              size: 36,
            ),
          ),
        ),
      ],
    );
  }
}

class _BaseToggle extends StatelessWidget {
  const _BaseToggle({
    required this.label,
    required this.selected,
    required this.fill,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final bool selected;
  final Color fill;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.boba : AppColors.seed,
          width: selected ? 3 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppLayout.minTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.boba,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
