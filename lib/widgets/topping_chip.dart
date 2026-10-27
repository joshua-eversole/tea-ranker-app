import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';
import 'new_catalog_dialogs.dart';

class ToppingChip extends StatelessWidget {
  const ToppingChip({
    super.key,
    required this.label,
    this.colorHex,
    this.intensity,
    this.selected = false,
    this.compact = false,
    this.addNew = false,
    this.onTap,
  });

  factory ToppingChip.fromRow(
    ToppingRow topping, {
    bool selected = false,
    bool compact = false,
    VoidCallback? onTap,
  }) {
    return ToppingChip(
      label: topping.name,
      colorHex: topping.colorHex,
      intensity: topping.colorIntensity,
      selected: selected,
      compact: compact,
      onTap: onTap,
    );
  }

  factory ToppingChip.addNew({VoidCallback? onTap, bool compact = false}) {
    return ToppingChip(
      label: kAddNewChipLabel,
      colorHex: kAddNewChipHex,
      intensity: kToppingDefaultIntensity,
      compact: compact,
      addNew: true,
      onTap: onTap,
    );
  }

  final String label;
  final String? colorHex;
  final int? intensity;
  final bool selected;
  final bool compact;
  final bool addNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fill = toppingFill(colorHex: colorHex, intensity: intensity);
    final onFill = addNew ? AppColors.boba : toppingLabelColor(fill);
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final textStyle = TextStyle(
      color: onFill,
      fontSize: compact ? 12 : 14,
      fontWeight: addNew
          ? FontWeight.w700
          : (selected ? FontWeight.w600 : FontWeight.w400),
    );
    final BorderSide side;
    if (addNew) {
      side = const BorderSide(color: AppColors.boba, width: 1.5);
    } else if (selected) {
      side = BorderSide(color: onFill, width: 2);
    } else {
      side = BorderSide(color: fill.withValues(alpha: 0.01));
    }

    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: pad,
      decoration: ShapeDecoration(
        color: fill,
        shape: StadiumBorder(side: side),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected && !addNew) ...[
            Icon(Icons.check, size: compact ? 14 : 16, color: onFill),
            const SizedBox(width: 4),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );

    // Shrink-wrap so Wrap can put several chips on one row. Do not expand
    // to the Wrap's max width (Center / loose Align would stack one per line).
    final sized = onTap == null
        ? pill
        : Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              customBorder: const StadiumBorder(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppLayout.minTap),
                child: Align(
                  alignment: Alignment.center,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: pill,
                ),
              ),
            ),
          );

    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: sized,
    );
  }
}
