import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/data/tea_repository.dart';
import 'package:tea_ranker/data/tea_types.dart';
import 'package:tea_ranker/grading/grade.dart';
import 'package:tea_ranker/screens/friend_taste_screen.dart';
import 'package:tea_ranker/screens/shop_detail_screen.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/theme/topping_colors.dart';
import 'package:tea_ranker/widgets/base_toggles.dart';
import 'package:tea_ranker/widgets/milk_fruit_icons.dart';
import 'package:tea_ranker/widgets/new_catalog_dialogs.dart';
import 'package:tea_ranker/widgets/tea_type_chip.dart';
import 'package:tea_ranker/widgets/topping_chip.dart';

DrinkEntryRow typedDrink({String? note}) {
  const type = TeaTypeRow(
    id: 'tt-black',
    name: 'Black',
    userId: 'u1',
    isPrimary: true,
    isUserAdded: false,
  );
  return DrinkEntryRow(
    id: 'd1',
    userId: 'u1',
    shopId: 's1',
    teaName: 'Assam milk tea',
    drinkType: 'Milk-based',
    sugarLevel: 30,
    iceLevel: 50,
    price: 65,
    grade: 4,
    overallGrade: 'A',
    notes: null,
    loggedAt: DateTime(2026, 4, 8, 12),
    teaTypeId: type.id,
    teaTypeNote: note,
    teaType: type,
    shop: const ShopRow(
      id: 's1',
      name: '50 Lan',
      nameZh: '五十嵐',
      userId: 'u1',
      isUserAdded: false,
    ),
  );
}

