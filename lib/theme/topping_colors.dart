import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// WCAG 2.1 contrast floor for brown/black chip labels (`AppColors.boba`).
/// Below this ratio the label switches to white.
const kToppingLabelContrastFloor = 4.5;

const kToppingLabelDark = AppColors.boba;
const kToppingLabelLight = Color(0xFFFFFFFF);
const kToppingFallbackHex = '#D4B59E';
const kToppingDefaultIntensity = 100;

int snapIntensity(int? value) {
  if (value == null) return kToppingDefaultIntensity;
  return value.clamp(0, 100);
}

/// ~10 light, bright fills offered when creating or recoloring a topping.
const toppingBrightPaletteHex = <String>[
  '#F3E1C6', // almond beige
  '#FFF59D', // pineapple yellow
  '#FFE082', // pudding / honey gold
  '#E6EE9C', // pear lime
  '#C5E1A5', // grape-foam green
  '#B2DFDB', // mint
  '#B3E5FC', // sky foam
  '#F8BBD0', // lychee pink
  '#E1BEE7', // taro lilac
  '#FFCCBC', // peach
];

/// Named catalog defaults (Joshua’s 11 + new-user seeds). Keys are lowercase.
const namedToppingColorHex = <String, String>{
  'almond jelly': '#F3E1C6',
  'grape foam': '#C5E1A5',
  'sesame milk': '#1A1A1A',
  'pineapple chunks': '#FFF59D',
  'agar jelly': '#E8F5E9',
  'ayou jelly': '#F0F4C3',
  'boba': '#3E2723',
  'coffee': '#A1887F',
  'honeycomb coffee mochi': '#FFD54F',
  'pear chunks': '#E6EE9C',
  'tea jelly': '#E6C28A',
  'pudding': '#FFE082',
  'grass jelly': '#1B3D2F',
  'aloe': '#DCEDC8',
  'red bean': '#E8A598',
  'cheese foam': '#FFF3C4',
};

final _hex6 = RegExp(r'^#?([0-9a-fA-F]{6})$');
final _hex3 = RegExp(r'^#?([0-9a-fA-F]{3})$');

String normalizeColorHex(String? raw, {String fallback = kToppingFallbackHex}) {
  return tryNormalizeColorHex(raw) ?? fallback.toUpperCase();
}

String? tryNormalizeColorHex(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  final six = _hex6.firstMatch(t);
  if (six != null) return '#${six.group(1)!.toUpperCase()}';
  final three = _hex3.firstMatch(t);
  if (three != null) {
    final c = three.group(1)!;
    return '#${(c[0] * 2 + c[1] * 2 + c[2] * 2).toUpperCase()}';
  }
  return null;
}

Color colorFromHex(String? raw, {Color fallback = AppColors.seed}) {
  final hex = tryNormalizeColorHex(raw);
  if (hex == null) return fallback;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

/// Mix the stored hue toward cream at lower intensity (0 = cream, 100 = full hue).
Color toppingFill({String? colorHex, int? intensity}) {
  final hue = colorFromHex(colorHex);
  final t = snapIntensity(intensity) / 100.0;
  return Color.lerp(AppColors.cream, hue, t)!;
}

String hexFromColor(Color color) {
  final n = color.toARGB32() & 0xFFFFFF;
  return '#${n.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

String? namedColorHexForTopping(String name) {
  return namedToppingColorHex[name.trim().toLowerCase()];
}

String colorHexForNewTopping(
  String name, {
  required Iterable<String?> existingHexes,
}) {
  final named = namedColorHexForTopping(name);
  if (named != null) return named;
  return nextBrightPaletteHex(existingHexes);
}

String nextBrightPaletteHex(Iterable<String?> existingHexes) {
  final used = existingHexes
      .map(tryNormalizeColorHex)
      .whereType<String>()
      .toSet();
  for (final hex in toppingBrightPaletteHex) {
    if (!used.contains(hex.toUpperCase())) return hex.toUpperCase();
  }
  return toppingBrightPaletteHex[existingHexes.length %
          toppingBrightPaletteHex.length]
      .toUpperCase();
}

/// Relative luminance (WCAG 2.1).
double relativeLuminance(Color color) {
  double srgb(double channel) {
    return channel <= 0.04045
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * srgb(color.r) +
      0.7152 * srgb(color.g) +
      0.0722 * srgb(color.b);
}

double contrastRatio(Color a, Color b) {
  final l1 = relativeLuminance(a);
  final l2 = relativeLuminance(b);
  final light = l1 > l2 ? l1 : l2;
  final dark = l1 > l2 ? l2 : l1;
  return (light + 0.05) / (dark + 0.05);
}

/// White label when brown/black text would sit under [kToppingLabelContrastFloor].
bool toppingFillNeedsWhiteLabel(Color fill) {
  return contrastRatio(fill, kToppingLabelDark) < kToppingLabelContrastFloor;
}

Color toppingLabelColor(Color fill) {
  return toppingFillNeedsWhiteLabel(fill)
      ? kToppingLabelLight
      : kToppingLabelDark;
}
