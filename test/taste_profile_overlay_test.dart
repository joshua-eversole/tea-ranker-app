import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/data/taste_stats.dart';
import 'package:tea_ranker/grading/grade.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/widgets/taste_stats_card.dart';

ShopRow shop(String id, String name, {String? zh}) => ShopRow(
      id: id,
      name: name,
      nameZh: zh,
      userId: 'u1',
      isUserAdded: false,
    );

DrinkEntryRow drink({
  required String id,
  required String shopId,
  required DateTime loggedAt,
  String drinkType = 'Tea-based',
  int? sugar = 50,
  int? ice = 50,
  double price = 65,
  int grade = 4,
  List<ToppingRow> toppings = const [],
  ShopRow? shopRow,
}) {
  return DrinkEntryRow(
    id: id,
    userId: 'u1',
    shopId: shopId,
    teaName: 'Drink $id',
    drinkType: drinkType,
    sugarLevel: sugar,
    iceLevel: ice,
    price: price,
    grade: grade,
    overallGrade: LetterGrade.fromPoints(grade)?.letter,
    notes: null,
    loggedAt: loggedAt,
    shop: shopRow,
    toppings: toppings,
  );
}

ToppingRow topping(String id, String name) => ToppingRow(
      id: id,
      name: name,
      userId: 'u1',
      isUserAdded: true,
    );

