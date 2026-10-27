import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/data/shop_brands.dart';
import 'package:tea_ranker/data/tea_repository.dart';
import 'package:tea_ranker/grading/grade.dart';
import 'package:tea_ranker/screens/drink_logger_screen.dart';
import 'package:tea_ranker/screens/shop_detail_screen.dart';
import 'package:tea_ranker/data/tea_types.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/widgets/drink_visit_overview.dart';
import 'package:tea_ranker/widgets/grade_circle.dart';
import 'package:tea_ranker/widgets/new_catalog_dialogs.dart';
import 'package:tea_ranker/widgets/topping_chip.dart';

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
    expect(payload['tea_type_id'], isNull);
    expect(payload['tea_type_note'], isNull);
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

  test('Save requires shop, drink, price, grade; base defaults Tea-based', () {
    expect(
      loggerCanSave(
        shop: '50 Lan',
        tea: 'Milk tea',
        priceText: '65',
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

  testWidgets('visit card has no overflow; tap opens overview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrinkVisitCard(
            drink: sampleDrink(),
            onEdit: () {},
            onDelete: () async {},
          ),
        ),
      ),
    );
    expect(find.text('Wintermelon Milk'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    await tester.tap(find.text('Wintermelon Milk'));
    await tester.pumpAndSettle();
    expect(find.byTooltip(kVisitEditTooltip), findsOneWidget);
    expect(find.byTooltip(kVisitDeleteTooltip), findsOneWidget);
    expect(find.text('light'), findsOneWidget);
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
            onDelete: () async {},
          ),
        ),
      ),
    );
    expect(find.text('0%'), findsNothing);
    expect(find.text('30%'), findsNothing);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('empty shop notes show the add hint; tap opens edit', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShopNotesBlock(notes: null, onTap: () => tapped = true),
        ),
      ),
    );
    expect(find.text(kAddShopNotesHint), findsOneWidget);
    await tester.tap(find.text(kAddShopNotesHint));
    expect(tapped, isTrue);
  });

  testWidgets('shop notes text is compact chocolate and tappable', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShopNotesBlock(
            notes: 'Ask for less ice',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text(kAddShopNotesHint), findsNothing);
    final text = tester.widget<Text>(find.text('Ask for less ice'));
    expect(text.style?.color, AppColors.chocolate);
    expect(text.style?.fontSize, 13);
    await tester.tap(find.text('Ask for less ice'));
    expect(tapped, isTrue);
  });

  testWidgets('long-press visit row edits; swipe left confirms delete', (
    tester,
  ) async {
    var edited = false;
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrinkVisitCard(
            drink: sampleDrink(),
            onEdit: () => edited = true,
            onDelete: () async => deleted = true,
          ),
        ),
      ),
    );
    await tester.longPress(find.text('Wintermelon Milk'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
    expect(find.byType(DrinkVisitOverview), findsNothing);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text(kDeleteVisitConfirmMessage), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deleted, isFalse);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('overview Edit and Delete icons', (tester) async {
    var edited = false;
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrinkVisitCard(
            drink: sampleDrink(),
            onEdit: () => edited = true,
            onDelete: () async => deleted = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Wintermelon Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(kVisitEditTooltip));
    await tester.pumpAndSettle();
    expect(edited, isTrue);

    await tester.tap(find.text('Wintermelon Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(kVisitDeleteTooltip));
    await tester.pumpAndSettle();
    expect(find.text(kDeleteVisitConfirmMessage), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('New Topping dialog includes palette and intensity', (
    tester,
  ) async {
    NewToppingDraft? draft;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  draft = await showNewToppingDialog(
                    context: context,
                    existingHexes: const [],
                  );
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
    expect(find.text(kNewToppingTitle), findsOneWidget);
    expect(find.text('Bright defaults'), findsOneWidget);
    expect(find.text('Intensity'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Lychee');
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(draft?.name, 'Lychee');
    expect(draft?.colorHex, isNotEmpty);
    expect(draft?.intensity, 100);
  });

  test('overview headline is bold drink @ shop; base is Milk/Fruit/Tea', () {
    expect(
      drinkOverviewHeadline(sampleDrink()),
      'Wintermelon Milk @ 50 Lan / 五十嵐',
    );
    expect(drinkTypeShortLabel('Milk-based'), 'Milk');
    expect(drinkTypeShortLabel('Fruit-based'), 'Fruit');
    expect(drinkTypeShortLabel('Tea-based'), 'Tea');
    expect(AppLayout.overviewGradeSize, AppLayout.historyGradeSize * 1.5);
  });

  testWidgets(
    'overview layout: date by grade, price, base, top-right actions',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrinkVisitOverview(
              drink: sampleDrink(),
              onEdit: () {},
              onDelete: () async {},
            ),
          ),
        ),
      );
      expect(find.textContaining('Wintermelon Milk'), findsOneWidget);
      expect(find.textContaining('@ 50 Lan / 五十嵐'), findsOneWidget);
      expect(find.text(formatTwd(65)), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Milk-based'), findsNothing);
      expect(find.text('Boba'), findsOneWidget);

      final grade = tester.widget<GradeCircle>(find.byType(GradeCircle));
      expect(grade.size, AppLayout.overviewGradeSize);

      final gradeBox = tester.getRect(find.byType(GradeCircle));
      final dateLabel = DateFormat.yMMMd().format(DateTime(2026, 4, 8, 12));
      final dateBox = tester.getRect(find.text(dateLabel));
      expect(dateBox.left, greaterThan(gradeBox.right));
      expect(dateBox.top, greaterThan(gradeBox.top));

      final sugarBox = tester.getRect(find.text('30%'));
      expect(sugarBox.top, greaterThan(dateBox.bottom - 4));

      final editBox = tester.getRect(find.byTooltip(kVisitEditTooltip));
      final deleteBox = tester.getRect(find.byTooltip(kVisitDeleteTooltip));
      expect(editBox.top, lessThan(gradeBox.top + 8));
      expect(deleteBox.left, greaterThan(editBox.left));
      expect(deleteBox.right, greaterThan(editBox.right - 1));
      expect(deleteBox.center.dy, closeTo(editBox.center.dy, 6));

      final topping = tester.widget<ToppingChip>(find.byType(ToppingChip));
      expect(topping.compact, isFalse);
    },
  );

  testWidgets('swipe delete red is clipped to the rounded card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrinkVisitCard(
            drink: sampleDrink(),
            onEdit: () {},
            onDelete: () async {},
          ),
        ),
      ),
    );
    final clip = tester.widget<ClipRRect>(
      find.ancestor(
        of: find.byType(Dismissible),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clip.borderRadius, BorderRadius.circular(AppRadii.card));
    expect(clip.clipBehavior, Clip.antiAlias);
    expect(find.byType(ColoredBox), findsWidgets);
  });
}
