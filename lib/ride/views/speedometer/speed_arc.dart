import 'dart:math';

import 'package:flutter/material.dart';

class SpeedometerSpeedArcPainter extends CustomPainter {
  final double pct;
  final double lastPct;
  final bool isDark;
  final bool batterySaveMode;

  SpeedometerSpeedArcPainter({
    required pct,
    required this.lastPct,
    required this.isDark,
    required this.batterySaveMode,
  }) : pct = pct == 0 ? 0.001 : pct;

  /// Paints the tail of the pointer
  void paintSpeedArcTail(Canvas canvas, Size size) {
    // Scale the opacity of the glow based on the speed.
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 32;
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
    final angle = startAngle + pct * (endAngle - startAngle);
    var sweepAngle = angle - startAngle;

    () {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: pct * (endAngle - startAngle),
          tileMode: TileMode.mirror,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.2),
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

  void paintSpeedArcTailBatterySave(Canvas canvas, Size size) {
    if (pct == lastPct) return;
    // Scale the opacity of the glow based on the speed.
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 32;
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;

    final angle = startAngle + pct * (endAngle - startAngle);
    final lastAngle = startAngle + lastPct * (endAngle - startAngle);

    final colors = [
      Colors.white.withOpacity(0.0),
      Colors.white.withOpacity(0.0),
      angle < lastAngle ? Colors.white.withOpacity(isDark ? 0.6 : 0.8) : Colors.white.withOpacity(0),
      angle < lastAngle ? Colors.white.withOpacity(0) : Colors.white.withOpacity(isDark ? 0.6 : 0.8),
      Colors.white.withOpacity(0.0),
      Colors.white.withOpacity(0.0)
    ];

    // The used part of the speedometer arc in percentage.
    // Used to adjust the percentage values.
    const diff = 0.75;

    // Calculate borders for the sweep gradient.
    final minBorder = pct < lastPct ? (pct - 0.001) * diff : (lastPct - 0.001) * diff;
    final min = pct < lastPct ? (pct) * diff : (lastPct) * diff;
    final max = pct > lastPct ? (pct) * diff : (lastPct) * diff;
    final maxBorder = pct > lastPct ? (pct + 0.001) * diff : (lastPct + 0.001) * diff;

    () {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = SweepGradient(
          tileMode: TileMode.clamp,
          colors: colors,
          stops: [0, minBorder, min, max, maxBorder, 1],
          transform: const GradientRotation(startAngle),
        ).createShader(rect)
        ..strokeWidth = 55
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, endAngle - startAngle, false, paint);
    }();
  }

  /// Paints the inner part of the pointer.
  void paintSpeedPointer(Canvas canvas, Size size) {
    const double rectangleHeight = 56;
    const double rectangleWidth = 14;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 32;
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
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
      const Radius.circular(8),
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

  /// Paints the blurry background of the pointer.
  void paintSpeedPointerBackground(Canvas canvas, Size size) {
    const double rectangleHeight = 60;
    const double rectangleWidth = 17;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 32;
    const startAngle = -5 * pi / 4;
    const endAngle = pi / 4;
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
      const Radius.circular(8),
    );

    final paint = Paint()
      ..color = Colors.grey
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    canvas.drawRRect(
      rect,
      paint,
    );

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    batterySaveMode ? paintSpeedArcTailBatterySave(canvas, size) : paintSpeedArcTail(canvas, size);
    paintSpeedPointerBackground(canvas, size);
    paintSpeedPointer(canvas, size);
  }

  @override
  bool shouldRepaint(covariant SpeedometerSpeedArcPainter oldDelegate) =>
      oldDelegate.pct != pct || oldDelegate.lastPct != lastPct || oldDelegate.isDark != isDark;
}
