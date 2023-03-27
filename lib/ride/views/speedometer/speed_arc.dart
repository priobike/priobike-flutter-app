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

  void paintSpeedArcGlow(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 32;
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
    final pct = (speed - minSpeed) / (maxSpeed - minSpeed);
    final sweepAngle = pct * (endAngle - startAngle);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..color = CI.blue
      ..strokeWidth = 60
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1)
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, sweepAngle + startAngle - 0.05, 0.1, false, paint);
  }

  void paintSpeedArc(Canvas canvas, Size size) {
    // Scale the opacity of the glow based on the speed.
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 32;
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
    final pct = (speed - minSpeed) / (maxSpeed - minSpeed);
    final angle = startAngle + pct * (endAngle - startAngle);
    final sweepAngle = angle - startAngle;
    () {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(1),
          ],
          radius: 0.6,
        ).createShader(rect)
        ..strokeWidth = 55
        ..strokeCap = StrokeCap.butt
        ..blendMode = BlendMode.srcATop
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, sweepAngle + startAngle - 0.035, 0.07, false, paint);
    }();
  }

  void paintSpeedArcFlowGlow(Canvas canvas, Size size) {
    // Scale the opacity of the glow based on the speed.
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 32;
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

  @override
  void paint(Canvas canvas, Size size) {
    paintSpeedArcFlowGlow(canvas, size);
    paintSpeedArcGlow(canvas, size);
    paintSpeedArc(canvas, size);
  }

  @override
  bool shouldRepaint(covariant SpeedometerSpeedArcPainter oldDelegate) =>
      oldDelegate.speed != speed || oldDelegate.isDark != isDark;
}
