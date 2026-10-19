import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/theme/topping_colors.dart';
import 'package:tea_ranker/widgets/topping_chip.dart';
import 'package:tea_ranker/widgets/topping_color_picker.dart';

void main() {
  test('bright palette is ten light defaults', () {
    expect(toppingBrightPaletteHex, hasLength(10));
    expect(toppingBrightPaletteHex.toSet(), hasLength(10));
    for (final hex in toppingBrightPaletteHex) {
      final fill = colorFromHex(hex);
      expect(
        toppingFillNeedsWhiteLabel(fill),
        isFalse,
        reason: '$hex should keep brown/black text',
      );
    }
  });

  test('Joshua’s eleven and seed names have the locked fills', () {
    expect(namedColorHexForTopping('Almond Jelly'), '#F3E1C6');
    expect(namedColorHexForTopping('Grape Foam'), '#C5E1A5');
    expect(namedColorHexForTopping('Sesame Milk'), '#1A1A1A');
    expect(namedColorHexForTopping('Pineapple Chunks'), '#FFF59D');
    expect(namedColorHexForTopping('Agar Jelly'), '#E8F5E9');
    expect(namedColorHexForTopping('Ayou Jelly'), '#F0F4C3');
    expect(namedColorHexForTopping('Boba'), '#3E2723');
    expect(namedColorHexForTopping('Coffee'), '#A1887F');
    expect(namedColorHexForTopping('Honeycomb Coffee Mochi'), '#FFD54F');
    expect(namedColorHexForTopping('Pear Chunks'), '#E6EE9C');
    expect(namedColorHexForTopping('Tea Jelly'), '#E6C28A');
    expect(namedColorHexForTopping('Pudding'), '#FFE082');
    expect(namedColorHexForTopping('Grass Jelly'), '#1B3D2F');
    expect(namedColorHexForTopping('Aloe'), '#DCEDC8');
    expect(namedColorHexForTopping('Red Bean'), '#E8A598');
    expect(namedColorHexForTopping('Cheese Foam'), '#FFF3C4');
  });

  test('white label when contrast vs boba is under 4.5:1', () {
    expect(kToppingLabelContrastFloor, 4.5);
    expect(kToppingLabelDark, AppColors.boba);

    final sesame = colorFromHex('#1A1A1A');
    expect(contrastRatio(sesame, AppColors.boba) < 4.5, isTrue);
    expect(toppingFillNeedsWhiteLabel(sesame), isTrue);
    expect(toppingLabelColor(sesame), kToppingLabelLight);

    final boba = colorFromHex('#3E2723');
    expect(toppingFillNeedsWhiteLabel(boba), isTrue);

    final pineapple = colorFromHex('#FFF59D');
    expect(contrastRatio(pineapple, AppColors.boba) >= 4.5, isTrue);
    expect(toppingFillNeedsWhiteLabel(pineapple), isFalse);
    expect(toppingLabelColor(pineapple), kToppingLabelDark);
  });

  test('hex normalize accepts #RGB and #RRGGBB', () {
    expect(tryNormalizeColorHex('#c5e'), '#CC55EE');
    expect(tryNormalizeColorHex('c5e1a5'), '#C5E1A5');
    expect(tryNormalizeColorHex('nope'), isNull);
    expect(normalizeColorHex(null), kToppingFallbackHex);
  });

  test('new unnamed topping takes the next unused bright swatch', () {
    expect(
      colorHexForNewTopping('Lychee', existingHexes: const []),
      '#F3E1C6',
    );
    expect(
      colorHexForNewTopping(
        'Lychee',
        existingHexes: const ['#F3E1C6', '#FFF59D'],
      ),
      '#FFE082',
    );
    expect(
      colorHexForNewTopping('Boba', existingHexes: const ['#F3E1C6']),
      '#3E2723',
    );
  });

  testWidgets('chip fill and label follow the topping hex', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ToppingChip(label: 'Sesame Milk', colorHex: '#1A1A1A'),
              ToppingChip(label: 'Pineapple Chunks', colorHex: '#FFF59D'),
            ],
          ),
        ),
      ),
    );

    final sesame = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('Sesame Milk'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final pineapple = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('Pineapple Chunks'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((sesame.decoration as ShapeDecoration).color, const Color(0xFF1A1A1A));
    expect((pineapple.decoration as ShapeDecoration).color, const Color(0xFFFFF59D));
    expect(
      tester.widget<Text>(find.text('Sesame Milk')).style?.color,
      kToppingLabelLight,
    );
    expect(
      tester.widget<Text>(find.text('Pineapple Chunks')).style?.color,
      kToppingLabelDark,
    );
    expect(sesame.decoration, isA<ShapeDecoration>());
    expect(
      ((sesame.decoration as ShapeDecoration).shape as StadiumBorder),
      isA<StadiumBorder>(),
    );
  });

  testWidgets('color picker live-previews fill and auto label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ToppingColorPicker(
            toppingName: 'Custom Jelly',
            initialHex: '#FFF59D',
          ),
        ),
      ),
    );

    expect(find.text('Custom Jelly'), findsWidgets);
    expect(find.text('Brown label — contrast is at least 4.5:1'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Palette color #F8BBD0'));
    await tester.pumpAndSettle();
    expect(find.text('Brown label — contrast is at least 4.5:1'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Hex'), '#1A1A1A');
    await tester.pumpAndSettle();
    expect(
      find.text('White label — fill is too dark for brown text'),
      findsOneWidget,
    );
  });

  test('ToppingRow maps color_hex', () {
    final row = ToppingRow.fromMap({
      'id': 't1',
      'name': 'Boba',
      'user_id': 'u1',
      'is_user_added': true,
      'color_hex': '#3E2723',
    });
    expect(row.colorHex, '#3E2723');
    expect(row.copyWith(colorHex: '#C5E1A5').colorHex, '#C5E1A5');
  });
}
