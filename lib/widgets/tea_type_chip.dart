import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/shop_brands.dart';
import '../data/tea_types.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';
import 'milk_fruit_icons.dart';
import 'topping_chip.dart';
import 'wash_choice_tile.dart';

Color teaTypeTileFill(TeaTypeRow row) {
  final intensity = isPrimaryTeaTypeName(row.name)
      ? kTeaTypePrimaryIntensity
      : row.colorIntensity;
  return toppingFill(
    colorHex: effectiveTeaTypeColorHex(row),
    intensity: intensity,
  );
}

Color teaTypeLeafWash(TeaTypeRow row) {
  return Color.lerp(
    AppColors.cream,
    colorFromHex(effectiveTeaTypeColorHex(row)),
    kHomeLogoCircleWashMix,
  )!;
}

/// Row 1: Black / Green / Oolong as three Milk/Fruit-style tiles with a leaf.
class TeaTypePrimaryRow extends StatelessWidget {
  const TeaTypePrimaryRow({
    super.key,
    required this.types,
    required this.selectedId,
    required this.onToggle,
  });

  final List<TeaTypeRow> types;
  final String? selectedId;
  final ValueChanged<TeaTypeRow> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < types.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _PrimaryTypeTile(
              type: types[i],
              selected: selectedId == types[i].id,
              onTap: () => onToggle(types[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryTypeTile extends StatelessWidget {
  const _PrimaryTypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final TeaTypeRow type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = teaTypeTileFill(type);
    return WashChoiceTile(
      label: type.name,
      selected: selected,
      fill: fill,
      labelColor: toppingLabelColor(fill),
      onTap: onTap,
      icon: TwoTeaLeavesIcon(
        color: teaTypeLeafWash(type),
        pearlColor: fill,
        size: 36,
      ),
    );
  }
}

/// Row 2: topping-sized chips, horizontal scroll, no wrap, no icons.
class TeaTypeSecondaryScroller extends StatelessWidget {
  const TeaTypeSecondaryScroller({
    super.key,
    required this.types,
    required this.selectedId,
    required this.onToggle,
  });

  final List<TeaTypeRow> types;
  final String? selectedId;
  final ValueChanged<TeaTypeRow> onToggle;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: AppLayout.minTap,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final t = types[index];
          return ToppingChip(
            label: t.name,
            colorHex: effectiveTeaTypeColorHex(t),
            intensity: t.colorIntensity,
            selected: selectedId == t.id,
            onTap: () => onToggle(t),
          );
        },
      ),
    );
  }
}

/// Same `{Type}` / `{Type} - {note}` line on shop visits, friend’s last 3, hangout drink.
class TeaTypeVisitLine extends StatelessWidget {
  const TeaTypeVisitLine({super.key, required this.drink});

  final DrinkEntryRow drink;

  @override
  Widget build(BuildContext context) {
    final line = drink.teaTypeLine;
    if (line == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        line,
        style: const TextStyle(color: AppColors.chocolate, fontSize: 13),
      ),
    );
  }
}
