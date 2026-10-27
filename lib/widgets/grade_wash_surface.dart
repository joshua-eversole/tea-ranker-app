import 'package:flutter/material.dart';

import '../grading/grade.dart';
import '../theme/tokens.dart';

/// Flat 24px row: no border, no elevation, cream mixed with the grade fill.
class GradeWashSurface extends StatelessWidget {
  const GradeWashSurface({
    super.key,
    required this.mark,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.wash,
  });

  final String? mark;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Overrides grade wash (Home logo tint). Visit cards never pass this.
  final Color? wash;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    );
    return Material(
      color: wash ?? gradeWash(mark),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null && onLongPress == null
          ? child
          : InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              customBorder: shape,
              child: child,
            ),
    );
  }
}
