import 'dart:math';

import 'package:flutter/material.dart';

/// A ring which displays the users progress for something, which can be animated and which can contain an icon.
class ProgressRing extends StatefulWidget {
  /// The progress displayed by the ring, as a level between 0 and 1.
  final double progress;

  /// The color of the level ring.
  final Color ringColor;

  /// The size of the ring. The icon size also depends on this value.
  final double ringSize;

  /// The widget to be displayed inside of the ring. 
  final Widget? content;

  /// Whether to show a border around the level ring.
  final bool showBorder;

  /// The color of the backround and border of the ring.
  final Color background;

  /// An animation controller animate the level ring.
  final AnimationController? animationController;

  const ProgressRing({
    Key? key,
    required this.ringColor,
    required this.ringSize,
    this.progress = 1,
    this.animationController,
    this.showBorder = true,
    this.background = Colors.transparent,
    this.content,
  }) : super(key: key);

  @override
  ProgressRingState createState() => ProgressRingState();
}

class ProgressRingState extends State<ProgressRing> {
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

  /// Update the state of the level ring. Called when the animation controller value changes.
  void update() => {if (mounted) setState(() {})};

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
                  backgroundColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                  radiusThreshold: widget.animationController == null
                      ? 1
                      : Tween<double>(begin: 0, end: 1)
                          .animate(CurvedAnimation(
                            parent: widget.animationController!,
                            curve: Curves.easeIn,
                          ))
                          .value,
                  progress: widget.progress,
                ),
              ),
            ),
          ),
          if (widget.content != null)
            SizedBox(
              width: widget.ringSize,
              height: widget.ringSize,
              child: Center(
                child: widget.content,
              ),
            ),
        ]),
      ]),
    );
  }
}

/// A painter which paints a simple ring in a certain color, displaying a given progress.
class SolidRingPainter extends CustomPainter {
  /// The color showing the current progress.
  final Color progressColor;

  /// The background color of the ring, which can be seen if the progress is not 1.
  final Color backgroundColor;

  /// The users progress as a value between 0 and 1.
  final double progress;

  /// What percentage of the ring should be shown.
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
