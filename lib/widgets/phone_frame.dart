import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Desktop stretch of the same phone-width UI.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cream,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
          child: child,
        ),
      ),
    );
  }
}
