import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';

class SpeedometerBackgroundPainter extends CustomPainter {
  bool isDark;

  SpeedometerBackgroundPainter({
    required this.isDark,
  });

  void paintSpeedArcBackground(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    () {
      final paint = Paint()
        ..color = isDark
            ? HSLColor.fromColor(CI.blue).withLightness(0.1).withAlpha(0.4).toColor()
            : Colors.black.withOpacity(0.4)
        ..strokeWidth = 21
        ..style = PaintingStyle.stroke;
      final radius = size.width / 2 - 32;
      final rect = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -5 * pi / 4;
      const endAngle = pi / 4;
      const angle = startAngle + (endAngle - startAngle);
      const sweepAngle = angle - startAngle;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }();
    () {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final radius = size.width / 2 - 12;
      final rect = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -7 * pi / 5;
      const endAngle = pi / 4;
      const angle = startAngle + (endAngle - startAngle);
      const sweepAngle = angle - startAngle;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }();
  }

  void paintPredictionArcBackground(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
    const angle = startAngle + (endAngle - startAngle);
    const sweepAngle = angle - startAngle;
    final radius = size.width / 2 - 52;
    final rect = Rect.fromCircle(center: center, radius: radius);
    () {
      final paint = Paint()
        ..color = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.4)
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }();
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintSpeedArcBackground(canvas, size);
    paintPredictionArcBackground(canvas, size);
  }

  @override
  bool shouldRepaint(covariant SpeedometerBackgroundPainter oldDelegate) => oldDelegate.isDark != isDark;
}
