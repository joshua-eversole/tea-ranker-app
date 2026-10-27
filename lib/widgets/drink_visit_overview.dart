import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/tea_types.dart';
import '../theme/tokens.dart';
import 'drink_visit_facts.dart';
import 'grade_circle.dart';
import 'tea_type_chip.dart';
import 'topping_chip.dart';
import 'with_companions_line.dart';

const kVisitEditTooltip = 'Edit';
const kVisitDeleteTooltip = 'Delete';

/// `{Drink name} @ {shop display name}` when a shop is set.
String drinkOverviewHeadline(DrinkEntryRow drink) {
  final shop = drink.shop?.displayName.trim();
  if (shop == null || shop.isEmpty) return drink.teaName;
  return '${drink.teaName} @ $shop';
}

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
    final shop = drink.shop?.displayName.trim();
    final date = DateFormat.yMMMd().format(drink.loggedAt);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (drink.letter != null)
                  GradeCircle(mark: letter, size: AppLayout.overviewGradeSize)
                else
                  const GradeOrDash(
                    band: null,
                    size: AppLayout.overviewGradeSize,
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: drink.teaName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: AppColors.boba,
                              ),
                            ),
                            if (shop != null && shop.isNotEmpty)
                              TextSpan(
                                text: ' @ $shop',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: AppColors.chocolate,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      DrinkIconFact(
                        icon: Icons.calendar_today_outlined,
                        text: date,
                      ),
                      TeaTypeVisitLine(drink: drink),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DrinkVisitFacts(drink: drink, showDate: false, spacious: true),
            const SizedBox(height: 12),
            Wrap(
              spacing: 28,
              runSpacing: 12,
              children: [
                DrinkIconFact(
                  icon: Icons.payments_outlined,
                  text: formatTwd(drink.price),
                  iconSize: 22,
                  spacious: true,
                ),
                DrinkIconFact(
                  icon: Icons.local_cafe_outlined,
                  text: drinkTypeShortLabel(drink.drinkType),
                  iconSize: 22,
                  spacious: true,
                ),
              ],
            ),
            if (drink.companions.isNotEmpty)
              WithCompanionsLine(
                companions: drink.companions,
                onTapLinked: onTapLinked,
              ),
            if (drink.toppings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final t in drink.toppings) ToppingChip.fromRow(t),
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
          ],
        ),
      ),
    );
  }
}
