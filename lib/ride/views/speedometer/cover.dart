import 'dart:math';

import 'package:flutter/material.dart';

class SpeedometerCoverPainter extends CustomPainter {
  SpeedometerCoverPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 64
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const startAngle = -5 * pi / 4;
    const endAngle = -7 * pi / 4;
    const angle = startAngle + (endAngle - startAngle);
    const sweepAngle = angle - startAngle;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant SpeedometerCoverPainter oldDelegate) => false;
}
