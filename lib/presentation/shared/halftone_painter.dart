import 'package:flutter/material.dart';

/// Paints a faint halftone dot grid. Used behind headers and on loud surfaces.
/// Opacity 0.03-0.06 for headers; loud surfaces may push higher.
class HalftonePainter extends CustomPainter {
  final double dotRadius;
  final double spacing;
  final double opacity;

  const HalftonePainter({
    this.dotRadius = 1.2,
    this.spacing = 8.0,
    this.opacity = 0.04,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, opacity)
      ..style = PaintingStyle.fill;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(HalftonePainter oldDelegate) =>
      oldDelegate.dotRadius != dotRadius ||
      oldDelegate.spacing != spacing ||
      oldDelegate.opacity != opacity;
}
