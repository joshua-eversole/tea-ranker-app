import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/data/tea_repository.dart';
import 'package:tea_ranker/grading/grade.dart';
import 'package:tea_ranker/screens/drink_logger_screen.dart';
import 'package:tea_ranker/screens/shop_detail_screen.dart';

DrinkEntryRow sampleDrink({int? sugarLevel = 30, int? iceLevel = 50}) =>
    DrinkEntryRow(
      id: 'd1',
      userId: 'u1',
      shopId: 's1',
      teaName: 'Wintermelon Milk',
      drinkType: 'Milk-based',
      sugarLevel: sugarLevel,
      iceLevel: iceLevel,
      price: 65,
      grade: 4,
      overallGrade: 'A',
      notes: 'light',
      loggedAt: DateTime(2026, 4, 8, 12),
      shop: const ShopRow(
        id: 's1',
        name: '50 Lan',
        nameZh: '五十嵐',
        userId: 'u1',
        isUserAdded: false,
      ),
      toppings: const [
        ToppingRow(id: 't1', name: 'Boba', userId: 'u1', isUserAdded: true),
      ],
    );

void main() {
  test('logger title switches in edit mode', () {
    expect(drinkLoggerTitle(editing: false), 'Log a drink');
    expect(drinkLoggerTitle(editing: true), 'Edit drink');
  });

  test('write payload updates grade and overall_grade, not user_id', () {
    final payload = drinkEntryWritePayload(
      shopId: 'shop-1',
      teaName: '  Oolong  ',
      drinkType: 'Tea-based',
      sugarLevel: 30,
      iceLevel: 50,
      price: 65,
      grade: LetterGrade.a,
      notes: '  toasted  ',
      localDay: DateTime(2026, 3, 4, 23, 59),
    );
    expect(payload.containsKey('user_id'), isFalse);
    expect(payload['shop_id'], 'shop-1');
    expect(payload['tea_name'], 'Oolong');
    expect(payload['grade'], 4);
    expect(payload['overall_grade'], 'A');
    expect(payload['notes'], 'toasted');
    expect(
      payload['logged_at'],
      DateTime(2026, 3, 4, 12).toUtc().toIso8601String(),
    );
  });

  test('write payload stores null sugar/ice when Fixed', () {
    final payload = drinkEntryWritePayload(
      shopId: 'shop-1',
      teaName: 'Special',
      drinkType: 'Tea-based',
      sugarLevel: null,
      iceLevel: null,
      price: 70,
      grade: LetterGrade.s,
      notes: null,
      localDay: DateTime(2026, 10, 22),
    );
    expect(payload['sugar_level'], isNull);
    expect(payload['ice_level'], isNull);
  });

  test('fromMap keeps null sugar/ice, does not coerce to 0', () {
    final row = DrinkEntryRow.fromMap({
      'id': 'd',
      'user_id': 'u',
      'shop_id': 's',
      'tea_name': 'Special',
      'drink_type': 'Tea-based',
      'sugar_level': null,
      'ice_level': null,
      'price': 70,
      'grade': 5,
      'overall_grade': 'S',
      'notes': null,
      'logged_at': DateTime(2026, 10, 22, 12).toUtc().toIso8601String(),
    });
    expect(row.sugarLevel, isNull);
    expect(row.iceLevel, isNull);
  });

  test('Save still requires shop, drink, price, base, grade; Fixed skips %', () {
    expect(
      loggerCanSave(
        shop: '50 Lan',
        tea: 'Milk tea',
        priceText: '65',
        base: 'Milk-based',
        grade: LetterGrade.a,
        sugarFixed: true,
        iceFixed: true,
        sugar: 50,
        ice: 50,
        saving: false,
      ),
      isTrue,
    );
    expect(
      loggerCanSave(
        shop: '',
        tea: 'Milk tea',
        priceText: '65',
        base: 'Milk-based',
        grade: LetterGrade.a,
        sugarFixed: true,
        iceFixed: false,
        sugar: 30,
        ice: 50,
        saving: false,
      ),
      isFalse,
    );
    expect(kFixedLevelLabel, 'Fixed');
  });

  test('empty shop still pops Home after the last visit is gone', () {
    expect(
      shopDetailPhase(
        loading: false,
        loadError: null,
        hasProfile: true,
        hasDrinks: false,
      ),
      ShopDetailPhase.empty,
    );
  });

  testWidgets('visit card overflow offers Edit and Delete', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrinkVisitCard(
            drink: sampleDrink(),
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    expect(find.text('Wintermelon Milk'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit or delete this visit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('delete confirm copy; Cancel does nothing', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  final ok = await confirmDeleteVisit(context);
                  if (ok) deleted = true;
                },
                child: const Text('go'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text(kDeleteVisitConfirmMessage), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deleted, isFalse);
    expect(find.text(kDeleteVisitConfirmMessage), findsNothing);
  });

  testWidgets('delete confirm Delete returns true', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  final ok = await confirmDeleteVisit(context);
                  if (ok) deleted = true;
                },
                child: const Text('go'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('visit card omits Fixed sugar/ice instead of faking 0%', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrinkVisitCard(
            drink: sampleDrink(sugarLevel: null, iceLevel: 50),
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    expect(find.text('0%'), findsNothing);
    expect(find.text('30%'), findsNothing);
    expect(find.text('50%'), findsOneWidget);
  });
}
