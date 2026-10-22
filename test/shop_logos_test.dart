import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/data/shop_brands.dart';
import 'package:tea_ranker/grading/grade.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/theme/topping_colors.dart';
import 'package:tea_ranker/widgets/boba_cup_icon.dart';
import 'package:tea_ranker/widgets/shop_logo_circle.dart';

ShopRow shop({String? name, String? nameZh}) => ShopRow(
  id: 's',
  name: name,
  nameZh: nameZh,
  userId: 'u',
  isUserAdded: false,
);

ShopBrand brand({
  String? name,
  String? nameZh,
  String? logoPath,
  String? selectedHex,
}) => ShopBrand(
  id: 'b',
  name: name,
  nameZh: nameZh,
  logoPath: logoPath,
  selectedHex: selectedHex,
);

void main() {
  test('matches shops the same way as the logger', () {
    final fifty = shop(name: '50 Lan', nameZh: '五十嵐');
    expect(
      shopMatchesBrand(fifty, brand(name: '50 Lan', nameZh: '五十嵐')),
      isTrue,
    );
    expect(shopMatchesBrand(fifty, brand(name: '50 lan')), isTrue);
    expect(shopMatchesBrand(fifty, brand(nameZh: '五十嵐')), isTrue);
    expect(
      shopMatchesBrand(
        shop(nameZh: '五十嵐'),
        brand(name: '50 Lan', nameZh: '五十嵐'),
      ),
      isTrue,
    );
    expect(shopMatchesBrand(fifty, brand(name: 'Kebuke')), isFalse);
  });

  test(
    'tint defaults off; logo wash mixes toward cream and stays readable',
    () {
      expect(
        const ProfileRow(id: 'u', username: 'j').tintHomeWithLogos,
        isFalse,
      );
      expect(
        ProfileRow.fromMap({'id': 'u', 'username': 'j'}).tintHomeWithLogos,
        isFalse,
      );
      final hue = colorFromHex('#1A1A1A');
      final unlifted = Color.lerp(AppColors.cream, hue, kGradeWashMix)!;
      final wash = logoPageWash('#1A1A1A');
      expect(
        contrastRatio(wash, AppColors.chocolate),
        greaterThanOrEqualTo(contrastRatio(unlifted, AppColors.chocolate)),
      );
      expect(
        contrastRatio(wash, AppColors.chocolate),
        closeTo(contrastRatio(AppColors.cream, AppColors.chocolate), 0.05),
      );
      final off = homeRowWash(
        tintHomeWithLogos: false,
        brand: brand(logoPath: 'x', selectedHex: '#E6B422'),
        gradeMark: 'A',
      );
      expect(off, gradeWash('A'));
      final on = homeRowWash(
        tintHomeWithLogos: true,
        brand: brand(logoPath: 'x', selectedHex: '#E6B422'),
        gradeMark: 'A',
      );
      expect(on, logoPageWash('#E6B422'));
      final noLogo = homeRowWash(
        tintHomeWithLogos: true,
        brand: brand(selectedHex: '#E6B422'),
        gradeMark: 'A',
      );
      expect(noLogo, gradeWash('A'));
    },
  );

  test('shop details page wash uses logo color; visits stay grade', () {
    final band = bandForAverage(4.5);
    final withLogo = shopDetailsPageWash(
      brand: brand(logoPath: 'p', selectedHex: '#1565C0'),
      band: band,
    );
    expect(withLogo, logoPageWash('#1565C0'));
    expect(shopDetailsPageWash(brand: null, band: band), shopPageWash(band));
  });

  test('locked copy', () {
    expect(kTintHomeWithLogosLabel, 'Tint Home rows with shop logos');
    expect(kPickMainColorTitle, 'Pick the main color');
    expect(kAddOrReplaceLogoTooltip, 'Add or replace logo');
  });

  test('home circle is larger than the row and leaves room for the name', () {
    expect(kHomeLogoCircleSize, 96);
    expect(kHomeLogoCircleSize, greaterThan(80));
    expect(kHomeLogoTextInset, kHomeLogoCircleSize + kHomeLogoCircleGap);
  });

  test('home circle fill is a step darker than the row wash, not the disc', () {
    const mark = 'A';
    final fill = homeLogoCircleFill(mark);
    expect(fill, isNot(gradeWash(mark)));
    expect(fill, isNot(colorsForMark(mark).$1));
    expect(kHomeLogoCircleWashMix, greaterThan(kGradeWashMix));
    expect(kHomeLogoCircleWashMix, lessThan(0.6));
    expect(
      fill,
      Color.lerp(
        AppColors.cream,
        colorsForMark(mark).$1,
        kHomeLogoCircleWashMix,
      ),
    );
  });

  testWidgets('home circle without logo is deeper wash plus boba icon', (
    tester,
  ) async {
    final band = bandForAverage(5);
    final wash = gradeWash(band!.label);
    final fill = homeLogoCircleFill(band.label);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Scaffold(
          backgroundColor: AppColors.cream,
          body: ShopLogoCircle(
            size: kHomeLogoCircleSize,
            band: band,
            showBobaIcon: true,
            fill: fill,
            iconColor: wash,
          ),
        ),
      ),
    );
    expect(find.text('S'), findsNothing);
    expect(find.byType(ShopLogoCircle), findsOneWidget);
    expect(find.byType(BobaCupIcon), findsOneWidget);
    final box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(ShopLogoCircle),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(box.color, fill);
    expect(box.color, isNot(colorsForMark(band.label).$1));
    expect(box.color, isNot(wash));
  });

  testWidgets('logo cover-crop does not draw the boba icon on the photo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Scaffold(
          body: ShopLogoCircle(
            size: kHomeLogoCircleSize,
            band: bandForAverage(5),
            showBobaIcon: true,
            logoUrl: 'https://example.com/logo.png',
          ),
        ),
      ),
    );
    expect(find.byType(BobaCupIcon), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('shop-details header without logo still shows the letter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Scaffold(
          body: ShopLogoCircle(
            size: AppLayout.shopHeaderGradeSize,
            band: bandForAverage(5),
            showGradeMark: true,
          ),
        ),
      ),
    );
    expect(find.text('S'), findsOneWidget);
    expect(find.byType(BobaCupIcon), findsNothing);
  });
}
