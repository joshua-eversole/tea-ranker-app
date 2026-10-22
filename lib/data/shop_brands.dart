import 'package:flutter/material.dart';

import '../grading/grade.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';
import 'models.dart';

const kTintHomeRowLabel = 'Tint Home row';
const kPickMainColorTitle = 'Pick the main color';
const kAddOrReplaceLogoTooltip = 'Add or replace logo';
const kShopLogosSqlHint =
    'Paste supabase/shop_brands_and_logos.sql and supabase/shop_brands_tint_home.sql in the Supabase SQL editor.';
const kShopLogosBucket = 'shop-logos';

/// Left Home circle is slightly larger than the shop row (vertical overflow OK).
const kHomeLogoCircleSize = 80.0;

/// Deeper cream mix than [kGradeWashMix] for the no-logo Home circle fill.
const kHomeLogoCircleWashMix = 0.30;

/// Gap between the Home circle and the shop name / visit count.
const kHomeLogoCircleGap = 12.0;

/// Left inset so the circle cannot cover title or visit count.
const kHomeLogoTextInset = kHomeLogoCircleSize + kHomeLogoCircleGap;

class ShopBrand {
  const ShopBrand({
    required this.id,
    this.name,
    this.nameZh,
    this.logoPath,
    this.paletteHex = const [],
    this.selectedHex,
    this.tintHome = true,
  });

  final String id;
  final String? name;
  final String? nameZh;
  final String? logoPath;
  final List<String> paletteHex;
  final String? selectedHex;
  final bool tintHome;

  String? get englishName => trimToNull(name);
  String? get chineseName => trimToNull(nameZh);

  String get displayName {
    final en = englishName;
    final zh = chineseName;
    if (en != null && zh != null) return '$en / $zh';
    return en ?? zh ?? '';
  }

  bool get hasLogo => logoPath != null && logoPath!.trim().isNotEmpty;

  bool matchesNeedle(String raw) {
    final n = raw.trim().toLowerCase();
    if (n.isEmpty) return false;
    if (englishName?.toLowerCase() == n) return true;
    if (chineseName?.toLowerCase() == n) return true;
    if (displayName.toLowerCase() == n) return true;
    return false;
  }

  factory ShopBrand.fromMap(Map<String, dynamic> map) {
    final rawPalette = map['palette_hex'];
    final palette = <String>[];
    if (rawPalette is List) {
      for (final item in rawPalette) {
        final hex = tryNormalizeColorHex(item?.toString());
        if (hex != null) palette.add(hex);
      }
    }
    return ShopBrand(
      id: map['id'] as String,
      name: map['name'] as String?,
      nameZh: map['name_zh'] as String?,
      logoPath: map['logo_path'] as String?,
      paletteHex: palette,
      selectedHex: tryNormalizeColorHex(map['selected_hex'] as String?),
      tintHome: map['tint_home'] as bool? ?? true,
    );
  }
}

/// Same rules as the logger: case-insensitive name / name_zh / English / 中文.
bool shopMatchesBrand(ShopRow shop, ShopBrand brand) {
  for (final needle in [
    brand.englishName,
    brand.chineseName,
    brand.displayName,
  ]) {
    if (needle != null && shop.matchesNeedle(needle)) return true;
  }
  for (final needle in [shop.englishName, shop.chineseName, shop.displayName]) {
    if (needle != null && brand.matchesNeedle(needle)) return true;
  }
  return false;
}

ShopBrand? brandForShop(ShopRow shop, Iterable<ShopBrand> brands) {
  for (final brand in brands) {
    if (shopMatchesBrand(shop, brand)) return brand;
  }
  return null;
}

/// Mix [selectedHex] toward cream. Start at [kGradeWashMix]; lift (more cream)
/// until chocolate body text contrast is at least 4.5:1, or cream’s own
/// contrast if chocolate-on-cream cannot reach that floor.
Color logoPageWash(String? selectedHex) {
  final hue = colorFromHex(selectedHex, fallback: AppColors.seed);
  final creamContrast = contrastRatio(AppColors.cream, AppColors.chocolate);
  final floor = creamContrast < kToppingLabelContrastFloor
      ? creamContrast
      : kToppingLabelContrastFloor;
  var mix = kGradeWashMix;
  var wash = Color.lerp(AppColors.cream, hue, mix)!;
  while (contrastRatio(wash, AppColors.chocolate) < floor && mix > 0) {
    mix = (mix - 0.02).clamp(0.0, 1.0);
    wash = Color.lerp(AppColors.cream, hue, mix)!;
  }
  return wash;
}

Color shopDetailsPageWash({
  required ShopBrand? brand,
  required AggregateBand? band,
}) {
  if (brand != null && brand.hasLogo && brand.selectedHex != null) {
    return logoPageWash(brand.selectedHex);
  }
  return shopPageWash(band);
}

Color? homeRowWash({required ShopBrand? brand, required String? gradeMark}) {
  if (brand != null &&
      brand.hasLogo &&
      brand.selectedHex != null &&
      brand.tintHome) {
    return logoPageWash(brand.selectedHex);
  }
  return gradeWash(gradeMark);
}

/// Same grade hue as the row wash, modestly deeper toward the grade fill.
Color homeLogoCircleFill(String? gradeMark) {
  if (gradeMark == null || gradeMark.trim().isEmpty || gradeMark == '—') {
    return Color.lerp(AppColors.cream, AppColors.seed, kHomeLogoCircleWashMix)!;
  }
  return Color.lerp(
    AppColors.cream,
    colorsForMark(gradeMark).$1,
    kHomeLogoCircleWashMix,
  )!;
}

List<String> takePaletteHexes(
  Iterable<Color> colors, {
  int min = 4,
  int max = 6,
}) {
  final seen = <String>{};
  final out = <String>[];
  for (final color in colors) {
    final hex = hexFromColor(color);
    if (seen.add(hex)) out.add(hex);
    if (out.length >= max) break;
  }
  if (out.length >= min || out.isNotEmpty) return out;
  return out;
}
