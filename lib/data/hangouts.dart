import 'dart:math';

import 'models.dart';
import 'social.dart';

const kWithAnyoneLabel = 'With anyone?';
const kHangoutInvitationsTitle = 'Hangout invitations';
const kHangoutSheetDoneLabel = 'Done';
const kHangoutDrinkLoadingCopy = 'Loading their drink…';
const kHangoutDrinkErrorCopy = 'Couldn’t load this drink.';
const kHangoutSqlHint =
    'Paste supabase/hangouts_companions.sql in the Supabase SQL editor.';

enum CompanionInviteStatus { pending, accepted, declined, linked }

CompanionInviteStatus? parseCompanionInviteStatus(String? raw) {
  switch (raw) {
    case 'pending':
      return CompanionInviteStatus.pending;
    case 'accepted':
      return CompanionInviteStatus.accepted;
    case 'declined':
      return CompanionInviteStatus.declined;
    case 'linked':
      return CompanionInviteStatus.linked;
    default:
      return null;
  }
}

class DrinkCompanionRow {
  const DrinkCompanionRow({
    required this.drinkEntryId,
    required this.friendUserId,
    this.peerDrinkId,
    this.inviteStatus,
    this.username = '',
    this.pendingLabel,
  });

  final String drinkEntryId;
  final String friendUserId;
  final String? peerDrinkId;
  final CompanionInviteStatus? inviteStatus;
  final String username;
  final String? pendingLabel;

  bool get hasLinkedPeer => peerDrinkId != null && peerDrinkId!.isNotEmpty;

  factory DrinkCompanionRow.fromMap(Map<String, dynamic> map) {
    String username = '';
    final profile = map['profiles'];
    if (profile is Map) {
      username = (profile['username'] as String?) ?? '';
    }
    username = (map['username'] as String?) ?? username;
    return DrinkCompanionRow(
      drinkEntryId: map['drink_entry_id'] as String,
      friendUserId: map['friend_user_id'] as String,
      peerDrinkId: map['peer_drink_id'] as String?,
      inviteStatus: parseCompanionInviteStatus(map['invite_status'] as String?),
      username: username,
      pendingLabel: map['pending_label'] as String?,
    );
  }

  DrinkCompanionRow withUsername(String name) {
    return DrinkCompanionRow(
      drinkEntryId: drinkEntryId,
      friendUserId: friendUserId,
      peerDrinkId: peerDrinkId,
      inviteStatus: inviteStatus,
      username: name,
      pendingLabel: pendingLabel,
    );
  }
}

class HangoutInvite {
  const HangoutInvite({
    required this.companion,
    required this.senderId,
    required this.senderUsername,
    required this.shopName,
    required this.localDay,
    this.hangoutId,
  });

  final DrinkCompanionRow companion;
  final String senderId;
  final String senderUsername;
  final String shopName;
  final DateTime localDay;
  final String? hangoutId;

  HangoutLogPrefill get prefill => HangoutLogPrefill(
    localDay: localDay,
    shopName: shopName,
    friendUserId: senderId,
    fromDrinkId: companion.drinkEntryId,
    hangoutId: hangoutId,
  );
}

class HangoutLogPrefill {
  const HangoutLogPrefill({
    required this.localDay,
    required this.shopName,
    required this.friendUserId,
    required this.fromDrinkId,
    this.hangoutId,
  });

  final DateTime localDay;
  final String shopName;
  final String friendUserId;
  final String fromDrinkId;
  final String? hangoutId;

  static HangoutLogPrefill? fromQuery(Map<String, String> q) {
    final from = q['from'];
    final withId = q['with'];
    final shop = q['shop'];
    final date = q['date'];
    if (from == null ||
        from.isEmpty ||
        withId == null ||
        withId.isEmpty ||
        shop == null ||
        shop.isEmpty ||
        date == null ||
        date.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return null;
    return HangoutLogPrefill(
      localDay: DateTime(parsed.year, parsed.month, parsed.day),
      shopName: shop,
      friendUserId: withId,
      fromDrinkId: from,
      hangoutId: q['hangout'],
    );
  }

  String toLocation() {
    final date =
        '${localDay.year.toString().padLeft(4, '0')}-${localDay.month.toString().padLeft(2, '0')}-${localDay.day.toString().padLeft(2, '0')}';
    final params = <String, String>{
      'date': date,
      'shop': shopName,
      'with': friendUserId,
      'from': fromDrinkId,
    };
    if (hangoutId != null && hangoutId!.isNotEmpty) {
      params['hangout'] = hangoutId!;
    }
    final encoded = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return '/log?$encoded';
  }
}

/// `With {username}` or `With a, b` when several.
String withCompanionsCopy(Iterable<String> usernames) {
  final names = [
    for (final n in usernames)
      if (n.trim().isNotEmpty) n.trim(),
  ];
  if (names.isEmpty) return '';
  return 'With ${names.join(', ')}';
}

bool isSameLocalDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Same shop that local calendar day — match display name, never shop id.
DrinkEntryRow? mostRecentSameShopDay({
  required List<DrinkEntryRow> friendDrinks,
  required String shopName,
  required DateTime localDay,
}) {
  final needle = shopName.trim();
  if (needle.isEmpty) return null;
  DrinkEntryRow? best;
  for (final drink in friendDrinks) {
    if (!isSameLocalDay(drink.loggedAt, localDay)) continue;
    final shop = drink.shop;
    if (shop == null || !shop.matchesNeedle(needle)) continue;
    if (best == null || drink.loggedAt.isAfter(best.loggedAt)) {
      best = drink;
    }
  }
  return best;
}

bool shouldSendHangoutInvite(DrinkEntryRow? existingSameShopDay) {
  return existingSameShopDay == null;
}

List<HangoutInvite> pendingHangoutInvites(List<HangoutInvite> rows) {
  return [
    for (final row in rows)
      if (row.companion.inviteStatus == CompanionInviteStatus.pending) row,
  ];
}

String newHangoutId() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int start, int len) => bytes
      .sublist(start, start + len)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 2)}-${hex(6, 2)}-${hex(8, 2)}-${hex(10, 6)}';
}

List<DirectoryProfile> acceptedFriendsOnly({
  required String me,
  required List<FriendshipRow> friendships,
  required List<DirectoryProfile> directory,
}) {
  return acceptedFriends(
    me: me,
    rows: friendships,
    directory: {for (final p in directory) p.id: p},
  );
}
