import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/models.dart';

class LevelView extends StatefulWidget {
  /// The levels to display.
  final List<Level> levels;

  /// The current value.
  final double value;

  /// The icon to be displayed.
  final IconData icon;

  /// The unit of the value.
  final String unit;

  @override
  LevelViewState createState() => LevelViewState();

  const LevelView({
    Key? key,
    required this.levels,
    required this.value,
    required this.icon,
    required this.unit,
  }) : super(key: key);
}

class LevelViewState extends State<LevelView> {
  /// The color gradient of the level bar.
  late List<Color> colors;

  /// If the view is currently animating.
  bool animating = false;

  /// The percentage of the circular progress that hides the level circle.
  double circleCoverPct = 0;

  /// The current level.
  Level getCurrentLevel() {
    var currentLevel = widget.levels.first;
    for (var level in widget.levels) {
      if (level.value <= widget.value) {
        currentLevel = level;
      } else {
        break;
      }
    }
    return currentLevel;
  }

  /// The next level.
  Level getNextLevel() {
    var nextLevel = widget.levels.last;
    for (var level in widget.levels.reversed) {
      if (level.value > widget.value) {
        nextLevel = level;
      } else {
        break;
      }
    }
    return nextLevel;
  }

  /// Run the bling animation.
  Future<void> runAnimation({delay = 0}) async {
    if (animating) return;
    animating = true;
    await Future.delayed(Duration(milliseconds: delay));
    final currentLevel = getCurrentLevel();
    // Animate the circle cover.
    setState(() {
      circleCoverPct = 1;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        circleCoverPct = 0;
      });
    });
    // Make a nice "bling" gradient animation.
    for (var i = 0.0; i <= pi * 2; i += pi / 4) {
      await Future.delayed(const Duration(milliseconds: 200), () {
        setState(() {
          colors = [
            HSLColor.fromColor(currentLevel.color).withLightness(max(0, min(1, 0.9 + 0.1 * cos(i + pi)))).toColor(),
            HSLColor.fromColor(currentLevel.color).withLightness(max(0, min(1, 0.8 + 0.1 * sin(i + pi / 3)))).toColor(),
            HSLColor.fromColor(currentLevel.color).withLightness(max(0, min(1, 0.7 + 0.1 * cos(i + pi / 4)))).toColor(),
          ];
        });
      });
    }
    animating = false;
  }

  @override
  void initState() {
    super.initState();
    final currentLevel = getCurrentLevel();
    colors = [
      HSLColor.fromColor(currentLevel.color).withLightness(0.7).toColor(),
      HSLColor.fromColor(currentLevel.color).withLightness(0.9).toColor(),
      HSLColor.fromColor(currentLevel.color).withLightness(0.8).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.levels.isEmpty) return Container();
    final currentLevel = getCurrentLevel();
    final nextLevel = getNextLevel();
    final pointsToNextLevel = nextLevel.value - widget.value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        runAnimation();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
        padding: const EdgeInsets.only(left: 2, right: 2, top: 2, bottom: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topCenter,
            colors: colors,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          ? "${(widget.value * 10).round() / 10}/${nextLevel.value.round()} ${widget.unit}"
                          : "Ziel erreicht!",
                      context: context,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                LevelRing(levels: widget.levels, value: widget.value, color: currentLevel.color, icon: widget.icon),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOutCubicEmphasized,
                  tween: Tween<double>(
                    begin: 0,
                    end: circleCoverPct,
                  ),
                  builder: (context, value, _) => Transform(
                    // Rotate by 180° to make the animation start at the bottom.
                    // Flip the animation by multiplying with -1.
                    transform: Matrix4.diagonal3Values(1, -1, 1),
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      strokeWidth: 8,
                      value: value,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.background),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A ring with n_levels segments and a space inbetween.
class LevelRing extends StatefulWidget {
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
  LevelRingState createState() => LevelRingState();
}

class LevelRingState extends State<LevelRing> {
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
                painter: RingPainter(levels: widget.levels, value: widget.value, brightness: brightness),
              ),
            ),
          ),
          SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              widget.icon,
              color: brightness == Brightness.light
                  ? HSLColor.fromColor(widget.color).withLightness(0.5).toColor()
                  : HSLColor.fromColor(widget.color).withLightness(0.7).toColor(),
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
