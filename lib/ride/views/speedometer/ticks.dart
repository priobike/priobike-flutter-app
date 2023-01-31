import 'dart:math';

import 'package:flutter/material.dart';

class SpeedometerTicksPainter extends CustomPainter {
  final double minSpeed;
  final double maxSpeed;

  SpeedometerTicksPainter({
    required this.minSpeed,
    required this.maxSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the number of ticks.
    final ticks = (maxSpeed - minSpeed) ~/ 5;

    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
    () {
      final radius = size.width / 2 - 12;
      final paint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 0; i <= ticks; i++) {
        final pct = i / ticks;
        final angle = startAngle + pct * (endAngle - startAngle);
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);
        final x2 = center.dx + (radius - 6) * cos(angle);
        final y2 = center.dy + (radius - 6) * sin(angle);
        canvas.drawLine(Offset(x, y), Offset(x2, y2), paint);
      }
    }();
    () {
      final radius = size.width / 2 - 12;
      final paint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 0; i <= ticks; i++) {
        final pct = i / ticks;
        final angle = startAngle + pct * (endAngle - startAngle);
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);
        final x2 = center.dx + (radius - 6) * cos(angle);
        final y2 = center.dy + (radius - 6) * sin(angle);
        canvas.drawLine(Offset(x, y), Offset(x2, y2), paint);
      }
    }();
    () {
      final radius = size.width / 2 - 14;
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 0; i <= ticks * 10; i++) {
        final pct = i / (ticks * 10);
        final angle = startAngle + pct * (endAngle - startAngle);
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);
        final x2 = center.dx + (radius - 3) * cos(angle);
        final y2 = center.dy + (radius - 3) * sin(angle);
        canvas.drawLine(Offset(x, y), Offset(x2, y2), paint);
      }
    }();
  }

  @override
  bool shouldRepaint(covariant SpeedometerTicksPainter oldDelegate) => false;
}
