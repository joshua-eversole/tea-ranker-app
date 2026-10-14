import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/grading/grade.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/widgets/app_shell.dart';
import 'package:tea_ranker/widgets/shop_name_field.dart';

ShopRow shop(String id, String name) => ShopRow(
      id: id,
      name: name,
      userId: 'u',
      isUserAdded: true,
    );

void main() {
  test('formatTwd uses NT\$ prefix', () {
    expect(formatTwd(65), 'NT\$ 65');
    expect(formatTwd(65.5), 'NT\$ 65.50');
  });

  test('shop suggestions prefer prefix matches and skip exact text', () {
    final shops = [
      shop('1', '50 Lan'),
      shop('2', 'Lan Shan'),
      shop('3', 'Chun Shui Tang'),
    ];
    final found = matchingShops(shops, 'lan');
    expect(found.map((s) => s.name), ['Lan Shan', '50 Lan']);
    expect(matchingShops(shops, '50 Lan'), isEmpty);
  });

  test('nav pills idle on logger and shop details, selected on Home', () {
    expect(shellTabIndex('/'), 0);
    expect(shellTabIndex('/map'), 1);
    expect(shellTabIndex('/social'), 2);
    expect(shellTabIndex('/profile'), 3);
    expect(shellTabIndex('/log'), -1);
    expect(shellTabIndex('/shops/abc'), -1);
  });

  test('grade wash mixes locked fills toward cream, including +/−', () {
    expect(
      gradeWash('A'),
      Color.lerp(AppColors.cream, AppColors.gradeA, kGradeWashMix),
    );
    expect(
      gradeWash('A+'),
      Color.lerp(AppColors.cream, AppColors.gradeAPlus, kGradeWashMix),
    );
    expect(
      gradeWash('A−'),
      Color.lerp(AppColors.cream, AppColors.gradeAMinus, kGradeWashMix),
    );
    expect(
      gradeWash('S'),
      Color.lerp(AppColors.cream, AppColors.gradeS, kGradeWashMix),
    );
    expect(
      gradeWash(null),
      Color.lerp(AppColors.cream, AppColors.seed, kGradeWashMix),
    );
  });
}
