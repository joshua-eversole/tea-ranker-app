import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/hangouts.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/data/social.dart';
import 'package:tea_ranker/screens/friend_taste_screen.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/widgets/with_companions_line.dart';

ShopRow shop({required String id, String? name, String? nameZh}) => ShopRow(
  id: id,
  name: name,
  nameZh: nameZh,
  userId: 'them',
  isUserAdded: true,
);

DrinkEntryRow drink({
  required String id,
  required DateTime at,
  ShopRow? atShop,
}) => DrinkEntryRow(
  id: id,
  userId: 'them',
  shopId: atShop?.id ?? 's',
  teaName: 'Milk tea',
  drinkType: 'Milk-based',
  sugarLevel: 30,
  iceLevel: 50,
  price: 50,
  grade: 4,
  overallGrade: 'A',
  notes: 'secret',
  loggedAt: at,
  shop: atShop,
);

void main() {
  test('With line is With {username}, comma-separated if several', () {
    expect(withCompanionsCopy(['maya']), 'With maya');
    expect(withCompanionsCopy(['maya', 'ken']), 'With maya, ken');
    expect(withCompanionsCopy(['', '  ']), '');
  });

  test('skip invite when friend logged same shop name that local day', () {
    final fifty = shop(id: 's1', name: '50 Lan', nameZh: '五十嵐');
    final day = DateTime(2026, 10, 21, 15);
    final existing = mostRecentSameShopDay(
      friendDrinks: [
        drink(id: 'old', at: DateTime(2026, 10, 21, 8), atShop: fifty),
        drink(id: 'new', at: DateTime(2026, 10, 21, 12), atShop: fifty),
        drink(id: 'other-day', at: DateTime(2026, 10, 20, 12), atShop: fifty),
      ],
      shopName: '50 Lan / 五十嵐',
      localDay: day,
    );
    expect(existing?.id, 'new');
    expect(shouldSendHangoutInvite(existing), isFalse);
  });

  test(
    'invite when shop name does not match, even same shop id would not apply',
    () {
      final theirs = shop(id: 'same-id', name: 'Kebuke', nameZh: '可不可熟成紅茶');
      final existing = mostRecentSameShopDay(
        friendDrinks: [
          drink(id: 'k', at: DateTime(2026, 10, 21, 12), atShop: theirs),
        ],
        shopName: '50 Lan',
        localDay: DateTime(2026, 10, 21),
      );
      expect(existing, isNull);
      expect(shouldSendHangoutInvite(existing), isTrue);
    },
  );

  test('hangout accept prefill is date, shop name, that friend', () {
    final prefill = HangoutLogPrefill(
      localDay: DateTime(2026, 10, 21),
      shopName: '50 Lan / 五十嵐',
      friendUserId: 'sender',
      fromDrinkId: 'd1',
      hangoutId: 'h1',
    );
    expect(prefill.toLocation(), contains('/log?'));
    expect(prefill.toLocation(), contains('shop='));
    expect(HangoutLogPrefill.fromQuery({'date': '2026-10-21'}), isNull);
    final parsed = HangoutLogPrefill.fromQuery({
      'date': '2026-10-21',
      'shop': '50 Lan / 五十嵐',
      'with': 'sender',
      'from': 'd1',
      'hangout': 'h1',
    });
    expect(parsed?.friendUserId, 'sender');
    expect(parsed?.shopName, '50 Lan / 五十嵐');
    expect(parsed?.fromDrinkId, 'd1');
  });

  test('decline hides pending hangout invite only', () {
    final pending = DrinkCompanionRow(
      drinkEntryId: 'd1',
      friendUserId: 'me',
      inviteStatus: CompanionInviteStatus.pending,
    );
    final declined = DrinkCompanionRow(
      drinkEntryId: 'd2',
      friendUserId: 'me',
      inviteStatus: CompanionInviteStatus.declined,
    );
    expect(
      pendingHangoutInvites([
        HangoutInvite(
          companion: pending,
          senderId: 's',
          senderUsername: 'maya',
          shopName: '50 Lan',
          localDay: DateTime(2026, 10, 21),
        ),
        HangoutInvite(
          companion: declined,
          senderId: 's',
          senderUsername: 'maya',
          shopName: '50 Lan',
          localDay: DateTime(2026, 10, 21),
        ),
      ]).map((i) => i.companion.drinkEntryId),
      ['d1'],
    );
  });

  testWidgets('With line is not a link without peer_drink_id', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Scaffold(
          backgroundColor: AppColors.cream,
          body: WithCompanionsLine(
            companions: const [
              DrinkCompanionView(userId: 'u', username: 'maya'),
            ],
            onTapLinked: (_) => fail('should not tap'),
          ),
        ),
      ),
    );
    expect(find.text('With '), findsOneWidget);
    expect(find.text('maya'), findsOneWidget);
    await tester.tap(find.text('maya'));
    await tester.pump();
  });

  testWidgets('friend drink card shows With line, no edit', (tester) async {
    final row =
        drink(
          id: 'd1',
          at: DateTime(2026, 10, 1, 12),
          atShop: shop(id: 's', name: '50 Lan', nameZh: '五十嵐'),
        ).withRelations(
          companions: const [
            DrinkCompanionView(userId: 'me', username: 'joshua'),
          ],
        );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Scaffold(
          backgroundColor: AppColors.cream,
          body: FriendDrinkCard(drink: row),
        ),
      ),
    );
    expect(find.text('With '), findsOneWidget);
    expect(find.text('joshua'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(kWithAnyoneLabel, 'With anyone?');
    expect(kHangoutInvitationsTitle, 'Hangout invitations');
    expect(kAcceptInviteLabel, 'Accept');
    expect(kDeclineInviteLabel, 'Decline');
    expect(kHangoutSheetDoneLabel, 'Done');
  });

  testWidgets('With names stay on one row when they fit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: const Scaffold(
          backgroundColor: AppColors.cream,
          body: WithCompanionsLine(
            companions: [
              DrinkCompanionView(userId: 'a', username: 'maya'),
              DrinkCompanionView(userId: 'b', username: 'ken'),
            ],
          ),
        ),
      ),
    );
    final withBox = tester.getRect(find.text('With '));
    final mayaBox = tester.getRect(find.text('maya'));
    final kenBox = tester.getRect(find.text('ken'));
    expect(mayaBox.left, greaterThan(withBox.right - 2));
    expect(kenBox.left, greaterThan(mayaBox.right));
    expect(mayaBox.center.dy, closeTo(withBox.center.dy, 8));
    expect(kenBox.center.dy, closeTo(mayaBox.center.dy, 8));
  });
}
