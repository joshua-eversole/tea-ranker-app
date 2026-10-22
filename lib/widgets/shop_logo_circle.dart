import 'package:flutter/material.dart';

import '../data/shop_brands.dart';
import '../grading/grade.dart';
import '../theme/tokens.dart';
import 'grade_circle.dart';

class ShopLogoCircle extends StatelessWidget {
  const ShopLogoCircle({
    super.key,
    required this.size,
    required this.band,
    this.brand,
    this.logoUrl,
    this.onTap,
    this.tooltip,
    this.showGradeMark = false,
  });

  final double size;
  final AggregateBand? band;
  final ShopBrand? brand;
  final String? logoUrl;
  final VoidCallback? onTap;
  final String? tooltip;

  /// Shop-details header keeps S–D with +/− when there is no logo.
  /// Home left circle is grade **fill** only; the letter stays on the right.
  final bool showGradeMark;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;
    final child = SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, _, _) => GradeOrDash(band: band, size: size),
              )
            : showGradeMark
            ? GradeOrDash(band: band, size: size)
            : ColoredBox(
                color: band == null
                    ? AppColors.seed
                    : colorsForMark(band!.label).$1,
              ),
      ),
    );
    if (onTap == null) return child;
    return Tooltip(
      message: tooltip ?? kAddOrReplaceLogoTooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}
