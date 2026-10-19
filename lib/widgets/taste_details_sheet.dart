import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/taste_stats.dart';
import '../theme/tokens.dart';
import 'grade_circle.dart';
import 'shop_name_text.dart';

Future<void> showTasteDetailsSheet({
  required BuildContext context,
  required TasteProfile data,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: AppColors.cream,
    barrierColor: AppColors.boba.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadii.card),
      ),
    ),
    builder: (context) => TasteDetailsSheet(data: data),
  );
}

class TasteDetailsSheet extends StatelessWidget {
  const TasteDetailsSheet({super.key, required this.data});

  final TasteProfile data;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      kTasteDetailsTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: kCloseTasteDetailsTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  if (data.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        kNoDrinksYetCopy,
                        style: TextStyle(color: AppColors.chocolate),
                      ),
                    ),
                  _DetailRow(
                    label: 'Avg ice',
                    value: formatAveragePercent(data.averageIcePercent),
                  ),
                  _DetailRow(
                    label: 'Most visited shop',
                    value: data.mostVisitedShop?.shop.displayName ?? '—',
                    valueWidget: data.mostVisitedShop == null
                        ? null
                        : ShopNameText(
                            shop: data.mostVisitedShop!.shop,
                            nameStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                  for (final row in data.favoriteShopsByBase)
                    _DetailRow(
                      label: favoriteShopLabelForBase(row.drinkType),
                      value: row.shop.displayName,
                      trailing: GradeOrDash(
                        band: row.band,
                        size: 36,
                      ),
                      valueWidget: ShopNameText(
                        shop: row.shop,
                        nameStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  _DetailRow(
                    label: 'Average price',
                    value: formatAveragePrice(data.averagePrice),
                  ),
                  _DetailRow(
                    label: 'Favorite topping',
                    value: data.favoriteTopping ?? '—',
                  ),
                  _DetailRow(
                    label: 'Days since last drink',
                    value: formatDaysSinceLastDrink(data.daysSinceLastDrink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.trailing,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.chocolate,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                valueWidget ??
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
