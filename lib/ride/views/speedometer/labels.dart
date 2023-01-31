import 'dart:math';

import 'package:flutter/material.dart';

class SpeedometerLabelsPainter extends CustomPainter {
  final double minSpeed;
  final double maxSpeed;

  SpeedometerLabelsPainter({
    required this.minSpeed,
    required this.maxSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -5 * pi / 4 + pi / 22;
    const endAngle = pi / 4 - pi / 22;
    // Paint speed labels.
    () {
      final radius = size.width / 2 + 8;
      final textStyle = TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );
      for (var i in [
        minSpeed,
        maxSpeed,
      ]) {
        final pct = (i - minSpeed) / (maxSpeed - minSpeed);
        final angle = startAngle + pct * (endAngle - startAngle);
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);
        final speed = minSpeed + pct * (maxSpeed - minSpeed);
        final speedText = speed.toStringAsFixed(0);
        final textSpan = TextSpan(
          text: speedText,
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final textWidth = textPainter.width;
        final textHeight = textPainter.height;
        final textX = x - textWidth / 2;
        final textY = y - textHeight / 2;
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }();
  }

  @override
  bool shouldRepaint(SpeedometerLabelsPainter oldDelegate) {
    return oldDelegate.minSpeed != minSpeed || oldDelegate.maxSpeed != maxSpeed;
  }
}
