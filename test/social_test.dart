import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/data/social.dart';
import 'package:tea_ranker/screens/friend_taste_screen.dart';
import 'package:tea_ranker/screens/social_screen.dart';
import 'package:tea_ranker/theme/tokens.dart';

FriendshipRow edge(String a, String b, FriendshipStatus status) =>
    FriendshipRow(userId: a, friendId: b, status: status);

void main() {
  const me = 'me';
  const other = 'you';

  test('cannot friend yourself', () {
    expect(
      friendRelation(me: me, other: me, rows: const []),
      FriendRelation.self,
    );
    expect(canSendFriendRequest(FriendRelation.self), isFalse);
  });

  test('blocks duplicate pending and accepted requests', () {
    expect(
      canSendFriendRequest(
        friendRelation(
          me: me,
          other: other,
          rows: [edge(me, other, FriendshipStatus.pending)],
        ),
      ),
      isFalse,
    );
    expect(
      canSendFriendRequest(
        friendRelation(
          me: me,
          other: other,
          rows: [edge(other, me, FriendshipStatus.pending)],
        ),
      ),
      isFalse,
    );
    expect(
      canSendFriendRequest(
        friendRelation(
          me: me,
          other: other,
          rows: [edge(me, other, FriendshipStatus.accepted)],
        ),
      ),
      isFalse,
    );
  });

  test('decline hides the invite and allows a later request', () {
    final declined = [edge(other, me, FriendshipStatus.declined)];
    expect(incomingInvitations(me: me, rows: declined), isEmpty);
    expect(
      friendRelation(me: me, other: other, rows: declined),
      FriendRelation.declined,
    );
    expect(canSendFriendRequest(FriendRelation.declined), isTrue);
  });

  test('search is username-only and skips self', () {
    final hits = searchDirectory(
      me: me,
      needle: 'bob',
      directory: const [
        DirectoryProfile(id: me, username: 'bobby'),
        DirectoryProfile(id: '2', username: 'BobaFan'),
        DirectoryProfile(id: '3', username: 'tea'),
      ],
    );
    expect(hits.map((p) => p.id), ['2']);
  });

  test('last drinks are the 3 most recent by logged_at', () {
    DrinkEntryRow drink(String id, DateTime at) => DrinkEntryRow(
      id: id,
      userId: other,
      shopId: 's',
      teaName: id,
      drinkType: 'Tea-based',
      sugarLevel: 30,
      iceLevel: 50,
      price: 50,
      grade: 4,
      overallGrade: 'A',
      notes: 'secret',
      loggedAt: at,
    );
    final kept = lastDrinks([
      drink('old', DateTime(2026, 1, 1)),
      drink('new', DateTime(2026, 10, 1)),
      drink('mid', DateTime(2026, 5, 1)),
      drink('newer', DateTime(2026, 10, 20)),
    ]);
    expect(kept.map((e) => e.id).toList(), ['newer', 'new', 'mid']);
  });

  testWidgets('Social loading and error copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ColoredBox(
          color: AppColors.cream,
          child: SizedBox(
            width: 390,
            height: 700,
            child: Scaffold(backgroundColor: AppColors.cream),
          ),
        ),
      ),
    );
    expect(socialPhase(loading: true, error: null), SocialPhase.loading);
    expect(socialPhase(loading: false, error: 'x'), SocialPhase.error);
    expect(socialPhase(loading: false, error: null), SocialPhase.ready);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: const ColoredBox(
          color: AppColors.cream,
          child: Scaffold(
            backgroundColor: AppColors.cream,
            body: SizedBox.shrink(),
          ),
        ),
      ),
    );
    expect(kSocialLoadingCopy, 'Loading friends…');
    expect(kSocialErrorCopy, 'Couldn’t load Social.');
    expect(kSendFriendRequestLabel, 'Send friend request');
    expect(kAcceptInviteLabel, 'Accept');
    expect(kDeclineInviteLabel, 'Decline');
  });

  testWidgets('friend drink card has no edit or delete', (tester) async {
    final drink = DrinkEntryRow(
      id: 'd1',
      userId: other,
      shopId: 's',
      teaName: 'Wintermelon',
      drinkType: 'Tea-based',
      sugarLevel: 30,
      iceLevel: 50,
      price: 50,
      grade: 5,
      overallGrade: 'S',
      notes: 'do not show',
      loggedAt: DateTime(2026, 10, 1, 12),
      shop: const ShopRow(
        id: 's',
        name: '50 Lan',
        nameZh: '五十嵐',
        userId: other,
        isUserAdded: false,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: Scaffold(
          backgroundColor: AppColors.cream,
          body: FriendDrinkCard(drink: drink),
        ),
      ),
    );
    expect(find.text('Wintermelon'), findsOneWidget);
    expect(find.text('50 Lan / 五十嵐'), findsOneWidget);
    expect(find.text('do not show'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });
}