void main() {
  group('drinkTypeFromToggles', () {
    test('milk wins even when fruit is also on', () {
      expect(drinkTypeFromToggles(milk: true, fruit: true), kDrinkTypeMilk);
      expect(drinkTypeFromToggles(milk: true, fruit: false), kDrinkTypeMilk);
    });

    test('fruit only is Fruit-based; neither is Tea-based', () {
      expect(drinkTypeFromToggles(milk: false, fruit: true), kDrinkTypeFruit);
      expect(drinkTypeFromToggles(milk: false, fruit: false), kDrinkTypeTea);
    });

    test('togglesFromDrinkType ignores Other', () {
      expect(togglesFromDrinkType('Other'), (milk: false, fruit: false));
      expect(togglesFromDrinkType(kDrinkTypeMilk).milk, isTrue);
      expect(togglesFromDrinkType(kDrinkTypeFruit).fruit, isTrue);
    });
  });

  group('teaTypeCardLine', () {
    test('type only, type plus note, and empty', () {
      expect(teaTypeCardLine(typeName: 'Black'), 'Black');
      expect(
        teaTypeCardLine(typeName: 'Black', note: 'Assam'),
        'Black - Assam',
      );
      expect(teaTypeCardLine(typeName: 'Black', note: '  '), 'Black');
      expect(teaTypeCardLine(typeName: null, note: 'Assam'), isNull);
      expect(typedDrink(note: 'Assam').teaTypeLine, 'Black - Assam');
      expect(typedDrink().teaTypeLine, 'Black');
    });
  });

  group('tea type catalog', () {
    test(
      'empty catalog gets nine seeds; existing seven get Jasmine + Tieguanyin',
      () {
        expect(teaTypesToSeedForUser(const []), newUserTeaTypeSeeds);
        expect(newUserTeaTypeSeeds, hasLength(9));
        expect(kPuerName, 'Pu’er');
        expect(kPuerName.codeUnitAt(2), 0x2019);
        expect(newUserTeaTypeSeeds.map((s) => s.name).toList(), [
          'Black',
          'Green',
          'Oolong',
          'Matcha',
          'Hojicha',
          kPuerName,
          'White',
          'Jasmine',
          'Tieguanyin',
        ]);
        expect(
          newUserTeaTypeSeeds.where((s) => s.isPrimary).map((s) => s.name),
          ['Black', 'Green', 'Oolong'],
        );
        final seven = [
          'Black',
          'Green',
          'Oolong',
          'Matcha',
          'Hojicha',
          kPuerName,
          'White',
        ];
        expect(teaTypesToSeedForUser(seven).map((s) => s.name), [
          'Jasmine',
          'Tieguanyin',
        ]);
        expect(
          teaTypesToSeedForUser([
            ...seven,
            'Jasmine',
            'Yellow',
          ]).map((s) => s.name),
          ['Tieguanyin'],
        );
        expect(
          teaTypesToSeedForUser([...seven, 'Jasmine', 'Tieguanyin']),
          isEmpty,
        );
      },
    );

    test('Matcha is secondary, not under Green; extras follow seeds', () {
      final catalog = [
        for (final s in newUserTeaTypeSeeds)
          TeaTypeRow(
            id: s.name,
            name: s.name,
            userId: 'u',
            isPrimary: s.isPrimary,
            isUserAdded: false,
          ),
        const TeaTypeRow(
          id: 'extra',
          name: 'Yellow',
          userId: 'u',
          isPrimary: false,
          isUserAdded: true,
        ),
      ];
      expect(primaryTeaTypes(catalog).map((t) => t.name), kPrimaryTeaTypeNames);
      expect(secondaryTeaTypes(catalog).map((t) => t.name), [
        ...kSecondarySeedTeaTypeNames,
        'Yellow',
      ]);
    });
  });

  test('write payload nulls note without a type; keeps note with a type', () {
    final none = drinkEntryWritePayload(
      shopId: 's',
      teaName: 'Oolong',
      drinkType: kDrinkTypeTea,
      price: 50,
      grade: LetterGrade.a,
      notes: null,
      localDay: DateTime(2026, 10, 26),
      teaTypeId: null,
      teaTypeNote: 'should drop',
    );
    expect(none['tea_type_id'], isNull);
    expect(none['tea_type_note'], isNull);
    expect(none['drink_type'], kDrinkTypeTea);

    final withType = drinkEntryWritePayload(
      shopId: 's',
      teaName: 'Milk tea',
      drinkType: kDrinkTypeMilk,
      price: 65,
      grade: LetterGrade.a,
      notes: null,
      localDay: DateTime(2026, 10, 26),
      teaTypeId: 'tt-black',
      teaTypeNote: '  Assam  ',
    );
    expect(withType['tea_type_id'], 'tt-black');
    expect(withType['tea_type_note'], 'Assam');
  });

  testWidgets('visit cards show {Type} or {Type} - {note}', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrinkVisitCard(
            drink: typedDrink(note: 'Assam'),
            onEdit: () {},
            onDelete: () async {},
          ),
        ),
      ),
    );
    expect(find.text('Assam milk tea'), findsOneWidget);
    expect(find.text('Black - Assam'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FriendDrinkCard(drink: typedDrink())),
      ),
    );
    expect(find.text('Black'), findsOneWidget);
    expect(find.text('Black - Assam'), findsNothing);
  });

  testWidgets('Milk and Fruit toggles are half-width and independent', (
    tester,
  ) async {
    var milk = false;
    var fruit = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return BaseToggles(
                milk: milk,
                fruit: fruit,
                onMilk: (v) => setState(() => milk = v),
                onFruit: (v) => setState(() => fruit = v),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Fruit'), findsOneWidget);
    expect(find.text('Milk-based'), findsNothing);
    expect(find.text('Other'), findsNothing);

    final milkBox = tester.getRect(
      find.ancestor(of: find.text('Milk'), matching: find.byType(InkWell)),
    );
    final fruitBox = tester.getRect(
      find.ancestor(of: find.text('Fruit'), matching: find.byType(InkWell)),
    );
    expect(milkBox.right, lessThan(fruitBox.left));
    expect((milkBox.width - fruitBox.width).abs(), lessThan(2));

    await tester.tap(find.text('Milk'));
    await tester.pump();
    await tester.tap(find.text('Fruit'));
    await tester.pump();
    expect(milk, isTrue);
    expect(fruit, isTrue);
    expect(drinkTypeFromToggles(milk: milk, fruit: fruit), kDrinkTypeMilk);
  });

  test('named tea type fills; extras pick a palette color', () {
    expect(namedColorHexForTeaType('Black'), kTeaTypeBlackHex);
    expect(namedColorHexForTeaType('Green'), kTeaTypeGreenHex);
    expect(namedColorHexForTeaType('Oolong'), kTeaTypeOolongHex);
    expect(namedColorHexForTeaType('Matcha'), kTeaTypeMatchaHex);
    expect(namedColorHexForTeaType('Hojicha'), kTeaTypeHojichaHex);
    expect(namedColorHexForTeaType(kPuerName), kTeaTypePuerHex);
    expect(namedColorHexForTeaType("Pu'er"), kTeaTypePuerHex);
    expect(namedColorHexForTeaType('White'), kTeaTypeWhiteHex);
    expect(namedColorHexForTeaType('Jasmine'), kTeaTypeJasmineHex);
    expect(namedColorHexForTeaType('Tieguanyin'), kTeaTypeTieguanyinHex);
    expect(
      colorHexForNewTeaType('Yellow', existingHexes: const []),
      kTeaTypeExtraDefaultHex,
    );
    expect(kTeaTypeExtraDefaultHex, kToppingFallbackHex);
    const stored = TeaTypeRow(
      id: '1',
      name: 'Matcha',
      userId: 'u',
      isPrimary: false,
      isUserAdded: false,
      colorHex: '#123456',
    );
    expect(effectiveTeaTypeColorHex(stored), '#123456');
    const uncolored = TeaTypeRow(
      id: '2',
      name: 'Matcha',
      userId: 'u',
      isPrimary: false,
      isUserAdded: false,
    );
    expect(effectiveTeaTypeColorHex(uncolored), kTeaTypeMatchaHex);
  });

  test('row 1 tiles use grade-wash pastel, not full-blast hex', () {
    expect(kTeaTypePrimaryIntensity, (kGradeWashMix * 100).round());
    const black = TeaTypeRow(
      id: 'b',
      name: 'Black',
      userId: 'u',
      isPrimary: true,
      isUserAdded: false,
      colorHex: kTeaTypeBlackHex,
      colorIntensity: 100,
    );
    final pastel = teaTypeTileFill(black);
    final blasted = toppingFill(colorHex: kTeaTypeBlackHex, intensity: 100);
    final expected = toppingFill(
      colorHex: kTeaTypeBlackHex,
      intensity: kTeaTypePrimaryIntensity,
    );
    expect(pastel, expected);
    expect(pastel, isNot(blasted));
    expect(pastel, Color.lerp(AppColors.cream, blasted, kGradeWashMix));
  });

  testWidgets(
    'row 1 is three half-style leaf tiles; row 2 scrolls without icons',
    (tester) async {
      final catalog = [
        for (final s in newUserTeaTypeSeeds)
          TeaTypeRow(
            id: s.name,
            name: s.name,
            userId: 'u',
            isPrimary: s.isPrimary,
            isUserAdded: false,
            colorHex: s.colorHex,
          ),
        const TeaTypeRow(
          id: 'Yellow',
          name: 'Yellow',
          userId: 'u',
          isPrimary: false,
          isUserAdded: true,
          colorHex: '#FFF59D',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TeaTypePrimaryRow(
                  types: primaryTeaTypes(catalog),
                  selectedId: 'Black',
                  onToggle: (_) {},
                ),
                TeaTypeSecondaryScroller(
                  types: secondaryTeaTypes(catalog),
                  selectedId: null,
                  onToggle: (_) {},
                  onAddNew: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Black'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Oolong'), findsOneWidget);
      expect(find.byType(TwoTeaLeavesIcon), findsNWidgets(3));

      final blackBox = tester.getRect(
        find.ancestor(of: find.text('Black'), matching: find.byType(InkWell)),
      );
      final oolongBox = tester.getRect(
        find.ancestor(of: find.text('Oolong'), matching: find.byType(InkWell)),
      );
      expect(blackBox.right, lessThan(oolongBox.left));
      expect((blackBox.width - oolongBox.width).abs(), lessThan(2));

      expect(find.text('Matcha'), findsOneWidget);
      expect(find.text('Jasmine'), findsOneWidget);
      expect(find.text('Tieguanyin'), findsOneWidget);
      expect(find.text('Yellow'), findsOneWidget);
      expect(find.text('Add new +'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
      expect(find.byType(ToppingChip), findsNWidgets(8));
      expect(
        tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .scrollDirection,
        Axis.horizontal,
      );

      final matchaFill = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.widgetWithText(ToppingChip, 'Matcha'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final matchaDeco = matchaFill.decoration! as ShapeDecoration;
      expect(matchaDeco.color, colorFromHex(kTeaTypeMatchaHex));

      final addFill = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.widgetWithText(ToppingChip, 'Add new +'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final addDeco = addFill.decoration! as ShapeDecoration;
      expect(addDeco.color, colorFromHex('#FFFFFF'));
    },
  );

  testWidgets('variety note stays visible before a type is picked', (
    tester,
  ) async {
    final note = TextEditingController();
    addTearDown(note.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TeaTypeNoteField(controller: note)),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, kTeaTypeNoteHint);
    expect(field.decoration?.labelText, kTeaTypeNoteLabel);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  testWidgets('New Tea Type dialog Add / Cancel; Add returns the name', (
    tester,
  ) async {
    String? added;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  added = await showNewTeaTypeDialog(context: context);
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(kNewTeaTypeTitle), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Yellow  ');
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(added, 'Yellow');
  });
}
