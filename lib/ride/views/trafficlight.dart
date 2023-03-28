import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride.dart';

class RideTrafficLightView extends StatefulWidget {
  const RideTrafficLightView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideTrafficLightViewState();
}

class RideTrafficLightViewState extends State<RideTrafficLightView> {
  /// The associated ride service, which is injected by the provider.
  late Ride ride;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    ride = getIt<Ride>();
    ride.addListener(update);
  }

  @override
  void dispose() {
    ride.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = 120.0;
    return Stack(
      children: [
        // RIGHT BUTTON
        Transform.translate(
          offset: const Offset(radius * 0.75, 0),
          child: Transform.rotate(
            angle: -pi / 4,
            child: CenterButton(
              radius: radius,
              gradient: const LinearGradient(
                colors: [CI.blue, Colors.white],
                stops: [0.4, 1.0],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              onPressed: () => print("test"),
            ),
          ),
        ),
        // BOTTOM BUTTON
        Transform.translate(
          offset: const Offset(0, radius * 0.75),
          child: Transform.rotate(
            angle: pi / 4,
            child: CenterButton(
              radius: radius,
              gradient: const LinearGradient(
                colors: [CI.blue, Colors.white],
                stops: [0.4, 1.0],
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
              ),
              onPressed: () => print("test"),
            ),
          ),
        ),
        // LEFT BUTTON
        Transform.translate(
          offset: const Offset(-radius * 0.75, 0),
          child: Transform.rotate(
            angle: 3 * (pi / 4),
            child: CenterButton(
              radius: radius,
              gradient: const LinearGradient(
                colors: [CI.blue, Colors.white],
                stops: [0.4, 1.0],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              onPressed: () => print("test"),
            ),
          ),
        ),
        // TOP BUTTON
        Transform.translate(
          offset: const Offset(0, -radius * 0.75),
          child: Transform.rotate(
            angle: -3 * (pi / 4),
            child: CenterButton(
              radius: radius,
              gradient: const LinearGradient(
                colors: [CI.blue, Colors.white],
                stops: [0.4, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPressed: () => print("test"),
            ),
          ),
        ),
      ],
    );
  }
}

class CenterButton extends StatelessWidget {
  final double radius;
  final LinearGradient gradient;
  final Function onPressed;
  const CenterButton({Key? key, required this.radius, required this.onPressed, required this.gradient})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => onPressed,
        child: CustomPaint(
          size: Size(radius, radius),
          painter: CenterButtonPainter(
            gradient: gradient,
          ),
        ));
  }
}

class CenterButtonPainter extends CustomPainter {
  final LinearGradient gradient;

  CenterButtonPainter({required this.gradient});

  void drawButtonShadow(Canvas canvas, Size size, Path path) {
    final paint = Paint()
      ..color = CI.blue
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawPath(path, paint);
  }

  void drawButton(Canvas canvas, Size size, Path path) {
    final paint = Paint()..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: size.width));
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final holeRadius = size.width / 2;
    final outerRadius = size.width;

    final borderRadius = 5.0;

    path.lineTo(0, holeRadius - borderRadius);
    path.arcToPoint(
      Offset(borderRadius, holeRadius),
      radius: Radius.circular(borderRadius),
      clockwise: true,
    );
    path.arcToPoint(
      Offset(holeRadius - borderRadius, 0),
      radius: Radius.circular(holeRadius),
      clockwise: false,
    );

    path.lineTo(holeRadius, 0);
    path.lineTo(size.width, 0);

    path.arcToPoint(
      Offset(0, size.height),
      radius: Radius.circular(outerRadius),
      clockwise: true,
    );

    drawButtonShadow(canvas, size, path);
    drawButton(canvas, size, path);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
