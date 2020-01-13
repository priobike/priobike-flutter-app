import 'package:flutter/material.dart';
import 'dart:math';

class SpeedSlider extends StatefulWidget {
  double value;
  double max = 10;
  double min = -10;

  SpeedSlider(double value) {
    if (value > max) {
      this.value = max;
    } else if (value < min) {
      this.value = min;
    } else {
      this.value = value;
    }
  }
  @override
  State<StatefulWidget> createState() {
    return SpeedSliderState();
  }
}

class SpeedSliderState extends State<SpeedSlider> {
  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 50,
        activeTrackColor: Colors.transparent,
        trackShape: RetroSliderTrackShape(),
        thumbColor: Colors.black,
        thumbShape: RetroSliderThumbShape(thumbRadius: 25),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 15.0),
      ),
      child: Slider(
        value: widget.value,
        max: widget.max,
        min: widget.min,
      ),
    );
  }
}

class RetroSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;

  const RetroSliderThumbShape({
    this.thumbRadius = 15.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    final Canvas canvas = context.canvas;

    final rect = Rect.fromCircle(center: center, radius: thumbRadius);

    final pathSegment = Path()
      ..moveTo(rect.centerLeft.dx, rect.centerLeft.dy)
      ..lineTo(rect.topCenter.dx, rect.topCenter.dy)
      ..lineTo(rect.centerRight.dx, rect.centerRight.dy)
      ..lineTo(rect.bottomCenter.dx, rect.bottomCenter.dy);

    final fillPaint = Paint()
      ..color = sliderTheme.thumbColor
      ..style = PaintingStyle.fill;

//    final borderPaint = Paint()
//      ..color = Colors.black
//      ..strokeWidth = 0
//      ..style = PaintingStyle.stroke;

    canvas.drawPath(pathSegment, fillPaint);
//    canvas.drawRRect(rrect, borderPaint);
  }
}

class RetroSliderTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    RenderBox parentBox,
    Offset offset = Offset.zero,
    SliderThemeData sliderTheme,
    bool isEnabled,
    bool isDiscrete,
  }) {
    final double thumbWidth =
        sliderTheme.thumbShape.getPreferredSize(true, isDiscrete).width;
    final double trackHeight = sliderTheme.trackHeight;
    assert(thumbWidth >= 0);
    assert(trackHeight >= 0);
    assert(parentBox.size.width >= thumbWidth);
    assert(parentBox.size.height >= trackHeight);

    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    TextDirection textDirection,
    Offset thumbCenter,
    bool isDiscrete,
    bool isEnabled,
  }) {
    if (sliderTheme.trackHeight == 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    var gradient = RadialGradient(
      center: Alignment.center, // near the top right
      radius: 4,
      colors: [
        const Color(0xFF388e3c),const Color(0xffffb300),
        const Color(0xfff4511e)
      ],
      stops: [0.1, 0.5, 1],
    );
    // rect is the area we are painting over
    final Paint fillPaint = Paint()
      ..shader = gradient.createShader(trackRect);

//    final Paint fillPaint = Paint()
//      ..color = sliderTheme.activeTrackColor
//      ..style = PaintingStyle.fill;

//    final Paint borderPaint = Paint()
//      ..color = Colors.black
//      ..strokeWidth = 0.0
//      ..style = PaintingStyle.stroke;

    final pathSegment = Path()
      ..moveTo(trackRect.left, trackRect.top)
      ..lineTo(trackRect.right, trackRect.top)
      ..arcTo(
          Rect.fromPoints(
            Offset(trackRect.right + 7, trackRect.top),
            Offset(trackRect.right - 7, trackRect.bottom),
          ),
          -pi / 2,
          pi,
          false)
      ..lineTo(trackRect.left, trackRect.bottom)
      ..arcTo(
          Rect.fromPoints(
            Offset(trackRect.left + 7, trackRect.top),
            Offset(trackRect.left - 7, trackRect.bottom),
          ),
          -pi * 3 / 2,
          pi,
          false);

    context.canvas.drawPath(pathSegment, fillPaint);
//    context.canvas.drawPath(pathSegment, borderPaint);
  }
}
