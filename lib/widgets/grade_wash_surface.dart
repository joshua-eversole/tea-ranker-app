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
  });

  final String? mark;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    );
    return Material(
      color: gradeWash(mark),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? child
          : InkWell(
              onTap: onTap,
              customBorder: shape,
              child: child,
            ),
    );
  }
}
