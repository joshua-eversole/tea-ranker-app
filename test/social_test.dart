import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tea_ranker/data/models.dart';
import 'package:tea_ranker/data/social.dart';
import 'package:tea_ranker/grading/grade.dart';
import 'package:tea_ranker/screens/friend_taste_screen.dart';
import 'package:tea_ranker/screens/map_screen.dart';
import 'package:tea_ranker/screens/social_screen.dart';
import 'package:tea_ranker/theme/friend_wash.dart';
import 'package:tea_ranker/theme/tokens.dart';
import 'package:tea_ranker/widgets/friend_card.dart';

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

  test('username initials use first letter(s)', () {
    expect(usernameInitials('mei'), 'M');
    expect(usernameInitials('BobaFan'), 'B');
    expect(usernameInitials('boba fan'), 'BF');
    expect(usernameInitials('tea_leaf'), 'TL');
    expect(usernameInitials('wu-wei'), 'WW');
    expect(usernameInitials('  '), '?');
  });

  test('trimFavoriteDrink is user-set and empty is null', () {
    expect(trimFavoriteDrink('  Brown sugar boba  '), 'Brown sugar boba');
    expect(trimFavoriteDrink(''), isNull);
    expect(trimFavoriteDrink('   '), isNull);
    expect(trimFavoriteDrink(null), isNull);
    expect(trimFavoriteDrink('x' * 90)?.length, kFavoriteDrinkMaxLength);
  });

  test('drink counts are per friend user_id', () {
    DrinkEntryRow drink(String id, String user) => DrinkEntryRow(
      id: id,
      userId: user,
      shopId: 's',
      teaName: id,
      drinkType: 'Tea-based',
      sugarLevel: 30,
      iceLevel: 50,
      price: 50,
      grade: 4,
      overallGrade: 'A',
      notes: null,
      loggedAt: DateTime(2026, 10, 1),
    );
    final counts = countDrinksByUserId([
      drink('a', 'you'),
      drink('b', 'you'),
      drink('c', 'other'),
    ]);
    expect(counts['you'], 2);
    expect(counts['other'], 1);
    expect(friendDrinksLoggedCopy(0), '0 drinks logged');
    expect(friendDrinksLoggedCopy(1), '1 drink logged');
    expect(friendDrinksLoggedCopy(22), '22 drinks logged');
  });

  test('friend wash is a stable cream mix, not a neon fill', () {
    const id = 'friend-1';
    const name = 'Mei';
    final hue = friendHueFor(id, name);
    final wash = friendCardWash(id, name);
    expect(wash, Color.lerp(AppColors.cream, hue, kFriendCardWashMix));
    expect(wash, isNot(hue));
    expect(kFriendCardWashMix, lessThan(0.5));
    expect(kFriendCardWashMix, greaterThan(kGradeWashMix));
    expect(friendCardWash(id, name), friendCardWash(id, name));
    expect(stableFriendHash(id, name), isNot(stableFriendHash('other', name)));
  });

  testWidgets('friend card is a wash card with their favorite, not yours', (
    tester,
  ) async {
    const mine = 'Pearl milk tea';
    const theirs = 'Wintermelon';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: const Scaffold(
          backgroundColor: AppColors.cream,
          body: Padding(
            padding: EdgeInsets.all(24),
            child: FriendCard(
              friend: DirectoryProfile(
                id: 'you',
                username: 'Mei Chen',
                favoriteDrink: theirs,
              ),
              drinkCount: 22,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.text('MC'), findsOneWidget);
    expect(find.text('Mei Chen'), findsOneWidget);
    expect(find.text('22 drinks logged'), findsOneWidget);
    expect(find.text('Favorite drink  Wintermelon'), findsOneWidget);
    expect(find.text(mine), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('friend card omits empty favorite', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTeaTheme(),
        home: const Scaffold(
          backgroundColor: AppColors.cream,
          body: FriendCard(
            friend: DirectoryProfile(id: 'you', username: 'Mei'),
            drinkCount: 0,
          ),
        ),
      ),
    );
    expect(find.text('M'), findsOneWidget);
    expect(find.text('0 drinks logged'), findsOneWidget);
    expect(find.textContaining(kFavoriteDrinkLabel), findsNothing);
  });

  testWidgets('Map stays brewing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildTeaTheme(), home: const MapScreen()),
    );
    expect(find.text('Map is brewing.'), findsOneWidget);
    expect(
      find.text(
        'Shop pins on a real map are next — your log stays private until then.',
      ),
      findsOneWidget,
    );
  });

  test(
    'ProfileRow reads favorite_drink and own-write copyWith can clear it',
    () {
      final row = ProfileRow.fromMap({
        'id': 'me',
        'username': 'joshua',
        'favorite_drink': '  Brown sugar  ',
      });
      expect(row.favoriteDrink, 'Brown sugar');
      expect(row.copyWith(clearFavoriteDrink: true).favoriteDrink, isNull);
    },
  );
}
