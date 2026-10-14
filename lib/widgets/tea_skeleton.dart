import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Cream / seed pulse used on Home and shop-details loading.
class TeaSkeleton extends StatefulWidget {
  const TeaSkeleton({super.key, required this.child});

  final Widget child;

  @override
  State<TeaSkeleton> createState() => _TeaSkeletonState();
}

class _TeaSkeletonState extends State<TeaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.55 + (_controller.value * 0.45),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class TeaBone extends StatelessWidget {
  const TeaBone({
    super.key,
    this.height,
    this.width,
    this.circle = false,
  });

  final double? height;
  final double? width;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? (circle ? height : null),
      decoration: BoxDecoration(
        color: AppSurfaces.bone,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle
            ? null
            : BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.seed.withValues(alpha: 0.7)),
      ),
    );
  }
}
