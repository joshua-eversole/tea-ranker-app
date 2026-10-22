import 'package:flutter/material.dart';

/// Cup + straw + pearls, drawn in the Home row-wash color.
class BobaCupIcon extends StatelessWidget {
  const BobaCupIcon({
    super.key,
    required this.color,
    required this.size,
    this.pearlColor,
  });

  final Color color;
  final Color? pearlColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BobaCupPainter(color: color, pearlColor: pearlColor ?? color),
      ),
    );
  }
}

class _BobaCupPainter extends CustomPainter {
  _BobaCupPainter({required this.color, required this.pearlColor});

  final Color color;
  final Color pearlColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final pearls = Paint()
      ..color = pearlColor
      ..style = PaintingStyle.fill;

    final straw = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.56, h * 0.04, w * 0.09, h * 0.38),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(straw, fill);

    final cup = Path()
      ..moveTo(w * 0.22, h * 0.34)
      ..lineTo(w * 0.78, h * 0.34)
      ..lineTo(w * 0.70, h * 0.90)
      ..quadraticBezierTo(w * 0.50, h * 0.98, w * 0.30, h * 0.90)
      ..close();
    canvas.drawPath(cup, fill);

    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.28, w * 0.64, h * 0.10),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(lid, fill);

    final r = w * 0.07;
    canvas.drawCircle(Offset(w * 0.40, h * 0.72), r, pearls);
    canvas.drawCircle(Offset(w * 0.54, h * 0.76), r, pearls);
    canvas.drawCircle(Offset(w * 0.46, h * 0.82), r * 0.85, pearls);
  }

  @override
  bool shouldRepaint(covariant _BobaCupPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pearlColor != pearlColor;
  }
}
