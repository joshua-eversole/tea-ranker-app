import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/data/tea_repository.dart';
import 'package:tea_ranker/grading/grade.dart';
import 'package:tea_ranker/screens/drink_logger_screen.dart';
import 'package:tea_ranker/screens/shop_detail_screen.dart';

DrinkEntryRow sampleDrink() => DrinkEntryRow(
      id: 'd1',
      userId: 'u1',
      shopId: 's1',
      teaName: 'Wintermelon Milk',
      drinkType: 'Milk-based',
      sugarLevel: 30,
      iceLevel: 50,
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
}
