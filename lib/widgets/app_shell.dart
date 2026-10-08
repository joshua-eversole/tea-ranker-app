import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../theme/tokens.dart';
import 'add_drink_slot.dart';
import 'phone_frame.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  int get _tabIndex {
    if (location.startsWith('/social')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  AddSlotState get _slotState {
    if (location == '/log' || location.startsWith('/log')) {
      return AddSlotState.watching;
    }
    return AddSlotState.idle;
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
                child: child,
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
                        const SizedBox(width: AppLayout.addSlotSize + 24),
                        Expanded(
                          child: GNav(
                            selectedIndex: _tabIndex,
                            onTabChange: (i) {
                              switch (i) {
                                case 0:
                                  context.go('/');
                                case 1:
                                  context.go('/social');
                                case 2:
                                  context.go('/profile');
                              }
                            },
                            gap: 6,
                            iconSize: 20,
                            color: AppColors.chocolate,
                            activeColor: Colors.white,
                            tabBackgroundColor: AppColors.boba,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            duration: const Duration(milliseconds: 280),
                            tabs: const [
                              GButton(icon: Icons.home_rounded, text: 'Home'),
                              GButton(icon: Icons.groups_rounded, text: 'Social'),
                              GButton(
                                icon: Icons.person_rounded,
                                text: 'Profile',
                              ),
                            ],
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
