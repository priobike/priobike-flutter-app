import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/models.dart';

class LevelView extends StatelessWidget {
  /// The levels to display.
  final List<Level> levels;

  /// The current value.
  final double value;

  /// The icon to be displayed.
  final IconData icon;

  /// The unit of the value.
  final String unit;

  const LevelView({
    Key? key,
    required this.levels,
    required this.value,
    required this.icon,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return Container();
    }
    var currentLevel = levels.first;
    for (var level in levels) {
      if (level.value <= value) {
        currentLevel = level;
      } else {
        break;
      }
    }
    var nextLevel = levels.last;
    for (var level in levels.reversed) {
      if (level.value > value) {
        nextLevel = level;
      } else {
        break;
      }
    }
    final pointsToNextLevel = nextLevel.value - value;
    return Container(
      padding: const EdgeInsets.only(left: 2, right: 2, top: 2, bottom: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topCenter,
          colors: [
            HSLColor.fromColor(currentLevel.color).withLightness(0.8).toColor(),
            HSLColor.fromColor(currentLevel.color).withLightness(0.9).toColor(),
            HSLColor.fromColor(currentLevel.color).withLightness(0.7).toColor(),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: HSLColor.fromColor(currentLevel.color).withLightness(0.5).withAlpha(0.2).toColor(),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.all(Radius.circular(32)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: BoldSmall(
                    text: currentLevel.title,
                    context: context,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 100,
                  child: Small(
                    text: pointsToNextLevel > 0
                        ? "${(value * 10).round() / 10}/${nextLevel.value.round()} $unit"
                        : "Ziel erreicht!",
                    context: context,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          LevelRing(levels: levels, value: value, color: currentLevel.color, icon: icon),
        ],
      ),
    );
  }
}

/// A ring with n_levels segments and a space inbetween.
class LevelRing extends StatelessWidget {
  /// The levels to display.
  final List<Level> levels;

  /// The current value.
  final double value;

  /// The color of the circle.
  final Color color;

  /// The icon to be displayed.
  final IconData icon;

  const LevelRing({
    Key? key,
    required this.levels,
    required this.value,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.background,
          width: 2,
        ),
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(children: [
        Stack(children: [
          SizedBox(
            width: 42,
            height: 42,
            child: AspectRatio(
              // Use 1.0 to ensure that the custom painter
              // will draw inside a container with width == height
              aspectRatio: 1.0,
              child: CustomPaint(
                painter: RingPainter(levels: levels, value: value, brightness: brightness),
              ),
            ),
          ),
          SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              color: brightness == Brightness.light
                  ? HSLColor.fromColor(color).withLightness(0.5).toColor()
                  : HSLColor.fromColor(color).withLightness(0.7).toColor(),
            ),
          ),
        ]),
      ]),
    );
  }
}

class RingPainter extends CustomPainter {
  RingPainter({
    required this.levels,
    required this.value,
    required this.brightness,
  });

  final List<Level> levels;
  final double value;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width / 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paddingBetweenSegments = 0.3 * pi / levels.length;

    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      // Start angle is at 6 o'clock and goes clockwise.
      final endAngle = (pi / 2) + (2 * pi) * (i / levels.length) + paddingBetweenSegments;
      final startAngle = (pi / 2) + (2 * pi) * ((i + 1) / levels.length) - paddingBetweenSegments;
      // If the brightness is light, darken the color. Otherwise, lighten it.
      final hslColor = value >= levels[i].value
          ? HSLColor.fromColor(level.color)
          : brightness == Brightness.light
              ? HSLColor.fromColor(Colors.black).withAlpha(0.05 + (i / levels.length) * 0.05)
              : HSLColor.fromColor(Colors.white).withAlpha(0.1 + (i / levels.length) * 0.05);
      final foregroundPaint = Paint()
        ..isAntiAlias = true
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = hslColor.toColor()
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        (endAngle - startAngle), // Clockwise.
        false,
        foregroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) => true;
}
