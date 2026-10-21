import 'package:flutter/material.dart';

import '../data/hangouts.dart';
import '../data/models.dart';
import '../data/social.dart';
import '../theme/tokens.dart';

class WithCompanionsLine extends StatelessWidget {
  const WithCompanionsLine({
    super.key,
    required this.companions,
    this.onTapLinked,
  });

  final List<DrinkCompanionView> companions;
  final void Function(DrinkCompanionView companion)? onTapLinked;

  @override
  Widget build(BuildContext context) {
    final named = [
      for (final c in companions)
        if (c.username.trim().isNotEmpty) c,
    ];
    if (named.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'With ',
            style: TextStyle(color: AppColors.chocolate, fontSize: 13),
          ),
          for (var i = 0; i < named.length; i++) ...[
            _Name(
              companion: named[i],
              onTap: named[i].hasLinkedPeer
                  ? () => onTapLinked?.call(named[i])
                  : null,
            ),
            if (i != named.length - 1)
              const Text(
                ', ',
                style: TextStyle(color: AppColors.chocolate, fontSize: 13),
              ),
          ],
        ],
      ),
    );
  }
}

class _Name extends StatelessWidget {
  const _Name({required this.companion, this.onTap});
  final DrinkCompanionView companion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: onTap == null ? AppColors.chocolate : AppColors.boba,
      fontSize: 13,
      fontWeight: onTap == null ? FontWeight.w400 : FontWeight.w600,
      decoration: onTap == null ? null : TextDecoration.underline,
      decorationColor: AppColors.boba,
    );
    if (onTap == null) {
      return Text(companion.username, style: style);
    }
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppLayout.minTap),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(companion.username, style: style),
        ),
      ),
    );
  }
}

Future<Set<String>?> showCompanionsSheet({
  required BuildContext context,
  required List<DirectoryProfile> friends,
  required Set<String> selected,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    barrierColor: AppColors.boba.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) => _CompanionsSheet(friends: friends, initial: selected),
  );
}

class _CompanionsSheet extends StatefulWidget {
  const _CompanionsSheet({required this.friends, required this.initial});
  final List<DirectoryProfile> friends;
  final Set<String> initial;

  @override
  State<_CompanionsSheet> createState() => _CompanionsSheetState();
}

class _CompanionsSheetState extends State<_CompanionsSheet> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kWithAnyoneLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (widget.friends.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  kNoFriendsCopy,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.chocolate),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final friend in widget.friends)
                      CheckboxListTile(
                        value: _selected.contains(friend.id),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(friend.id);
                            } else {
                              _selected.remove(friend.id);
                            }
                          });
                        },
                        title: Text(friend.username),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                  ],
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: const Text(kHangoutSheetDoneLabel),
            ),
          ],
        ),
      ),
    );
  }
}
