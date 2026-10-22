import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 0–100 slider in 10% steps. Track tint strengthens with the value:
/// sugar → red, ice → blue. 0 is almost untinted seed; 100 is the strong hue.
class PercentGradientSlider extends StatelessWidget {
  const PercentGradientSlider({
    super.key,
    required this.label,
    required this.value,
    required this.strongColor,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
  });

  final String label;
  final double value;
  final Color strongColor;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = (value / 100).clamp(0.0, 1.0);
    final thumb = Color.lerp(AppColors.seed, strongColor, 0.25 + 0.75 * t)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label  ${value.round()}%'),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            thumbColor: thumb,
            overlayColor: strongColor.withValues(alpha: 0.12),
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
            trackShape: StrengthGradientTrackShape(strongColor: strongColor),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 10,
            label: '${value.round()}%',
            onChanged: enabled ? onChanged : null,
            onChangeEnd: enabled ? onChangeEnd : null,
          ),
        ),
      ],
    );
  }
}

class StrengthGradientTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const StrengthGradientTrackShape({required this.strongColor});

  final Color strongColor;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (rect.width <= 0) return;

    final radius = Radius.circular(rect.height / 2);
    final canvas = context.canvas;
    final fraction =
        ((thumbCenter.dx - rect.left) / rect.width).clamp(0.0, 1.0);

    final inactive = Paint()..color = AppColors.seed;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), inactive);

    if (fraction <= 0) return;

    final activeRect = Rect.fromLTRB(
      rect.left,
      rect.top,
      thumbCenter.dx,
      rect.bottom,
    );
    final start = Color.lerp(AppColors.seed, strongColor, 0.08 + 0.22 * fraction)!;
    final end = Color.lerp(AppColors.seed, strongColor, 0.35 + 0.65 * fraction)!;
    final paint = Paint()
      ..shader = LinearGradient(colors: [start, end]).createShader(activeRect);
    canvas.drawRRect(RRect.fromRectAndRadius(activeRect, radius), paint);
  }
}
