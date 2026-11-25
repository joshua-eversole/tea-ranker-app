import 'package:flutter/material.dart';

import '../data/models.dart';
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

  /// Fill the circle and center-crop. Never letterbox a rectangle inside the
  /// disc (HTML `<img>` on web ignores [BoxFit.cover] unless we skip it).
  Widget _coverCroppedLogo(String url) {
    return ColoredBox(
      color: _placeholder,
      child: Image.network(
        url,
        key: const ValueKey('shopLogoCover'),
        fit: BoxFit.cover,
        width: size,
        height: size,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        webHtmlElementStrategy: WebHtmlElementStrategy.never,
        errorBuilder: (_, _, _) => _placeholderChild(),
      ),
    );
  }

  /// Tight square disc. Home overhangs via a parent OverflowBox with a
  /// **bounded** height (Positioned top/bottom). Do not wrap this disc in
  /// OverflowBox — [OverflowBoxFit.max] + an unbounded header Row is infinite
  /// height and blanks shop details.
  Widget _squareDisc() {
    final url = logoUrl;
    final image = url != null && url.isNotEmpty
        ? _coverCroppedLogo(url)
        : _placeholderChild();
    return SizedBox(
      key: const ValueKey('shopLogoDisc'),
      width: size,
      height: size,
      child: ClipOval(clipBehavior: Clip.antiAlias, child: image),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disc = _squareDisc();
    if (onTap == null) return disc;
    return Tooltip(
      message: tooltip ?? kAddOrReplaceLogoTooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: disc,
          ),
        ),
      ),
    );
  }
}

/// Taste Profile / friend overlay: chain logo fills the letter circle when we
/// already have one. No logo → keep the grade (or em dash).
class ShopLetterOrLogo extends StatelessWidget {
  const ShopLetterOrLogo({
    super.key,
    required this.shop,
    required this.band,
    required this.size,
    this.logoUrl,
  });

  final ShopRow shop;
  final AggregateBand? band;
  final double size;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ShopLogoCircle(
        size: size,
        band: band,
        logoUrl: url,
      );
    }
    return GradeOrDash(band: band, size: size);
  }
}
