import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Half-style Milk/Fruit tile: rounded fill, optional wash icon, label.
class WashChoiceTile extends StatelessWidget {
  const WashChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.fill,
    required this.onTap,
    this.icon,
    this.labelColor = AppColors.boba,
  });

  final String label;
  final bool selected;
  final Color fill;
  final VoidCallback onTap;
  final Widget? icon;
  final Color labelColor;

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
                if (icon != null) ...[icon!, const SizedBox(height: 6)],
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: labelColor,
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