void main() {
  final lan = shop('s-lan', '50 Lan', zh: '五十嵐');
  final macu = shop('s-macu', 'Macu', zh: '麻古茶坊');
  final kebuke = shop('s-kebuke', 'Kebuke', zh: '可不可熟成紅茶');
  final boba = topping('t-boba', 'Boba');
  final pudding = topping('t-pud', 'Pudding');

  test('empty log uses dashes and no fake favorites', () {
    final profile = buildTasteProfile(const [], const []);
    expect(profile.isEmpty, isTrue);
    expect(profile.averageSugarPercent, isNull);
    expect(profile.averageIcePercent, isNull);
    expect(profile.favoriteBase, isNull);
    expect(profile.highestRatedShop, isNull);
    expect(profile.mostVisitedShop, isNull);
    expect(profile.favoriteShopsByBase, isEmpty);
    expect(profile.averagePrice, isNull);
    expect(profile.favoriteTopping, isNull);
    expect(profile.daysSinceLastDrink, isNull);
    expect(formatAveragePercent(profile.averageIcePercent), '—');
    expect(formatAveragePrice(profile.averagePrice), '—');
    expect(formatDaysSinceLastDrink(profile.daysSinceLastDrink), '—');
  });

  test('taste averages skip Fixed (null) sugar and ice', () {
    final profile = buildTasteProfile(
      [
        drink(
          id: '1',
          shopId: lan.id,
          loggedAt: DateTime(2026, 10, 1),
          sugar: null,
          ice: 50,
        ),
        drink(
          id: '2',
          shopId: lan.id,
          loggedAt: DateTime(2026, 10, 2),
          sugar: 30,
          ice: null,
        ),
      ],
      [lan],
    );
    expect(profile.averageSugarPercent, 30);
    expect(profile.averageIcePercent, 50);
  });

  test('average ice rounds to the nearest 1%', () {
    final profile = buildTasteProfile(
      [
        drink(id: '1', shopId: lan.id, loggedAt: DateTime(2026, 10, 1), ice: 30),
        drink(id: '2', shopId: lan.id, loggedAt: DateTime(2026, 10, 2), ice: 50),
        drink(id: '3', shopId: lan.id, loggedAt: DateTime(2026, 10, 3), ice: 51),
      ],
      [lan],
    );
    // (30+50+51)/3 = 43.666… → 44
    expect(profile.averageIcePercent, 44);
  });

  test('most visited shop breaks ties with the most recent visit', () {
    final profile = buildTasteProfile(
      [
        drink(id: 'a1', shopId: lan.id, loggedAt: DateTime(2026, 10, 10, 12), shopRow: lan),
        drink(id: 'a2', shopId: lan.id, loggedAt: DateTime(2026, 10, 8, 12), shopRow: lan),
        drink(id: 'b1', shopId: macu.id, loggedAt: DateTime(2026, 10, 18, 12), shopRow: macu),
        drink(id: 'b2', shopId: macu.id, loggedAt: DateTime(2026, 10, 1, 12), shopRow: macu),
      ],
      [lan, macu],
    );
    expect(profile.mostVisitedShop?.shop.id, macu.id);
    expect(profile.mostVisitedShop?.visitCount, 2);
  });

  test('favorite shop per base uses that type’s avg grade and skips missing bases', () {
    final profile = buildTasteProfile(
      [
        drink(
          id: 'tea1',
          shopId: lan.id,
          drinkType: 'Tea-based',
          grade: 5,
          loggedAt: DateTime(2026, 10, 10),
          shopRow: lan,
        ),
        drink(
          id: 'tea2',
          shopId: kebuke.id,
          drinkType: 'Tea-based',
          grade: 3,
          loggedAt: DateTime(2026, 10, 11),
          shopRow: kebuke,
        ),
        drink(
          id: 'milk1',
          shopId: macu.id,
          drinkType: 'Milk-based',
          grade: 4,
          loggedAt: DateTime(2026, 10, 12),
          shopRow: macu,
        ),
        drink(
          id: 'other1',
          shopId: lan.id,
          drinkType: 'Other',
          grade: 5,
          loggedAt: DateTime(2026, 10, 13),
          shopRow: lan,
        ),
      ],
      [lan, macu, kebuke],
    );
    expect(
      profile.favoriteShopsByBase.map((e) => e.drinkType).toList(),
      ['Tea-based', 'Milk-based'],
    );
    expect(profile.favoriteShopsByBase.first.shop.id, lan.id);
    expect(profile.favoriteShopsByBase.first.band, AggregateBand.s);
    expect(profile.favoriteShopsByBase.last.shop.id, macu.id);
    expect(profile.favoriteShopsByBase.last.band, AggregateBand.a);
  });

  test('average price is TWD mean formatted NT\$', () {
    final profile = buildTasteProfile(
      [
        drink(id: '1', shopId: lan.id, price: 60, loggedAt: DateTime(2026, 10, 1)),
        drink(id: '2', shopId: lan.id, price: 70, loggedAt: DateTime(2026, 10, 2)),
      ],
      [lan],
    );
    expect(profile.averagePrice, 65);
    expect(formatAveragePrice(profile.averagePrice), 'NT\$ 65');
  });

  test('favorite topping breaks ties with the most recent drink', () {
    final profile = buildTasteProfile(
      [
        drink(
          id: 'new',
          shopId: lan.id,
          loggedAt: DateTime(2026, 10, 18),
          toppings: [pudding],
        ),
        drink(
          id: 'old1',
          shopId: lan.id,
          loggedAt: DateTime(2026, 10, 2),
          toppings: [boba],
        ),
        drink(
          id: 'old2',
          shopId: lan.id,
          loggedAt: DateTime(2026, 10, 1),
          toppings: [boba, pudding],
        ),
      ],
      [lan],
    );
    expect(profile.favoriteTopping, 'Pudding');
  });

  test('days since last drink is calendar days and 0 if today', () {
    final today = DateTime(2026, 10, 19, 22, 10);
    final sameDay = buildTasteProfile(
      [
        drink(
          id: '1',
          shopId: lan.id,
          loggedAt: DateTime(2026, 10, 19, 12),
        ),
      ],
      [lan],
      now: today,
    );
    expect(sameDay.daysSinceLastDrink, 0);
    expect(formatDaysSinceLastDrink(sameDay.daysSinceLastDrink), '0 days');

    final threeAgo = buildTasteProfile(
      [
        drink(
          id: '1',
          shopId: lan.id,
          loggedAt: DateTime(2026, 10, 16, 12),
        ),
      ],
      [lan],
      now: today,
    );
    expect(threeAgo.daysSinceLastDrink, 3);
  });

  testWidgets('More taste details opens a partial sheet; X and barrier close it',
      (tester) async {
    final profile = buildTasteProfile(
      [
        drink(
          id: '1',
          shopId: lan.id,
          ice: 40,
          price: 65,
          toppings: [boba],
          loggedAt: DateTime(2026, 10, 19, 12),
          shopRow: lan,
        ),
      ],
      [lan],
      now: DateTime(2026, 10, 19, 18),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Scaffold(
          body: TasteStatsCard(data: profile),
        ),
      ),
    );

    expect(find.text('Avg sugar'), findsOneWidget);
    expect(find.text(kMoreTasteDetailsLabel), findsOneWidget);
    expect(find.text(kTasteDetailsTitle), findsNothing);

    await tester.tap(find.text(kMoreTasteDetailsLabel));
    await tester.pumpAndSettle();

    expect(find.text(kTasteDetailsTitle), findsOneWidget);
    expect(find.text('Avg ice'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Most visited shop'), findsOneWidget);
    expect(find.text('Favorite Tea-based shop'), findsOneWidget);
    expect(find.text('Favorite Milk-based shop'), findsNothing);
    expect(find.text('Average price'), findsOneWidget);
    expect(find.text('NT\$ 65'), findsOneWidget);
    expect(find.text('Favorite topping'), findsOneWidget);
    expect(find.text('Boba'), findsOneWidget);
    expect(find.text('Days since last drink'), findsOneWidget);
    expect(find.text('0 days'), findsOneWidget);

    await tester.tap(find.byTooltip(kCloseTasteDetailsTooltip));
    await tester.pumpAndSettle();
    expect(find.text(kTasteDetailsTitle), findsNothing);

    await tester.tap(find.text(kMoreTasteDetailsLabel));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text(kTasteDetailsTitle), findsNothing);
  });

  testWidgets('empty log still opens the sheet with No drinks yet', (tester) async {
    final profile = buildTasteProfile(const [], const []);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Scaffold(body: TasteStatsCard(data: profile)),
      ),
    );
    await tester.tap(find.text(kMoreTasteDetailsLabel));
    await tester.pumpAndSettle();
    expect(find.text(kNoDrinksYetCopy), findsOneWidget);
    expect(find.text('—'), findsWidgets);
    expect(find.text('Avg ice'), findsOneWidget);
    expect(find.text('Favorite Tea-based shop'), findsNothing);
  });
}
