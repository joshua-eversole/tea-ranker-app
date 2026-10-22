import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../theme/tokens.dart';

/// Sugar %, ice %, date. Omits a % when that level is Fixed (null).
class DrinkVisitFacts extends StatelessWidget {
  const DrinkVisitFacts({super.key, required this.drink});

  final DrinkEntryRow drink;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().format(drink.loggedAt);
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        if (drink.sugarLevel != null)
          DrinkIconFact(
            icon: Icons.water_drop_outlined,
            text: '${drink.sugarLevel}%',
          ),
        if (drink.iceLevel != null)
          DrinkIconFact(icon: Icons.ac_unit, text: '${drink.iceLevel}%'),
        DrinkIconFact(icon: Icons.calendar_today_outlined, text: date),
      ],
    );
  }
}

class DrinkIconFact extends StatelessWidget {
  const DrinkIconFact({super.key, required this.icon, required this.text});
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
