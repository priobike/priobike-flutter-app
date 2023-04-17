import 'dart:math';

import 'package:flutter/material.dart';

class SpeedometerBackgroundPainter extends CustomPainter {
  bool isDark;

  SpeedometerBackgroundPainter({
    required this.isDark,
  });

  void paintPredictionArcBackground(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
    const angle = startAngle + (endAngle - startAngle);
    const sweepAngle = angle - startAngle;
    final radius = size.width / 2 - 32;
    final rect = Rect.fromCircle(center: center, radius: radius);
    () {
      final paint = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..strokeWidth = 32
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }();
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintPredictionArcBackground(canvas, size);
  }

  @override
  bool shouldRepaint(covariant SpeedometerBackgroundPainter oldDelegate) => oldDelegate.isDark != isDark;
}
