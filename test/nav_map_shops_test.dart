import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/widgets/app_shell.dart';
import 'package:tea_ranker/widgets/phone_frame.dart';
import 'package:tea_ranker/widgets/shop_name_field.dart';
import 'package:tea_ranker/widgets/tea_nav_bar.dart';

ShopRow shop(String id, String name, {String? nameZh}) => ShopRow(
      id: id,
      name: name,
      nameZh: nameZh,
      userId: 'u',
      isUserAdded: true,
    );

void main() {
  group('shellTabIndex', () {
    test('Home Map Social Profile, idle on logger and shop details', () {
      expect(shellTabIndex('/'), 0);
      expect(shellTabIndex('/map'), 1);
      expect(shellTabIndex('/social'), 2);
      expect(shellTabIndex('/social/friends/abc'), 2);
      expect(shellTabIndex('/social/friends/abc/drinks/d1'), 2);
      expect(shellTabIndex('/profile'), 3);
      expect(shellTabIndex('/log'), -1);
      expect(shellTabIndex('/shops/abc'), -1);
    });
  });

  group('framedContentWidth', () {
    test('phones fill the viewport instead of sitting in a 430px well', () {
      expect(framedContentWidth(390), 390);
      expect(framedContentWidth(430), 430);
      expect(framedContentWidth(480), 480);
      expect(framedContentWidth(AppLayout.phoneFillBreakpoint), 700);
    });

    test('wide desktop is capped, not a stretched dashboard', () {
      expect(framedContentWidth(701), AppLayout.maxContentWidth);
      expect(framedContentWidth(1280), AppLayout.maxContentWidth);
      expect(AppLayout.maxContentWidth, 480);
    });
  });

  group('shopsToSeedForUser', () {
    test('true new user gets bilingual Taiwan chains', () {
      final seeds = shopsToSeedForUser(const []);
      expect(seeds, isNotEmpty);
      expect(seeds.map((s) => s.name), containsAll(['50 Lan', 'Kebuke', 'Milksha']));
      expect(
        seeds.firstWhere((s) => s.name == '50 Lan').nameZh,
        '五十嵐',
      );
      expect(
        seeds.firstWhere((s) => s.name == 'Chun Shui Tang').nameZh,
        '春水堂',
      );
    });

    test('existing catalogs including Joshua are not seeded or wiped', () {
      expect(shopsToSeedForUser(['50 Lan']), isEmpty);
      expect(shopsToSeedForUser(['My neighborhood shop']), isEmpty);
    });
  });

  group('matchingShops', () {
    test('matches Chinese names as well as English', () {
      final shops = [
        shop('1', '50 Lan', nameZh: '五十嵐'),
        shop('2', 'Lan Shan'),
        shop('3', 'Chun Shui Tang', nameZh: '春水堂'),
      ];
      expect(matchingShops(shops, 'lan').map((s) => s.name), ['Lan Shan', '50 Lan']);
      expect(matchingShops(shops, '五十').map((s) => s.name), ['50 Lan']);
      expect(matchingShops(shops, '春水堂'), isEmpty);
    });

    test('matches Chinese-only shops with a null English name', () {
      final zhOnly = ShopRow(
        id: 'z',
        name: null,
        nameZh: '一手私藏',
        userId: 'u',
        isUserAdded: true,
      );
      expect(matchingShops([zhOnly], '一手').map((s) => s.displayName), ['一手私藏']);
    });
  });

  group('shopLoggerSuggestions', () {
    final own = [
      shop('1', '50 Lan', nameZh: '五十嵐'),
      shop('2', 'Lan Shan'),
    ];
    final other = ShopRow(
      id: 'o1',
      name: 'Tea & Magic Hand',
      userId: 'other',
      isUserAdded: true,
    );

    test('empty query does not list other users shops', () {
      expect(
        shopLoggerSuggestions(
          ownShops: own,
          otherShops: [other],
          query: '',
        ),
        isEmpty,
      );
      expect(ownCatalogMatchesQuery(own, ''), isFalse);
    });

    test('own matches win and hide other-user rows', () {
      final hits = shopLoggerSuggestions(
        ownShops: own,
        otherShops: [other, shop('x', 'Lantern')],
        query: 'lan',
      );
      expect(hits.map((h) => h.shop.name), ['Lan Shan', '50 Lan']);
      expect(hits.every((h) => !h.createdByAnotherUser), isTrue);
    });

    test('other-user shops appear only when own catalog has no match', () {
      final hits = shopLoggerSuggestions(
        ownShops: own,
        otherShops: [other],
        query: 'Tea',
      );
      expect(hits, hasLength(1));
      expect(hits.single.shop.name, 'Tea & Magic Hand');
      expect(hits.single.createdByAnotherUser, isTrue);
    });

    test('exact other-user name still suggests attach, not a new insert', () {
      final hits = shopLoggerSuggestions(
        ownShops: own,
        otherShops: [other],
        query: 'Tea & Magic Hand',
      );
      expect(hits.single.shop.id, 'o1');
      expect(hits.single.createdByAnotherUser, isTrue);
      expect(existingShopForName([other], 'tea & magic hand')?.id, 'o1');
    });

    test('attach existing on unique violation instead of inserting again', () {
      expect(looksLikeUniqueViolation('duplicate key value 23505'), isTrue);
      expect(
        existingShopForName(own, 'Tea & Magic Hand'),
        isNull,
      );
      expect(
        mergeShopsForLog(own, [other]).map((s) => s.id),
        containsAll(['1', '2', 'o1']),
      );
    });
  });

  group('shop display + create', () {
    test('one line English / 中文, Chinese-only, English-only', () {
      expect(
        shop('1', '50 Lan', nameZh: '五十嵐').displayName,
        '50 Lan / 五十嵐',
      );
      expect(
        ShopRow(
          id: '2',
          name: null,
          nameZh: '一手私藏',
          userId: 'u',
          isUserAdded: true,
        ).displayName,
        '一手私藏',
      );
      expect(shop('3', 'Lan Shan').displayName, 'Lan Shan');
    });

    test('Chinese-only logger input does not invent an English name', () {
      expect(looksLikeChineseOnly('一手私藏'), isTrue);
      expect(looksLikeChineseOnly('50 Lan'), isFalse);
      expect(looksLikeChineseOnly('Milksha 迷客夏'), isFalse);
      expect(shopCreateColumns('一手私藏'), {'name': null, 'name_zh': '一手私藏'});
      expect(shopCreateColumns('50 Lan'), {'name': '50 Lan', 'name_zh': null});
    });

    test('snapPercent stays on 10% steps', () {
      expect(snapPercent(0), 0);
      expect(snapPercent(14), 10);
      expect(snapPercent(15), 20);
      expect(snapPercent(100), 100);
    });
  });

  group('TeaNavBar', () {
    testWidgets('four equal tabs; Home label only when selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 52,
              child: TeaNavBar(selectedIndex: 0, onSelect: (_) {}),
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Map'), findsNothing);
      expect(find.text('Social'), findsNothing);
      expect(find.text('Profile'), findsNothing);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.map_rounded), findsOneWidget);
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      final expanded = tester.widgetList<Expanded>(find.byType(Expanded));
      expect(expanded.length, 4);
      expect(expanded.every((e) => e.flex == 1), isTrue);
    });

    testWidgets('logger idle shows no leftover Home text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 52,
              child: TeaNavBar(selectedIndex: -1, onSelect: (_) {}),
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsNothing);
      expect(find.text('Map'), findsNothing);
      expect(find.text('Social'), findsNothing);
      expect(find.text('Profile'), findsNothing);
      expect(find.byType(Expanded), findsNWidgets(4));
    });
  });

  group('ShopNameField other-user rows', () {
    testWidgets('shows Created by another user when own catalog has no match', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTeaTheme(),
          home: Scaffold(
            body: ShopNameField(
              controller: controller,
              shops: [shop('1', '50 Lan')],
              onChanged: () {},
              searchOtherShops: (_) async => [
                ShopRow(
                  id: 'o1',
                  name: 'Tea & Magic Hand',
                  userId: 'other',
                  isUserAdded: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Tea');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.text('Tea & Magic Hand'), findsOneWidget);
      expect(find.text(kCreatedByAnotherUserSubtitle), findsOneWidget);
    });

    testWidgets('does not search others on an empty query', (tester) async {
      var searched = false;
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTeaTheme(),
          home: Scaffold(
            body: ShopNameField(
              controller: controller,
              shops: [shop('1', '50 Lan')],
              onChanged: () {},
              searchOtherShops: (_) async {
                searched = true;
                return const [];
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump(const Duration(milliseconds: 350));
      expect(searched, isFalse);
      expect(find.text(kCreatedByAnotherUserSubtitle), findsNothing);
    });
  });
}
