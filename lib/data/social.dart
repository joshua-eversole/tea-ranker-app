import 'models.dart';

const kSocialTitle = 'Social';
const kSocialLoadingCopy = 'Loading friends…';
const kSocialErrorCopy = 'Couldn’t load Social.';
const kSocialSearchHint = 'Search usernames';
const kSocialSearchIdle = 'Type a username to find people on Tea Ranker.';
const kSocialSearchEmpty = 'No usernames match.';
const kSendFriendRequestLabel = 'Send friend request';
const kFriendRequestSentLabel = 'Requested';
const kSendingRequestLabel = 'Sending…';
const kAlreadyFriendsLabel = 'Friends';
const kInvitedYouLabel = 'Invited you';
const kInvitationsTitle = 'Invitations';
const kNoInvitationsCopy = 'No invitations right now.';
const kAcceptInviteLabel = 'Accept';
const kDeclineInviteLabel = 'Decline';
const kFriendsTitle = 'Friends';
const kNoFriendsCopy = 'No friends yet. Search a username to send a request.';
const kFriendTasteTitle = 'Taste Profile';
const kFriendLastDrinksTitle = 'Last drinks';
const kFriendNoDrinksCopy = 'No drinks yet';
const kFriendLoadingCopy = 'Loading their log…';
const kFriendErrorCopy = 'Couldn’t load this friend’s log.';
const kSocialSqlHint =
    'Paste supabase/friendships_status_and_rls.sql in the Supabase SQL editor.';
const kFavoriteDrinkLabel = 'Favorite drink';
const kFavoriteDrinkHint = 'Brown sugar boba';
const kFavoriteDrinkSqlHint =
    'Paste supabase/profiles_favorite_drink.sql in the Supabase SQL editor.';
const kFavoriteDrinkMaxLength = 80;

String? trimFavoriteDrink(String? raw) {
  final t = raw?.trim();
  if (t == null || t.isEmpty) return null;
  if (t.length <= kFavoriteDrinkMaxLength) return t;
  return t.substring(0, kFavoriteDrinkMaxLength).trim();
}

/// First letter of the username, or first letters of the first two tokens.
String usernameInitials(String username) {
  final trimmed = username.trim();
  if (trimmed.isEmpty) return '?';
  final parts = [
    for (final p in trimmed.split(RegExp(r'[\s_\-]+')))
      if (p.isNotEmpty) p,
  ];
  if (parts.length >= 2) {
    return '${_firstGrapheme(parts[0])}${_firstGrapheme(parts[1])}'
        .toUpperCase();
  }
  return _firstGrapheme(parts.first).toUpperCase();
}

String _firstGrapheme(String value) {
  final runes = value.runes;
  if (runes.isEmpty) return '';
  return String.fromCharCode(runes.first);
}

String friendDrinksLoggedCopy(int count) {
  return count == 1 ? '1 drink logged' : '$count drinks logged';
}

Map<String, int> countDrinksByUserId(Iterable<DrinkEntryRow> entries) {
  final counts = <String, int>{};
  for (final e in entries) {
    counts[e.userId] = (counts[e.userId] ?? 0) + 1;
  }
  return counts;
}

enum FriendshipStatus { pending, accepted, declined }

FriendshipStatus? parseFriendshipStatus(String? raw) {
  switch (raw) {
    case 'pending':
      return FriendshipStatus.pending;
    case 'accepted':
      return FriendshipStatus.accepted;
    case 'declined':
      return FriendshipStatus.declined;
    default:
      return null;
  }
}

class FriendshipRow {
  const FriendshipRow({
    required this.userId,
    required this.friendId,
    required this.status,
    this.createdAt,
  });

  final String userId;
  final String friendId;
  final FriendshipStatus status;
  final DateTime? createdAt;

  factory FriendshipRow.fromMap(Map<String, dynamic> map) {
    final status =
        parseFriendshipStatus(map['status'] as String?) ??
        FriendshipStatus.accepted;
    return FriendshipRow(
      userId: map['user_id'] as String,
      friendId: map['friend_id'] as String,
      status: status,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}

class DirectoryProfile {
  const DirectoryProfile({
    required this.id,
    required this.username,
    this.favoriteDrink,
  });
  final String id;
  final String username;
  final String? favoriteDrink;

  factory DirectoryProfile.fromMap(Map<String, dynamic> map) =>
      DirectoryProfile(
        id: map['id'] as String,
        username: (map['username'] as String?) ?? '',
        favoriteDrink: trimFavoriteDrink(map['favorite_drink'] as String?),
      );
}

enum FriendRelation {
  self,
  none,
  outgoingPending,
  incomingPending,
  accepted,
  declined,
}

FriendRelation friendRelation({
  required String me,
  required String other,
  required List<FriendshipRow> rows,
}) {
  if (me == other) return FriendRelation.self;
  FriendshipRow? pending;
  FriendshipRow? accepted;
  var declined = false;
  for (final row in rows) {
    final involves =
        (row.userId == me && row.friendId == other) ||
        (row.userId == other && row.friendId == me);
    if (!involves) continue;
    switch (row.status) {
      case FriendshipStatus.accepted:
        accepted = row;
      case FriendshipStatus.pending:
        pending = row;
      case FriendshipStatus.declined:
        declined = true;
    }
  }
  if (accepted != null) return FriendRelation.accepted;
  if (pending != null) {
    if (pending.userId == me) return FriendRelation.outgoingPending;
    return FriendRelation.incomingPending;
  }
  if (declined) return FriendRelation.declined;
  return FriendRelation.none;
}

bool canSendFriendRequest(FriendRelation relation) {
  return relation == FriendRelation.none || relation == FriendRelation.declined;
}

List<FriendshipRow> incomingInvitations({
  required String me,
  required List<FriendshipRow> rows,
}) {
  return [
    for (final row in rows)
      if (row.status == FriendshipStatus.pending && row.friendId == me) row,
  ];
}

List<DirectoryProfile> acceptedFriends({
  required String me,
  required List<FriendshipRow> rows,
  required Map<String, DirectoryProfile> directory,
}) {
  final friends = <DirectoryProfile>[];
  for (final row in rows) {
    if (row.status != FriendshipStatus.accepted) continue;
    final otherId = row.userId == me ? row.friendId : row.userId;
    if (row.userId != me && row.friendId != me) continue;
    final profile = directory[otherId];
    if (profile != null) friends.add(profile);
  }
  friends.sort(
    (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
  );
  return friends;
}

List<DirectoryProfile> searchDirectory({
  required String me,
  required String needle,
  required List<DirectoryProfile> directory,
}) {
  final q = needle.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return [
    for (final p in directory)
      if (p.id != me && p.username.toLowerCase().contains(q)) p,
  ];
}

List<DrinkEntryRow> lastDrinks(List<DrinkEntryRow> entries, {int n = 3}) {
  final sorted = [...entries]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  if (sorted.length <= n) return sorted;
  return sorted.take(n).toList();
}
