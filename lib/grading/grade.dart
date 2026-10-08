import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Logger letters only (no +/−). Maps to `drink_entries.grade` 5..1.
enum LetterGrade {
  s(5, 'S'),
  a(4, 'A'),
  b(3, 'B'),
  c(2, 'C'),
  d(1, 'D');

  const LetterGrade(this.points, this.letter);
  final int points;
  final String letter;

  static LetterGrade? fromPoints(int grade) => switch (grade) {
        5 => LetterGrade.s,
        4 => LetterGrade.a,
        3 => LetterGrade.b,
        2 => LetterGrade.c,
        1 => LetterGrade.d,
        _ => null,
      };

  static LetterGrade? fromOverall(String? overall) {
    if (overall == null) return null;
    return switch (overall.toUpperCase()) {
      'S' => LetterGrade.s,
      'A' => LetterGrade.a,
      'B' => LetterGrade.b,
      'C' => LetterGrade.c,
      'D' => LetterGrade.d,
      _ => null,
    };
  }
}

/// Aggregate display including +/−. No S+ / S−.
enum AggregateBand {
  s('S'),
  aPlus('A+'),
  a('A'),
  aMinus('A−'),
  bPlus('B+'),
  b('B'),
  bMinus('B−'),
  cPlus('C+'),
  c('C'),
  cMinus('C−'),
  dPlus('D+'),
  d('D'),
  dMinus('D−');

  const AggregateBand(this.label);
  final String label;
}

/// Lower bound inclusive, upper exclusive, except S includes 5.0.
AggregateBand? bandForAverage(double? avg) {
  if (avg == null) return null;
  if (avg >= 4.7) return AggregateBand.s;
  if (avg >= 4.3) return AggregateBand.aPlus;
  if (avg >= 4.0) return AggregateBand.a;
  if (avg >= 3.7) return AggregateBand.aMinus;
  if (avg >= 3.3) return AggregateBand.bPlus;
  if (avg >= 3.0) return AggregateBand.b;
  if (avg >= 2.7) return AggregateBand.bMinus;
  if (avg >= 2.3) return AggregateBand.cPlus;
  if (avg >= 2.0) return AggregateBand.c;
  if (avg >= 1.7) return AggregateBand.cMinus;
  if (avg >= 1.3) return AggregateBand.dPlus;
  if (avg >= 1.0) return AggregateBand.d;
  if (avg >= 0.0) return AggregateBand.dMinus;
  return null;
}

(Color fill, Color onFill) colorsForMark(String mark) {
  final letter = mark.isEmpty ? '' : mark[0].toUpperCase();
  final plus = mark.endsWith('+') || mark.endsWith('＋');
  final minus = mark.endsWith('−') || mark.endsWith('-');
  return switch (letter) {
    'S' => (AppColors.gradeS, AppColors.gradeSOn),
    'A' => plus
        ? (AppColors.gradeAPlus, Colors.white)
        : minus
            ? (AppColors.gradeAMinus, Colors.white)
            : (AppColors.gradeA, Colors.white),
    'B' => plus
        ? (AppColors.gradeBPlus, Colors.white)
        : minus
            ? (AppColors.gradeBMinus, Colors.white)
            : (AppColors.gradeB, Colors.white),
    'C' => plus
        ? (AppColors.gradeCPlus, AppColors.gradeSOn)
        : minus
            ? (AppColors.gradeCMinus, Colors.white)
            : (AppColors.gradeC, Colors.white),
    'D' => plus
        ? (AppColors.gradeDPlus, Colors.white)
        : minus
            ? (AppColors.gradeDMinus, Colors.white)
            : (AppColors.gradeD, Colors.white),
    _ => (AppColors.seed, AppColors.boba),
  };
}
