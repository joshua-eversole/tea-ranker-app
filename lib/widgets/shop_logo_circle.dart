import 'package:flutter/material.dart';

import '../data/shop_brands.dart';
import '../grading/grade.dart';
import 'boba_cup_icon.dart';
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
    this.showBobaIcon = false,
    this.fill,
    this.iconColor,
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

  /// Home no-logo flair. Never drawn on top of a logo photo.
  final bool showBobaIcon;

  /// Home no-logo fill — slightly deeper than the row wash.
  final Color? fill;

  /// Lighter row-wash color for the boba cup icon.
  final Color? iconColor;

  Color get _placeholder {
    return fill ?? homeLogoCircleFill(band?.label);
  }

  Widget _placeholderChild() {
    if (showGradeMark) {
      return GradeOrDash(band: band, size: size);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: _placeholder),
        if (showBobaIcon)
          Center(
            child: BobaCupIcon(
              color: iconColor ?? gradeWash(band?.label),
              pearlColor: _placeholder,
              size: size * 0.44,
            ),
          ),
      ],
    );
  }

  /// Square disc that ignores a short parent max-height (Home row).
  Widget _squareDisc() {
    final url = logoUrl;
    final image = url != null && url.isNotEmpty
        ? SizedBox.square(
            dimension: size,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: size,
              height: size,
              alignment: Alignment.center,
              errorBuilder: (_, _, _) => _placeholderChild(),
            ),
          )
        : _placeholderChild();
    return OverflowBox(
      alignment: Alignment.center,
      minWidth: size,
      maxWidth: size,
      minHeight: size,
      maxHeight: size,
      child: SizedBox(
        key: const ValueKey('shopLogoDisc'),
        width: size,
        height: size,
        child: ClipOval(child: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disc = _squareDisc();
    if (onTap == null) return disc;
    return Tooltip(
      message: tooltip ?? kAddOrReplaceLogoTooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: disc,
        ),
      ),
    );
  }
}
