import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/data/shop_brands.dart';
import 'package:tea_ranker/grading/grade.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/theme/topping_colors.dart';
import 'package:tea_ranker/widgets/boba_cup_icon.dart';
import 'package:tea_ranker/widgets/logo_color_picker.dart';
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
  List<String> paletteHex = const [],
  bool tintHome = true,
}) => ShopBrand(
  id: 'b',
  name: name,
  nameZh: nameZh,
  logoPath: logoPath,
  selectedHex: selectedHex,
  paletteHex: paletteHex,
  tintHome: tintHome,
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
    expect(
      shopMatchesBrand(
        shop(name: 'CHAGE', nameZh: '茶聚'),
        brand(name: 'CHAGE / 茶聚'),
      ),
      isTrue,
    );
  });

  test(
    'tint defaults on per brand; logo wash keeps the chosen hue visible',
    () {
      expect(brand().tintHome, isTrue);
      expect(ShopBrand.fromMap({'id': 'b', 'name': 'x'}).tintHome, isTrue);
      ProfileRow.fromMap({'id': 'u', 'username': 'j'});
      final blue = logoPageWash('#1565C0');
      expect(blue, isNot(AppColors.cream));
      expect(blue, isNot(shopPageWash(bandForAverage(3))));
      expect(kLogoWashMix, greaterThan(kGradeWashMix));
      expect(
        blue,
        isNot(
          Color.lerp(AppColors.cream, colorFromHex('#1565C0'), kGradeWashMix),
        ),
      );
      final off = homeRowWash(
        brand: brand(logoPath: 'x', selectedHex: '#E6B422', tintHome: false),
        gradeMark: 'A',
      );
      expect(off, gradeWash('A'));
      final on = homeRowWash(
        brand: brand(logoPath: 'x', selectedHex: '#E6B422'),
        gradeMark: 'A',
      );
      expect(on, logoPageWash('#E6B422'));
      final noLogo = homeRowWash(
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
    expect(withLogo, isNot(shopPageWash(band)));
    expect(shopDetailsPageWash(brand: null, band: band), shopPageWash(band));
  });

  test('brand map reads selected_hex, palette fallback, and logo_url', () {
    final fromPalette = ShopBrand.fromMap({
      'id': 'b1',
      'name': 'TrueDan',
      'palette_hex': ['#1565C0', '#EEEEEE'],
    });
    expect(fromPalette.effectiveSelectedHex, '#1565C0');
    expect(fromPalette.tintHome, isTrue);
    final fromUrl = ShopBrand.fromMap({
      'id': 'b2',
      'name_zh': '五十嵐',
      'logo_url': 'https://cdn.example/logo.png',
      'color_hex': '#E6B422',
    });
    expect(fromUrl.hasLogo, isTrue);
    expect(fromUrl.selectedHex, '#E6B422');
    expect(
      resolveLogoUrl(fromUrl.logoPath, publicUrlFor: (p) => 'storage://$p'),
      'https://cdn.example/logo.png',
    );
    expect(
      resolveLogoUrl('shop-logos/abc/logo.jpg', publicUrlFor: (p) => 'pub/$p'),
      'pub/abc/logo.jpg',
    );
    expect(
      resolveLogoUrl('abc/logo.jpg', publicUrlFor: (p) => 'pub/$p'),
      'pub/abc/logo.jpg',
    );
  });

  test('locked copy', () {
    expect(kTintHomeRowLabel, 'Tint Home row');
    expect(kPickMainColorTitle, 'Pick the main color');
    expect(kAddOrReplaceLogoTooltip, 'Add or replace logo');
    expect(kCustomColorLabel, 'Custom');
    expect(kCustomRgbLabel, 'Custom RGB');
  });

  test('null selected_hex still washes from palette', () {
    final band = bandForAverage(4.5);
    final wash = shopDetailsPageWash(
      brand: brand(
        logoPath: 'p',
        selectedHex: null,
        paletteHex: const ['#1565C0', '#EEEEEE'],
      ),
      band: band,
    );
    expect(wash, logoPageWash('#1565C0'));
    expect(wash, isNot(shopPageWash(band)));
  });

  test('home circle is 96, overhangs, shifted left, names inset', () {
    expect(kHomeLogoCircleSize, 96);
    expect(kHomeLogoCircleLeftShift, 10);
    expect(
      kHomeLogoTextInset,
      kHomeLogoCircleSize - kHomeLogoCircleLeftShift + kHomeLogoCircleGap,
    );
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

  testWidgets('home circle stays 96x96 inside a short row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Scaffold(
          backgroundColor: AppColors.cream,
          body: Center(
            child: SizedBox(
              width: 320,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  OverflowBox(
                    minWidth: kHomeLogoCircleSize,
                    maxWidth: kHomeLogoCircleSize,
                    minHeight: kHomeLogoCircleSize,
                    maxHeight: kHomeLogoCircleSize,
                    child: ShopLogoCircle(
                      size: kHomeLogoCircleSize,
                      band: bandForAverage(5),
                      showBobaIcon: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final disc = tester.getSize(find.byKey(const ValueKey('shopLogoDisc')));
    expect(disc.width, kHomeLogoCircleSize);
    expect(disc.height, kHomeLogoCircleSize);
    expect(disc.width, disc.height);
    expect(find.byType(BobaCupIcon), findsOneWidget);
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
    expect(
      find.descendant(
        of: find.byType(ShopLogoCircle),
        matching: find.byType(OverflowBox),
      ),
      findsNothing,
    );
  });

  testWidgets('shop-details header circle lays out in an unbounded Row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    const Expanded(child: Text('50 Lan / 五十嵐')),
                    ShopLogoCircle(
                      size: AppLayout.shopHeaderGradeSize,
                      band: bandForAverage(5),
                      brand: brand(logoPath: 'p', selectedHex: null),
                      showGradeMark: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const Text('2 visits'),
              const Expanded(child: Text('Visits')),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('50 Lan / 五十嵐'), findsOneWidget);
    expect(find.text('2 visits'), findsOneWidget);
    expect(find.text('Visits'), findsOneWidget);
    expect(find.byTooltip(kAddOrReplaceLogoTooltip), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
  });

  testWidgets('logo sheet has add/replace, color title, and tint default on', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showShopLogoSheet(context: context),
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text(kPickMainColorTitle), findsOneWidget);
    expect(find.text(kAddOrReplaceLogoTooltip), findsOneWidget);
    expect(find.text(kTintHomeRowLabel), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
  });

  testWidgets('logo sheet tint switch can start off for a brand', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showShopLogoSheet(
                  context: context,
                  brand: brand(tintHome: false),
                ),
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets('logo sheet recolors from stored palette without a new image', (
    tester,
  ) async {
    ShopLogoSheetResult? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showShopLogoSheet(
                    context: context,
                    brand: brand(
                      logoPath: 'p',
                      selectedHex: '#1565C0',
                      paletteHex: const ['#1565C0', '#E6B422'],
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text(kPickMainColorTitle), findsOneWidget);
    expect(find.text(kCustomRgbLabel), findsOneWidget);
    expect(find.text('Hex'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.bytes, isNull);
    expect(result!.selectedHex, '#1565C0');
    expect(result!.paletteHex, ['#1565C0', '#E6B422']);
  });
}
