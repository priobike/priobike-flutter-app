import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';

class SpeedometerSpeedArcPainter extends CustomPainter {
  final double minSpeed;
  final double maxSpeed;
  final double speed;
  final bool isDark;

  SpeedometerSpeedArcPainter({
    required this.minSpeed,
    required this.maxSpeed,
    required speed,
    required this.isDark,
  }) : speed = speed.clamp(
          minSpeed + 0.01, // Always show a little bit of the arc.
          maxSpeed,
        );

  void paintSpeedArcFlowGlow(Canvas canvas, Size size) {
    // Scale the opacity of the glow based on the speed.
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 34;
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
    final pct = (speed - minSpeed) / (maxSpeed - minSpeed);
    final angle = startAngle + pct * (endAngle - startAngle);
    final sweepAngle = angle - startAngle;
    () {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: pct * (endAngle - startAngle),
          tileMode: TileMode.mirror,
          colors: [
            Colors.white.withOpacity(0.0),
            CI.blue.withOpacity(0.2),
          ],
          stops: const [0.75, 1.0],
          transform: const GradientRotation(startAngle),
        ).createShader(rect)
        ..strokeWidth = 60
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1)
        ..strokeCap = StrokeCap.butt
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle - 0.03, sweepAngle, false, paint);
    }();
  }

  void paintSpeedPointer(Canvas canvas, Size size) {
    const double rectangleHeight = 56;
    const double rectangleWidth = 14;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 34;
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
    final pct = (speed - minSpeed) / (maxSpeed - minSpeed);
    final angle = startAngle + pct * (endAngle - startAngle);

    final Offset rectanglePosition = Offset(
      center.dx + radius * cos(angle) - rectangleHeight / 2,
      center.dy + radius * sin(angle) - rectangleWidth / 2,
    );

    canvas.save();
    canvas.translate(rectanglePosition.dx + rectangleHeight / 2, rectanglePosition.dy + rectangleWidth / 2);
    canvas.rotate(angle);
    canvas.translate(-rectangleHeight / 2, -rectangleWidth / 2);

    final rect = RRect.fromLTRBR(
      0,
      0,
      rectangleHeight,
      rectangleWidth,
      const Radius.circular(2),
    );

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect.middleRect);

    canvas.drawRRect(
      rect,
      paint,
    );

    canvas.restore();
  }

  void paintSpeedPointerBackground(Canvas canvas, Size size) {
    const double rectangleHeight = 60;
    const double rectangleWidth = 17;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 34;
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
    final pct = (speed - minSpeed) / (maxSpeed - minSpeed);
    final angle = startAngle + pct * (endAngle - startAngle);

    final Offset rectanglePosition = Offset(
      center.dx + radius * cos(angle) - rectangleHeight / 2,
      center.dy + radius * sin(angle) - rectangleWidth / 2,
    );

    canvas.save();
    canvas.translate(rectanglePosition.dx + rectangleHeight / 2, rectanglePosition.dy + rectangleWidth / 2);
    canvas.rotate(angle);
    canvas.translate(-rectangleHeight / 2, -rectangleWidth / 2);

    final rect = RRect.fromLTRBR(
      0,
      0,
      rectangleHeight,
      rectangleWidth,
      const Radius.circular(4),
    );

    final paint = Paint()
      ..color = CI.blue
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    canvas.drawRRect(
      rect,
      paint,
    );

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintSpeedArcFlowGlow(canvas, size);
    paintSpeedPointerBackground(canvas, size);
    paintSpeedPointer(canvas, size);
  }

  @override
  bool shouldRepaint(covariant SpeedometerSpeedArcPainter oldDelegate) =>
      oldDelegate.speed != speed || oldDelegate.isDark != isDark;
}
