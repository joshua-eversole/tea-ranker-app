import 'package:flutter/material.dart';

import 'tokens.dart';
import 'topping_colors.dart';

/// Stronger than visit-card wash so friend cards have identity, still cream-mix.
const kFriendCardWashMix = 0.28;

/// Avatar disc uses the seed-tint mix so initials read on the paler card.
const kFriendAvatarWashMix = 0.42;

/// Saturated app hues (grades + seed) plus mid topping-palette chips.
/// Mix toward cream — never the raw neon fill.
const kFriendCardHues = <Color>[
  AppColors.seed,
  AppColors.gradeS,
  AppColors.gradeAPlus,
  AppColors.gradeA,
  AppColors.gradeBPlus,
  AppColors.gradeB,
  AppColors.gradeCPlus,
  AppColors.gradeC,
  Color(0xFFC5E1A5),
  Color(0xFFB2DFDB),
  Color(0xFFB3E5FC),
  Color(0xFFF8BBD0),
  Color(0xFFE1BEE7),
  Color(0xFFFFCCBC),
  Color(0xFFE6C28A),
];

int stableFriendHash(String id, String username) {
  // FNV-1a 32-bit. Dart String.hashCode is not stable across runtimes.
  var hash = 0x811c9dc5;
  void absorb(String s) {
    for (final unit in s.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
  }

  absorb(id);
  hash ^= 0x1F;
  hash = (hash * 0x01000193) & 0xFFFFFFFF;
  absorb(username);
  return hash;
}

Color friendHueFor(String id, String username) {
  final hues = kFriendCardHues;
  final index = stableFriendHash(id, username) % hues.length;
  return hues[index];
}

Color friendCardWash(String id, String username) {
  return Color.lerp(
    AppColors.cream,
    friendHueFor(id, username),
    kFriendCardWashMix,
  )!;
}

Color friendAvatarWash(String id, String username) {
  return Color.lerp(
    AppColors.cream,
    friendHueFor(id, username),
    kFriendAvatarWashMix,
  )!;
}

Color friendInitialsColor(Color fill) => toppingLabelColor(fill);
