import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/taste_stats.dart';
import '../theme/tokens.dart';
import 'grade_circle.dart';
import 'shop_logo_circle.dart';
import 'shop_name_text.dart';
import 'topping_chip.dart';

const kTasteSheetHeaderPadding = EdgeInsets.fromLTRB(16, 4, 4, 0);
const kTasteSheetListPadding = EdgeInsets.fromLTRB(16, 0, 16, 12);
const kTasteDetailRowPadding = EdgeInsets.symmetric(vertical: 4);
const kTasteTypeRankPadding = EdgeInsets.symmetric(vertical: 4);

Future<void> showTasteDetailsSheet({
  required BuildContext context,
  required TasteProfile data,
  String? Function(ShopRow shop)? shopLogoUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: AppColors.cream,
    barrierColor: AppColors.boba.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) => TasteDetailsSheet(
      data: data,
      shopLogoUrl: shopLogoUrl,
    ),
  );
}

class TasteDetailsSheet extends StatelessWidget {
  const TasteDetailsSheet({
    super.key,
    required this.data,
    this.shopLogoUrl,
  });

  final TasteProfile data;
  final String? Function(ShopRow shop)? shopLogoUrl;

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
              padding: kTasteSheetHeaderPadding,
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
                padding: kTasteSheetListPadding,
                children: [
                  if (data.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
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
                            nameStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  for (final row in data.favoriteShopsByBase)
                    _DetailRow(
                      label: favoriteShopLabelForBase(row.drinkType),
                      value: row.shop.displayName,
                      trailing: ShopLetterOrLogo(
                        shop: row.shop,
                        band: row.band,
                        size: 36,
                        logoUrl: shopLogoUrl?.call(row.shop),
                      ),
                      valueWidget: ShopNameText(
                        shop: row.shop,
                        nameStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (data.teaTypeRankings.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 0),
                      child: Text(
                        kTeaTypeRankingsLabel,
                        style: TextStyle(
                          color: AppColors.chocolate,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    for (final row in data.teaTypeRankings)
                      _TypeRankRow(row: row),
                  ],
                  _DetailRow(
                    label: 'Average price',
                    value: formatAveragePrice(data.averagePrice),
                  ),
                  _DetailRow(
                    label: 'Favorite topping',
                    value: data.favoriteTopping ?? '—',
                    valueWidget: data.favoriteTopping == null
                        ? null
                        : ToppingChip(
                            label: data.favoriteTopping!,
                            colorHex: data.favoriteToppingColorHex,
                            intensity: data.favoriteToppingIntensity,
                            compact: true,
                          ),
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

class _TypeRankRow extends StatelessWidget {
  const _TypeRankRow({required this.row});

  final TeaTypeRanking row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kTasteTypeRankPadding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.type.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          GradeOrDash(band: row.band, size: 36),
        ],
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
      padding: kTasteDetailRowPadding,
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
                const SizedBox(height: 2),
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
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
