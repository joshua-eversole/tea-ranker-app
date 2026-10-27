import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import 'drink_visit_facts.dart';
import 'grade_circle.dart';
import 'tea_type_chip.dart';
import 'topping_chip.dart';
import 'with_companions_line.dart';

const kVisitEditTooltip = 'Edit';
const kVisitDeleteTooltip = 'Delete';

Future<void> showDrinkVisitOverview({
  required BuildContext context,
  required DrinkEntryRow drink,
  required VoidCallback onEdit,
  required Future<void> Function() onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    barrierColor: AppColors.boba.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) {
      return DrinkVisitOverview(
        drink: drink,
        onEdit: () {
          Navigator.pop(context);
          onEdit();
        },
        onDelete: () async {
          Navigator.pop(context);
          await onDelete();
        },
        onTapLinked: (c) {
          Navigator.pop(context);
          context.push('/social/friends/${c.userId}/drinks/${c.peerDrinkId}');
        },
      );
    },
  );
}

class DrinkVisitOverview extends StatelessWidget {
  const DrinkVisitOverview({
    super.key,
    required this.drink,
    required this.onEdit,
    required this.onDelete,
    this.onTapLinked,
  });

  final DrinkEntryRow drink;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final void Function(DrinkCompanionView companion)? onTapLinked;

  @override
  Widget build(BuildContext context) {
    final letter = drink.letter?.letter ?? '—';
    final notes = drink.notes?.trim();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.seed,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (drink.letter != null)
                  GradeCircle(mark: letter, size: AppLayout.historyGradeSize)
                else
                  const GradeOrDash(
                    band: null,
                    size: AppLayout.historyGradeSize,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drink.teaName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TeaTypeVisitLine(drink: drink),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DrinkVisitFacts(drink: drink),
            if (drink.companions.isNotEmpty)
              WithCompanionsLine(
                companions: drink.companions,
                onTapLinked: onTapLinked,
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
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                notes,
                style: const TextStyle(color: AppColors.chocolate, height: 1.3),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: AppLayout.minTap,
                  height: AppLayout.minTap,
                  child: IconButton(
                    tooltip: kVisitEditTooltip,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
                SizedBox(
                  width: AppLayout.minTap,
                  height: AppLayout.minTap,
                  child: IconButton(
                    tooltip: kVisitDeleteTooltip,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
