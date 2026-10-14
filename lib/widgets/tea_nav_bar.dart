import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Evenly spaced Home / Map / Social / Profile pills.
///
/// Replaces `google_nav_bar`: expanding GButtons measured text on a later
/// frame, so first-load “Home” sat outside the black pill, leftover “om”
/// showed on the logger, and the selected tab shoved the other icons.
/// Each tab owns an equal [Expanded] slot. The Add slot stays a left
/// overhang and is not part of this row.
class TeaNavBar extends StatelessWidget {
  const TeaNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  /// `-1` when logger / shop details are open — icons only, no leftover label.
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const tabs = <(IconData, String)>[
    (Icons.home_rounded, 'Home'),
    (Icons.map_rounded, 'Map'),
    (Icons.groups_rounded, 'Social'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++)
          Expanded(
            child: _TeaNavTab(
              icon: tabs[i].$1,
              label: tabs[i].$2,
              selected: selectedIndex == i,
              onTap: () => onSelect(i),
            ),
          ),
      ],
    );
  }
}

class _TeaNavTab extends StatelessWidget {
  const _TeaNavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.chocolate;
    final pill = selected
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.boba,
                borderRadius: BorderRadius.all(Radius.circular(AppRadii.chip)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Icon(icon, size: 20, color: color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          height: AppLayout.barContentHeight,
          child: Center(child: pill),
        ),
      ),
    );
  }
}
