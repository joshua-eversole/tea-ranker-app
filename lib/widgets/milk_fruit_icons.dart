import 'package:flutter/material.dart';

/// Milk glass, drawn in the light wash color (Home no-logo boba treatment).
class MilkGlassIcon extends StatelessWidget {
  const MilkGlassIcon({
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
        painter: _MilkGlassPainter(
          color: color,
          pearlColor: pearlColor ?? color,
        ),
      ),
    );
  }
}

class _MilkGlassPainter extends CustomPainter {
  _MilkGlassPainter({required this.color, required this.pearlColor});

  final Color color;
  final Color pearlColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final inner = Paint()
      ..color = pearlColor
      ..style = PaintingStyle.fill;

    final glass = Path()
      ..moveTo(w * 0.28, h * 0.16)
      ..lineTo(w * 0.72, h * 0.16)
      ..lineTo(w * 0.66, h * 0.86)
      ..quadraticBezierTo(w * 0.50, h * 0.96, w * 0.34, h * 0.86)
      ..close();
    canvas.drawPath(glass, fill);

    final milk = Path()
      ..moveTo(w * 0.34, h * 0.32)
      ..lineTo(w * 0.66, h * 0.32)
      ..lineTo(w * 0.62, h * 0.80)
      ..quadraticBezierTo(w * 0.50, h * 0.88, w * 0.38, h * 0.80)
      ..close();
    canvas.drawPath(milk, inner);
  }

  @override
  bool shouldRepaint(covariant _MilkGlassPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pearlColor != pearlColor;
  }
}

/// Lemon/lime, same light-icon wash treatment.
class CitrusIcon extends StatelessWidget {
  const CitrusIcon({
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
        painter: _CitrusPainter(color: color, pearlColor: pearlColor ?? color),
      ),
    );
  }
}

class _CitrusPainter extends CustomPainter {
  _CitrusPainter({required this.color, required this.pearlColor});

  final Color color;
  final Color pearlColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final inner = Paint()
      ..color = pearlColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.50, h * 0.56), w * 0.34, fill);
    canvas.drawCircle(Offset(w * 0.50, h * 0.56), w * 0.18, inner);

    final leaf = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..quadraticBezierTo(w * 0.72, h * 0.18, w * 0.58, h * 0.34)
      ..quadraticBezierTo(w * 0.42, h * 0.22, w * 0.50, h * 0.10)
      ..close();
    canvas.drawPath(leaf, fill);
  }

  @override
  bool shouldRepaint(covariant _CitrusPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pearlColor != pearlColor;
  }
}

/// Tea leaf, drawn in the same light wash as the Milk/Fruit icons.
class TeaLeafIcon extends StatelessWidget {
  const TeaLeafIcon({
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
        painter: _TeaLeafPainter(color: color, pearlColor: pearlColor ?? color),
      ),
    );
  }
}

class _TeaLeafPainter extends CustomPainter {
  _TeaLeafPainter({required this.color, required this.pearlColor});

  final Color color;
  final Color pearlColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final inner = Paint()
      ..color = pearlColor
      ..style = PaintingStyle.fill;

    final leaf = Path()
      ..moveTo(w * 0.50, h * 0.08)
      ..quadraticBezierTo(w * 0.92, h * 0.32, w * 0.72, h * 0.86)
      ..quadraticBezierTo(w * 0.50, h * 0.98, w * 0.28, h * 0.86)
      ..quadraticBezierTo(w * 0.08, h * 0.32, w * 0.50, h * 0.08)
      ..close();
    canvas.drawPath(leaf, fill);

    final vein = Path()
      ..moveTo(w * 0.50, h * 0.22)
      ..quadraticBezierTo(w * 0.62, h * 0.48, w * 0.52, h * 0.82)
      ..quadraticBezierTo(w * 0.50, h * 0.88, w * 0.48, h * 0.82)
      ..quadraticBezierTo(w * 0.38, h * 0.48, w * 0.50, h * 0.22)
      ..close();
    canvas.drawPath(vein, inner);
  }

  @override
  bool shouldRepaint(covariant _TeaLeafPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pearlColor != pearlColor;
  }
}
