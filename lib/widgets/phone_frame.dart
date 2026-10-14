import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Fill the viewport on phones; cap only on wide desktop.
double framedContentWidth(double viewportWidth) {
  if (viewportWidth <= AppLayout.phoneFillBreakpoint) return viewportWidth;
  return AppLayout.maxContentWidth;
}

/// Desktop stretch of the same phone-width UI.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width;
    final maxWidth = framedContentWidth(viewport);
    return ColoredBox(
      color: AppColors.cream,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}
