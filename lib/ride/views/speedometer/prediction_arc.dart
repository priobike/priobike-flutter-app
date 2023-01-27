import 'dart:math';

import 'package:flutter/material.dart';

class SpeedometerPredictionArcPainter extends CustomPainter {
  final double minSpeed;
  final double maxSpeed;
  final List<Color> colors;
  final List<double> stops;
  bool isDark;

  SpeedometerPredictionArcPainter({
    required this.minSpeed,
    required this.maxSpeed,
    required this.colors,
    required this.stops,
    required this.isDark,
  });

  void paintPrediction(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
    const angle = startAngle + (endAngle - startAngle);
    const sweepAngle = angle - startAngle;
    final radius = size.width / 2 - 52;
    final rect = Rect.fromCircle(center: center, radius: radius);
    () {
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: (endAngle - startAngle),
          tileMode: TileMode.mirror,
          colors: colors,
          stops: stops,
          transform: const GradientRotation(startAngle),
        ).createShader(rect)
        ..strokeWidth = 18
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0)
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }();
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintPrediction(canvas, size);
  }

  @override
  bool shouldRepaint(covariant SpeedometerPredictionArcPainter oldDelegate) => oldDelegate.isDark != isDark;
}
