import 'package:flutter/material.dart';

import '../grading/grade.dart';
import '../theme/tokens.dart';
import '../theme/topping_colors.dart';
import 'models.dart';

const kTintHomeRowLabel = 'Tint Home row';
const kPickMainColorTitle = 'Pick the main color';
const kAddOrReplaceLogoTooltip = 'Add or replace logo';
const kShopLogosSqlHint =
    'Couldn’t save shop logo settings. Check shop_brands selected_hex / logo_path.';
const kShopLogosBucket = 'shop-logos';

/// Left Home circle is slightly larger than the shop row (vertical overflow OK).
const kHomeLogoCircleSize = 80.0;

/// Deeper cream mix than [kGradeWashMix] for the no-logo Home circle fill.
const kHomeLogoCircleWashMix = 0.30;

/// Logo page/row wash — stronger than grade wash so the chosen hue reads.
const kLogoWashMix = 0.40;

/// Never lift logo wash all the way to cream (that looked like grade-only).
const kLogoWashMixFloor = 0.22;

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

  /// Chosen chip, or the first extracted palette color if `selected_hex` is empty.
  String? get effectiveSelectedHex =>
      selectedHex ?? (paletteHex.isNotEmpty ? paletteHex.first : null);

  bool matchesNeedle(String raw) {
    final n = _canon(raw);
    if (n.isEmpty) return false;
    for (final needle in _nameNeedles(englishName, chineseName, displayName)) {
      if (_canon(needle) == n) return true;
    }
    return false;
  }

  factory ShopBrand.fromMap(Map<String, dynamic> map) {
    final id = _asString(map['id']);
    if (id == null) {
      throw FormatException('shop_brands row missing id');
    }
    final palette = _paletteFrom(map);
    final selected =
        tryNormalizeColorHex(_asString(map['selected_hex'])) ??
        tryNormalizeColorHex(_asString(map['color_hex'])) ??
        (palette.isNotEmpty ? palette.first : null);
    return ShopBrand(
      id: id,
      name: _asString(map['name']),
      nameZh: _asString(map['name_zh']) ?? _asString(map['nameZh']),
      logoPath:
          _asString(map['logo_path']) ??
          _asString(map['logo_url']) ??
          _asString(map['path']),
      paletteHex: palette,
      selectedHex: selected,
      tintHome: _asBool(map['tint_home']) ?? true,
    );
  }
}

/// Same rules as the logger: case-insensitive name / name_zh / English / 中文.
bool shopMatchesBrand(ShopRow shop, ShopBrand brand) {
  final brandNeedles = _nameNeedles(
    brand.englishName,
    brand.chineseName,
    brand.displayName,
  ).map(_canon).where((n) => n.isNotEmpty).toSet();
  final shopNeedles = _nameNeedles(
    shop.englishName,
    shop.chineseName,
    shop.displayName,
  ).map(_canon).where((n) => n.isNotEmpty).toSet();
  return brandNeedles.intersection(shopNeedles).isNotEmpty;
}

ShopBrand? brandForShop(ShopRow shop, Iterable<ShopBrand> brands) {
  for (final brand in brands) {
    if (shopMatchesBrand(shop, brand)) return brand;
  }
  return null;
}

/// Mix [selectedHex] toward cream. Stronger than grade wash so the hue shows;
/// lift (more cream) only down to [kLogoWashMixFloor], never to plain cream.
Color logoPageWash(String? selectedHex) {
  final hue = colorFromHex(selectedHex, fallback: AppColors.seed);
  var mix = kLogoWashMix;
  var wash = Color.lerp(AppColors.cream, hue, mix)!;
  final creamContrast = contrastRatio(AppColors.cream, AppColors.chocolate);
  while (contrastRatio(wash, AppColors.chocolate) < creamContrast * 0.9 &&
      mix > kLogoWashMixFloor) {
    mix = (mix - 0.02).clamp(kLogoWashMixFloor, 1.0);
    wash = Color.lerp(AppColors.cream, hue, mix)!;
  }
  return wash;
}

Color shopDetailsPageWash({
  required ShopBrand? brand,
  required AggregateBand? band,
}) {
  final hex = brand?.effectiveSelectedHex;
  if (brand != null && brand.hasLogo && hex != null) {
    return logoPageWash(hex);
  }
  return shopPageWash(band);
}

Color? homeRowWash({required ShopBrand? brand, required String? gradeMark}) {
  final hex = brand?.effectiveSelectedHex;
  if (brand != null && brand.hasLogo && hex != null && brand.tintHome) {
    return logoPageWash(hex);
  }
  return gradeWash(gradeMark);
}

/// Storage object path, or a full http(s) URL already stored in the column.
String? resolveLogoUrl(
  String? logoPath, {
  required String Function(String objectPath) publicUrlFor,
}) {
  final path = logoPath?.trim();
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final object = path.startsWith('$kShopLogosBucket/')
      ? path.substring(kShopLogosBucket.length + 1)
      : path;
  return publicUrlFor(object);
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

String _canon(String raw) =>
    raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

Iterable<String> _nameNeedles(String? en, String? zh, String display) sync* {
  if (en != null && en.trim().isNotEmpty) yield en;
  if (zh != null && zh.trim().isNotEmpty) yield zh;
  if (display.trim().isNotEmpty) yield display;
  for (final part in display.split('/')) {
    final t = part.trim();
    if (t.isNotEmpty) yield t;
  }
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final t = value.toString().trim();
  return t.isEmpty ? null : t;
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final n = value.trim().toLowerCase();
    if (n == 'true' || n == '1') return true;
    if (n == 'false' || n == '0') return false;
  }
  return null;
}

List<String> _paletteFrom(Map<String, dynamic> map) {
  final raw = map['palette_hex'] ?? map['palette'];
  final out = <String>[];
  void add(dynamic item) {
    final hex = tryNormalizeColorHex(_asString(item));
    if (hex != null && !out.contains(hex)) out.add(hex);
  }

  if (raw is List) {
    for (final item in raw) {
      add(item);
    }
  } else if (raw is String) {
    for (final part in raw.split(RegExp(r'[^#0-9a-fA-F]+'))) {
      add(part);
    }
  }
  return out;
}
