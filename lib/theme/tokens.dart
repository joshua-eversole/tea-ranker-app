import 'package:flutter/material.dart';

abstract final class AppColors {
  static const cream = Color(0xFFFAF3E0);
  static const chocolate = Color(0xFF8D6E63);
  static const seed = Color(0xFFD4B59E);
  static const boba = Color(0xFF2C1E16);
  static const bobaWatching = Color(0xFF1A110C);

  static const gradeS = Color(0xFFE6B422);
  static const gradeSOn = Color(0xFF2C1E16);
  static const gradeAPlus = Color(0xFF43A047);
  static const gradeA = Color(0xFF2E7D32);
  static const gradeAMinus = Color(0xFF1B5E20);
  static const gradeBPlus = Color(0xFF1E88E5);
  static const gradeB = Color(0xFF1565C0);
  static const gradeBMinus = Color(0xFF0D47A1);
  static const gradeCPlus = Color(0xFFFB8C00);
  static const gradeC = Color(0xFFEF6C00);
  static const gradeCMinus = Color(0xFFE65100);
  static const gradeDPlus = Color(0xFFE53935);
  static const gradeD = Color(0xFFC62828);
  static const gradeDMinus = Color(0xFF8E0000);
}

abstract final class AppRadii {
  static const card = 24.0;
  static const chip = 999.0;
}

/// Cream cards with a seed-tinted sibling for stats / emphasis.
abstract final class AppSurfaces {
  static const card = AppColors.cream;
  static final cardTint = Color.lerp(AppColors.cream, AppColors.seed, 0.42)!;
  static final bone = AppColors.seed.withValues(alpha: 0.42);
  static final boneHighlight = AppColors.seed.withValues(alpha: 0.72);
}

abstract final class AppLayout {
  static const maxContentWidth = 430.0;
  static const addSlotSize = 64.0;
  static const addSlotOverhang = 12.0;
  static const barContentHeight = addSlotSize - addSlotOverhang; // 52
  static const historyGradeSize = 48.0;
  static const shopHeaderGradeSize = 64.0;
  static const minTap = 44.0;
}

ThemeData buildTeaTheme() {
  const family = 'Nunito';
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
      primary: AppColors.boba,
      onPrimary: Colors.white,
      surface: AppColors.cream,
      onSurface: AppColors.boba,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          fontFamily: family,
          bodyColor: AppColors.boba,
          displayColor: AppColors.boba,
        )
        .copyWith(
          titleLarge: const TextStyle(
            fontFamily: family,
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: AppColors.boba,
          ),
          titleMedium: const TextStyle(
            fontFamily: family,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.boba,
          ),
          bodyLarge: const TextStyle(
            fontFamily: family,
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: AppColors.boba,
          ),
          bodyMedium: const TextStyle(
            fontFamily: family,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: AppColors.boba,
          ),
          labelLarge: const TextStyle(
            fontFamily: family,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.boba,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.boba,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: AppColors.boba,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppSurfaces.card,
      elevation: 2,
      shadowColor: AppColors.boba.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.seed, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.seed,
      selectedColor: AppColors.boba,
      labelStyle: const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w400,
        color: AppColors.boba,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      shape: const StadiumBorder(),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.boba,
      thumbColor: AppColors.boba,
      inactiveTrackColor: AppColors.seed,
      overlayColor: AppColors.boba.withValues(alpha: 0.12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.boba,
        foregroundColor: Colors.white,
        minimumSize: const Size(AppLayout.minTap, AppLayout.minTap),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: family,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cream,
      labelStyle: const TextStyle(color: AppColors.chocolate, fontFamily: family),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.seed),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.seed),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.boba, width: 1.5),
      ),
    ),
  );
}
