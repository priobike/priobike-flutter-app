import 'dart:math';

import 'package:flutter/material.dart';

/// A ring with n_levels segments and a space inbetween.
class LevelRing extends StatefulWidget {
  final double progress;

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
    required this.ringSize,
    required this.ringColor,
    this.iconColor = Colors.transparent,
    this.icon,
    this.progress = 1,
    this.animationController,
    this.showBorder = true,
    this.background = Colors.transparent,
  }) : super(key: key);

  @override
  LevelRingState createState() => LevelRingState();
}

class LevelRingState extends State<LevelRing> {
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    widget.animationController?.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    widget.animationController?.removeListener(update);
    super.dispose();
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
              aspectRatio: 1.0,
              child: CustomPaint(
                painter: SolidRingPainter(
                  progressColor: widget.ringColor,
                  backgroundColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                  radiusThreshold: widget.animationController == null ? 1 : ringAnimation.value,
                  progress: widget.progress,
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

class SolidRingPainter extends CustomPainter {
  final Color progressColor;
  final Color backgroundColor;
  final double progress;
  final double radiusThreshold;

  SolidRingPainter({
    required this.progressColor,
    required this.backgroundColor,
    required this.radiusThreshold,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width / 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final thresholdRadius = radiusThreshold * (2 * pi);
    final progressRadius = progress * (2 * pi);
    final backgroundRadius = (2 * pi) - progressRadius;
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    paint.color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi / 2,
      min(progressRadius, thresholdRadius),
      false,
      paint,
    );

    if (thresholdRadius > progressRadius) {
      paint.color = backgroundColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi / 2 + progressRadius,
        min(backgroundRadius, thresholdRadius - progressRadius),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SolidRingPainter oldDelegate) => true;
}
