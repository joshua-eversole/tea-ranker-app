import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';

class ToppingChip extends StatelessWidget {
  const ToppingChip({
    super.key,
    required this.label,
    this.colorHex,
    this.selected = false,
    this.compact = false,
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
      selected: selected,
      compact: compact,
      onTap: onTap,
    );
  }

  final String label;
  final String? colorHex;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fill = colorFromHex(colorHex);
    final onFill = toppingLabelColor(fill);
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final textStyle = TextStyle(
      color: onFill,
      fontSize: compact ? 12 : 14,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
    );

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: pad,
      decoration: ShapeDecoration(
        color: fill,
        shape: StadiumBorder(
          side: selected
              ? BorderSide(color: onFill, width: 2)
              : BorderSide(color: fill.withValues(alpha: 0.01)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            Icon(Icons.check, size: compact ? 14 : 16, color: onFill),
            const SizedBox(width: 4),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppLayout.minTap),
          child: Center(child: child),
        ),
      ),
    );
  }
}
