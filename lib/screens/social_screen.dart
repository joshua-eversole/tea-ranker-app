import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/social.dart';
import '../data/tea_repository.dart';
import '../theme/tokens.dart';
import '../widgets/tea_skeleton.dart';
import 'home_screen.dart';

enum SocialPhase { loading, error, ready }

SocialPhase socialPhase({required bool loading, required Object? error}) {
  if (error != null) return SocialPhase.error;
  if (loading) return SocialPhase.loading;
  return SocialPhase.ready;
}

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key, required this.repo});

  final TeaRepository repo;

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  Object? _error;
  List<DirectoryProfile> _directory = const [];
  List<FriendshipRow> _friendships = const [];
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final directory = await widget.repo.loadDirectory();
      final friendships = await widget.repo.loadFriendships();
      if (!mounted) return;
      setState(() {
        _directory = directory;
        _friendships = friendships;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Map<String, DirectoryProfile> get _byId => {
    for (final p in _directory) p.id: p,
  };

  Future<void> _send(String friendId) async {
    setState(() => _busyId = friendId);
    try {
      await widget.repo.sendFriendRequest(friendId);
      await _reloadQuiet();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn’t send that request. $kSocialSqlHint'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _respond(String requesterId, FriendshipStatus status) async {
    setState(() => _busyId = requesterId);
    try {
      await widget.repo.respondToInvite(
        requesterId: requesterId,
        status: status,
      );
      await _reloadQuiet();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == FriendshipStatus.accepted
                ? 'Couldn’t accept that invitation.'
                : 'Couldn’t decline that invitation.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reloadQuiet() async {
    final directory = await widget.repo.loadDirectory();
    final friendships = await widget.repo.loadFriendships();
    if (!mounted) return;
    setState(() {
      _directory = directory;
      _friendships = friendships;
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final phase = socialPhase(loading: _loading, error: _error);
    switch (phase) {
      case SocialPhase.loading:
        return const _SocialSkeleton();
      case SocialPhase.error:
        return HomeLoadError(onRetry: _reload, message: kSocialErrorCopy);
      case SocialPhase.ready:
        break;
    }

    final me = widget.repo.userId ?? '';
    final matches = searchDirectory(
      me: me,
      needle: _search.text,
      directory: _directory,
    );
    final invites = incomingInvitations(me: me, rows: _friendships);
    final friends = acceptedFriends(
      me: me,
      rows: _friendships,
      directory: _byId,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Text(kSocialTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: kSocialSearchHint,
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _SearchResults(
            needle: _search.text,
            matches: matches,
            me: me,
            friendships: _friendships,
            busyId: _busyId,
            onSend: _send,
          ),
          const SizedBox(height: 28),
          Text(
            kInvitationsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (invites.isEmpty)
            const Text(
              kNoInvitationsCopy,
              style: TextStyle(color: AppColors.chocolate),
            )
          else
            for (final invite in invites)
              _InviteTile(
                username: _byId[invite.userId]?.username ?? 'Someone',
                busy: _busyId == invite.userId,
                onAccept: () =>
                    _respond(invite.userId, FriendshipStatus.accepted),
                onDecline: () =>
                    _respond(invite.userId, FriendshipStatus.declined),
              ),
          const SizedBox(height: 28),
          Text(kFriendsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (friends.isEmpty)
            const Text(
              kNoFriendsCopy,
              style: TextStyle(color: AppColors.chocolate),
            )
          else
            for (final friend in friends)
              ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 12,
                title: Text(
                  friend.username,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/social/friends/${friend.id}'),
              ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.needle,
    required this.matches,
    required this.me,
    required this.friendships,
    required this.busyId,
    required this.onSend,
  });

  final String needle;
  final List<DirectoryProfile> matches;
  final String me;
  final List<FriendshipRow> friendships;
  final String? busyId;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    if (needle.trim().isEmpty) {
      return const Text(
        kSocialSearchIdle,
        style: TextStyle(color: AppColors.chocolate),
      );
    }
    if (matches.isEmpty) {
      return const Text(
        kSocialSearchEmpty,
        style: TextStyle(color: AppColors.chocolate),
      );
    }
    return Column(
      children: [
        for (final person in matches)
          _SearchTile(
            person: person,
            relation: friendRelation(
              me: me,
              other: person.id,
              rows: friendships,
            ),
            busy: busyId == person.id,
            onSend: () => onSend(person.id),
          ),
      ],
    );
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({
    required this.person,
    required this.relation,
    required this.busy,
    required this.onSend,
  });

  final DirectoryProfile person;
  final FriendRelation relation;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final canSend = canSendFriendRequest(relation) && !busy;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 8,
      title: Text(
        person.username,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: switch (relation) {
        FriendRelation.accepted => const Text(
          kAlreadyFriendsLabel,
          style: TextStyle(color: AppColors.chocolate),
        ),
        FriendRelation.outgoingPending => const Text(
          kFriendRequestSentLabel,
          style: TextStyle(color: AppColors.chocolate),
        ),
        FriendRelation.incomingPending => const Text(
          kInvitedYouLabel,
          style: TextStyle(color: AppColors.chocolate),
        ),
        _ => TextButton(
          onPressed: canSend ? onSend : null,
          child: Text(busy ? kSendingRequestLabel : kSendFriendRequestLabel),
        ),
      },
    );
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile({
    required this.username,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final String username;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                username,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: busy ? null : onDecline,
              child: const Text(kDeclineInviteLabel),
            ),
            FilledButton(
              onPressed: busy ? null : onAccept,
              child: const Text(kAcceptInviteLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialSkeleton extends StatelessWidget {
  const _SocialSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: TeaSkeleton(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(kSocialTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text(
              kSocialLoadingCopy,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.chocolate,
              ),
            ),
            const SizedBox(height: 20),
            const TeaBone(height: 48),
            const SizedBox(height: 16),
            const TeaBone(height: 20, width: 120),
            const SizedBox(height: 12),
            const TeaBone(height: 64),
            const SizedBox(height: 12),
            const TeaBone(height: 64),
          ],
        ),
      ),
    );
  }
}
