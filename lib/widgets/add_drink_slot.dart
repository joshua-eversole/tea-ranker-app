import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum AddSlotState { idle, pressed, watching }

/// Mascot-ready Add Drink control. Keep the circular + as the slot child,
/// not as extra layout math in the shell (slot is [AppLayout.addSlotSize]).
class AddDrinkSlot extends StatefulWidget {
  const AddDrinkSlot({
    super.key,
    required this.state,
    required this.onPressed,
  });

  final AddSlotState state;
  final VoidCallback onPressed;

  @override
  State<AddDrinkSlot> createState() => _AddDrinkSlotState();
}

class _AddDrinkSlotState extends State<AddDrinkSlot> {
  static const _press = Duration(milliseconds: 180);
  bool _pressing = false;

  Future<void> _handleTap() async {
    setState(() => _pressing = true);
    await Future<void>.delayed(_press);
    if (!mounted) return;
    setState(() => _pressing = false);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final watching = widget.state == AddSlotState.watching;
    final pressed = widget.state == AddSlotState.pressed || _pressing;
    final scale = watching
        ? 1.08
        : pressed
            ? 1.12
            : 1.0;
    final fill = watching ? AppColors.bobaWatching : AppColors.boba;

    return Semantics(
      button: true,
      label: 'Add drink',
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedScale(
          scale: scale,
          duration: _press,
          curve: Curves.easeOut,
          child: Container(
            width: AppLayout.addSlotSize,
            height: AppLayout.addSlotSize,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.boba.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}
