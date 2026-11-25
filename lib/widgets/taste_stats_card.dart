import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/taste_stats.dart';
import '../theme/tokens.dart';
import 'grade_circle.dart';
import 'shop_logo_circle.dart';
import 'taste_details_sheet.dart';

/// Compact Taste Profile card padding (Profile + friend overlay).
const kTasteCardPadding = EdgeInsets.fromLTRB(12, 8, 12, 4);

const kTasteCardRunSpacing = 4.0;
const kTasteCardSpacing = 8.0;
const kTasteStatGap = 2.0;

/// Avg sugar, favorite base, highest shop, highest type — lives on Profile in v1.
class TasteStatsCard extends StatelessWidget {
  const TasteStatsCard({
    super.key,
    required this.data,
    this.shopLogoUrl,
  });

  final TasteProfile data;

  /// Public chain-logo URL for a shop, or null when none.
  final String? Function(ShopRow shop)? shopLogoUrl;

  @override
  Widget build(BuildContext context) {
    final highest = data.highestRatedShop;
    final highestType = data.highestRatedType;
    return Card(
      color: AppSurfaces.cardTint,
      child: Padding(
        padding: kTasteCardPadding,
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceAround,
              runSpacing: kTasteCardRunSpacing,
              spacing: kTasteCardSpacing,
              children: [
                _Stat(
                  label: 'Avg sugar',
                  value: '${data.averageSugarPercent ?? '—'}%',
                ),
                _Stat(
                  label: 'Favorite base',
                  value: data.favoriteBase ?? '—',
                ),
                _Stat(
                  label: 'Highest shop',
                  value: highest == null ? '—' : highest.shop.displayName,
                  trailing: highest == null
                      ? const GradeOrDash(
                          band: null,
                          size: AppLayout.historyGradeSize,
                        )
                      : ShopLetterOrLogo(
                          shop: highest.shop,
                          band: highest.band,
                          size: AppLayout.historyGradeSize,
                          logoUrl: shopLogoUrl?.call(highest.shop),
                        ),
                ),
                _Stat(
                  label: kHighestTypeLabel,
                  value: highestType == null ? '—' : highestType.type.name,
                  trailing: GradeOrDash(
                    band: highestType?.band,
                    size: AppLayout.historyGradeSize,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => showTasteDetailsSheet(
                  context: context,
                  data: data,
                  shopLogoUrl: shopLogoUrl,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.chocolate,
                  minimumSize: const Size(AppLayout.minTap, AppLayout.minTap),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  kMoreTasteDetailsLabel,
                  semanticsLabel: kOpenTasteDetailsHint,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.chocolate,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.trailing});
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.chocolate, fontSize: 12),
          ),
          const SizedBox(height: kTasteStatGap),
          ?trailing,
          if (trailing == null)
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
