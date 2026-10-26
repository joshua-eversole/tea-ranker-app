import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';

class TeaTypeChip extends StatelessWidget {
  const TeaTypeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.large = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? AppColors.boba : AppColors.seed;
    final onFill = selected ? Colors.white : AppColors.boba;
    return Material(
      color: fill,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.minTap,
            minWidth: AppLayout.minTap,
          ),
          child: Padding(
            padding: large
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: onFill,
                  fontWeight: FontWeight.w600,
                  fontSize: large ? 16 : 13,
                ),
              ),
            ),
          ),
        ),
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
