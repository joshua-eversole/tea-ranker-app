import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/taste_stats.dart';
import '../theme/tokens.dart';
import 'grade_circle.dart';
import 'taste_details_sheet.dart';

/// Avg sugar, favorite base, highest shop — lives on Profile in v1.
class TasteStatsCard extends StatelessWidget {
  const TasteStatsCard({super.key, required this.data});

  final TasteProfile data;

  @override
  Widget build(BuildContext context) {
    final highest = data.highestRatedShop;
    return Card(
      color: AppSurfaces.cardTint,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceAround,
              runSpacing: 12,
              spacing: 12,
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
                  trailing: GradeOrDash(
                    band: highest?.band,
                    size: AppLayout.historyGradeSize,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => showTasteDetailsSheet(
                  context: context,
                  data: data,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.chocolate,
                  minimumSize: const Size(AppLayout.minTap, AppLayout.minTap),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          const SizedBox(height: 6),
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
              padding: const EdgeInsets.only(top: 4),
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
