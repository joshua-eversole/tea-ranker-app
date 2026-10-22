import 'package:flutter/material.dart';

import '../data/shop_brands.dart';
import '../grading/grade.dart';
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
    this.fill,
  });

  final double size;
  final AggregateBand? band;
  final ShopBrand? brand;
  final String? logoUrl;
  final VoidCallback? onTap;
  final String? tooltip;

  /// Shop-details header keeps S–D with +/− when there is no logo.
  /// Home left circle is wash **fill** only; the letter stays on the right.
  final bool showGradeMark;

  /// Home no-logo fill — same cream mix as the shop row, not the letter disc.
  final Color? fill;

  Color get _placeholder {
    return fill ?? gradeWash(band?.label);
  }

  Widget _placeholderChild() {
    if (showGradeMark) {
      return GradeOrDash(band: band, size: size);
    }
    return ColoredBox(color: _placeholder);
  }

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
                errorBuilder: (_, _, _) => _placeholderChild(),
              )
            : _placeholderChild(),
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
