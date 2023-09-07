import 'dart:math';

import 'package:flutter/material.dart';

/// A ring with n_levels segments and a space inbetween.
class LevelRing extends StatefulWidget {
  final double minValue;

  final double maxValue;

  final double value;

  final int ringSeperators;

  /// The color of the circle.
  final Color iconColor;

  final Color ringColor;

  /// The icon to be displayed.
  final IconData? icon;

  /// The size of the ring. The icon size also depends on this value.
  final double ringSize;

  final bool showBorder;

  final Color background;

  final AnimationController? animationController;

  const LevelRing({
    Key? key,
    required this.ringColor,
    required this.iconColor,
    required this.icon,
    required this.ringSize,
    this.minValue = 0,
    this.maxValue = 0,
    this.value = 0,
    this.ringSeperators = 7,
    this.animationController,
    this.showBorder = true,
    this.background = Colors.transparent,
  }) : super(key: key);

  @override
  LevelRingState createState() => LevelRingState();
}

class LevelRingState extends State<LevelRing> {
  @override
  void initState() {
    widget.animationController?.addListener(() => setState(() {}));
    super.initState();
  }

  Animation<double> get ringAnimation => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: widget.animationController!,
        curve: Curves.easeIn,
      ));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: widget.showBorder ? Border.all(color: widget.background, width: 2) : null,
        color: widget.background,
        borderRadius: const BorderRadius.all(Radius.circular(48)),
      ),
      child: Column(children: [
        Stack(children: [
          SizedBox(
            width: widget.ringSize,
            height: widget.ringSize,
            child: AspectRatio(
              // Use 1.0 to ensure that the custom painter
              // will draw inside a container with width == height
              aspectRatio: 1.0,
              child: CustomPaint(
                painter: RingPainter(
                  color: widget.ringColor,
                  brightness: Theme.of(context).brightness,
                  threshold: widget.animationController == null ? 1 : ringAnimation.value,
                  curValue: widget.value,
                  minValue: widget.minValue,
                  maxValue: widget.maxValue,
                  seperators: widget.ringSeperators,
                ),
              ),
            ),
          ),
          SizedBox(
            width: widget.ringSize,
            height: widget.ringSize,
            child: Center(
              child: Icon(widget.icon, size: widget.ringSize * 0.5, color: widget.iconColor),
            ),
          ),
        ]),
      ]),
    );
  }
}

class RingPainter extends CustomPainter {
  RingPainter({
    required this.color,
    required this.minValue,
    required this.maxValue,
    required this.curValue,
    required this.seperators,
    required this.brightness,
    required this.threshold,
  });

  final Color color;
  final double minValue;
  final double maxValue;
  final double curValue;
  final int seperators;
  final Brightness brightness;
  final double threshold;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width / 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paddingBetweenSegments = 0.3 * pi / seperators;
    final ringLimit = (pi / 2) + (2 * pi) * threshold + paddingBetweenSegments;

    for (var i = 0; i < seperators; i++) {
      var segmentValueBorder = minValue + (maxValue - minValue) / seperators * (i + 1);
      // Start angle is at 6 o'clock and goes clockwise.
      final endAngle = (pi / 2) + (2 * pi) * (i / seperators) + paddingBetweenSegments;
      final startAngle = (pi / 2) + (2 * pi) * ((i + 1) / seperators) - paddingBetweenSegments;
      // If the brightness is light, darken the color. Otherwise, lighten it.
      final hslColor = curValue >= segmentValueBorder
          ? HSLColor.fromColor(color)
          : brightness == Brightness.light
              ? HSLColor.fromColor(Colors.black).withAlpha(0.05 + (i / seperators) * 0.05)
              : HSLColor.fromColor(Colors.white).withAlpha(0.1 + (i / seperators) * 0.05);
      final foregroundPaint = Paint()
        ..isAntiAlias = true
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = hslColor.toColor()
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        min(ringLimit, startAngle),
        (endAngle - min(ringLimit, startAngle)), // Clockwise.
        false,
        foregroundPaint,
      );
      if (startAngle > ringLimit) return;
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) => true;
}
