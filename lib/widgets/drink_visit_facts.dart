import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/tea_types.dart';
import '../theme/tokens.dart';

/// Sugar %, ice %, date. Omits a % when that level is Fixed (null).
class DrinkVisitFacts extends StatelessWidget {
  const DrinkVisitFacts({
    super.key,
    required this.drink,
    this.showDate = true,
    this.spacious = false,
    this.includePriceAndBase = false,
    this.singleRow = false,
  });

  final DrinkEntryRow drink;
  final bool showDate;
  final bool spacious;
  final bool includePriceAndBase;
  final bool singleRow;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().format(drink.loggedAt);
    final iconSize = spacious ? 22.0 : 16.0;
    final gap = spacious ? 16.0 : 12.0;
    final facts = <Widget>[
      if (drink.sugarLevel != null)
        DrinkIconFact(
          icon: Icons.water_drop_outlined,
          text: '${drink.sugarLevel}%',
          iconSize: iconSize,
          spacious: spacious,
        ),
      if (drink.iceLevel != null)
        DrinkIconFact(
          icon: Icons.ac_unit,
          text: '${drink.iceLevel}%',
          iconSize: iconSize,
          spacious: spacious,
        ),
      if (showDate)
        DrinkIconFact(
          icon: Icons.calendar_today_outlined,
          text: date,
          iconSize: iconSize,
          spacious: spacious,
        ),
      if (includePriceAndBase)
        DrinkIconFact(
          icon: Icons.payments_outlined,
          text: formatTwd(drink.price),
          iconSize: iconSize,
          spacious: spacious,
        ),
      if (includePriceAndBase)
        DrinkIconFact(
          icon: Icons.local_cafe_outlined,
          text: drinkTypeShortLabel(drink.drinkType),
          iconSize: iconSize,
          spacious: spacious,
        ),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();
    if (singleRow) {
      return Row(
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Flexible(child: facts[i]),
          ],
        ],
      );
    }
    return Wrap(spacing: gap, runSpacing: spacious ? 12 : 6, children: facts);
  }
}

class DrinkIconFact extends StatelessWidget {
  const DrinkIconFact({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = 16,
    this.spacious = false,
  });
  final IconData icon;
  final String text;
  final double iconSize;
  final bool spacious;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: spacious
          ? const EdgeInsets.symmetric(vertical: 4, horizontal: 2)
          : EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: AppColors.chocolate),
          SizedBox(width: spacious ? 8 : 4),
          Text(
            text,
            style: TextStyle(
              color: AppColors.chocolate,
              fontSize: spacious ? 16 : 14,
              fontWeight: spacious ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
