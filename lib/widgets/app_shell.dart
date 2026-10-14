import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import 'add_drink_slot.dart';
import 'phone_frame.dart';
import 'tea_nav_bar.dart';

/// Home is selected only on `/`. Logger and shop details leave pills idle
/// so tapping Home still navigates (GNav skips `onTabChange` when already selected).
int shellTabIndex(String location) {
  if (location == '/' || location.isEmpty) return 0;
  if (location.startsWith('/map')) return 1;
  if (location.startsWith('/social')) return 2;
  if (location.startsWith('/profile')) return 3;
  return -1;
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  int get _tabIndex => shellTabIndex(location);

  AddSlotState get _slotState {
    if (location == '/log' || location.startsWith('/log')) {
      return AddSlotState.watching;
    }
    return AddSlotState.idle;
  }

  void _onTabChange(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go('/');
      case 1:
        context.go('/map');
      case 2:
        context.go('/social');
      case 3:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barBlock = AppLayout.barContentHeight + bottomInset;

    return PhoneFrame(
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(bottom: barBlock),
                child: ClipRect(child: child),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                color: AppColors.seed,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: SizedBox(
                    height: AppLayout.barContentHeight,
                    child: Row(
                      children: [
                        // Add + overhangs from the left; this spacer keeps
                        // Home in its equal quarter and is not a fifth tab.
                        const SizedBox(width: AppLayout.addSlotSize + 8),
                        Expanded(
                          child: TeaNavBar(
                            selectedIndex: _tabIndex,
                            onSelect: (i) => _onTabChange(context, i),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              // Bottom of the 64px slot sits on the bar (above the home
              // indicator). The extra 12px is the specified overhang.
              bottom: bottomInset,
              child: AddDrinkSlot(
                state: _slotState,
                onPressed: () {
                  if (location != '/log') {
                    context.push('/log');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
