import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/hangouts.dart';
import '../data/models.dart';
import '../data/tea_repository.dart';
import '../theme/tokens.dart';
import '../widgets/tea_skeleton.dart';
import 'friend_taste_screen.dart';
import 'home_screen.dart';

class FriendHangoutDrinkScreen extends StatefulWidget {
  const FriendHangoutDrinkScreen({
    super.key,
    required this.repo,
    required this.userId,
    required this.drinkId,
  });

  final TeaRepository repo;
  final String userId;
  final String drinkId;

  @override
  State<FriendHangoutDrinkScreen> createState() =>
      _FriendHangoutDrinkScreenState();
}

class _FriendHangoutDrinkScreenState extends State<FriendHangoutDrinkScreen> {
  bool _loading = true;
  Object? _error;
  DrinkEntryRow? _drink;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final drink = await widget.repo.fetchFriendDrink(
        friendId: widget.userId,
        drinkId: widget.drinkId,
      );
      if (!mounted) return;
      setState(() {
        _drink = drink;
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

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return HomeLoadError(onRetry: _load, message: kHangoutDrinkErrorCopy);
    }
    if (_loading || _drink == null) {
      return SafeArea(
        child: TeaSkeleton(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              Text(
                kHangoutDrinkLoadingCopy,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.chocolate,
                ),
              ),
              SizedBox(height: 20),
              TeaBone(height: 120),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 24, 32),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/social/friends/${widget.userId}');
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  _drink!.shop?.displayName ?? _drink!.teaName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: FriendDrinkCard(drink: _drink!),
          ),
        ],
      ),
    );
  }
}
