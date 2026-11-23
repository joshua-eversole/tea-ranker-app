import 'package:flutter/material.dart';

import '../data/social.dart';
import '../theme/friend_wash.dart';
import '../theme/tokens.dart';

class FriendCard extends StatelessWidget {
  const FriendCard({
    super.key,
    required this.friend,
    required this.drinkCount,
    this.onTap,
  });

  final DirectoryProfile friend;
  final int drinkCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final wash = friendCardWash(friend.id, friend.username);
    final avatarFill = friendAvatarWash(friend.id, friend.username);
    final initials = usernameInitials(friend.username);
    final favorite = trimFavoriteDrink(friend.favoriteDrink);
    final displayName = friend.username.trim().isEmpty
        ? 'Friend'
        : friend.username.trim();
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: const BorderSide(color: AppColors.seed, width: 1),
    );

    return Material(
      color: wash,
      elevation: 2,
      shadowColor: AppColors.boba.withValues(alpha: 0.18),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: avatarFill,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: initials.length > 1 ? 16 : 18,
                    color: friendInitialsColor(avatarFill),
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.boba,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      friendDrinksLoggedCopy(drinkCount),
                      style: const TextStyle(
                        color: AppColors.chocolate,
                        fontSize: 14,
                      ),
                    ),
                    if (favorite != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$kFavoriteDrinkLabel  $favorite',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.chocolate,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.chocolate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
