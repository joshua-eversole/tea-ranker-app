import 'package:flutter/material.dart';

import '../grading/grade.dart';
import '../theme/tokens.dart';

class GradeCircle extends StatelessWidget {
  const GradeCircle({
    super.key,
    required this.mark,
    required this.size,
  });

  final String mark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = colorsForMark(mark);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.$1,
        shape: BoxShape.circle,
      ),
      child: Text(
        mark,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
          color: colors.$2,
          height: 1,
        ),
      ),
    );
  }
}

class GradeOrDash extends StatelessWidget {
  const GradeOrDash({super.key, required this.band, required this.size});

  final AggregateBand? band;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (band == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            '—',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              fontSize: size * 0.4,
              color: AppColors.chocolate,
            ),
          ),
        ),
      );
    }
    return GradeCircle(mark: band!.label, size: size);
  }
}
