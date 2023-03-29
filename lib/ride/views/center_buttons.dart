import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride.dart';

class RideCenterButtonsView extends StatefulWidget {
  /// A callback that is called when the danger button is tapped.
  final Function onTapDanger;

  const RideCenterButtonsView({Key? key, required this.onTapDanger}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideCenterButtonsViewState();
}

class RideCenterButtonsViewState extends State<RideCenterButtonsView> {
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
    final colors = [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary];
    final stops = [0.0, 0.8];
    const radius = 120.0;

    final signalGroupsAvailable = ride.route?.signalGroups != null && ride.route!.signalGroups.isNotEmpty;

    return SizedBox(
      width: 2 * radius,
      height: 2 * radius,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // RIGHT BUTTON
          if (signalGroupsAvailable)
            Transform.translate(
              offset: const Offset(radius * 0.75, 0),
              child: CenterButton(
                radius: radius,
                gradient: LinearGradient(
                  colors: colors,
                  stops: stops,
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                onPressed: () => ride.jumpToSG(step: 1), // Jump forward.
                rotation: -pi / 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: radius * 0.15),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Image(
                        image: AssetImage(
                          Theme.of(context).brightness == Brightness.light
                              ? "assets/images/trafficlights/traffic-light-light.png"
                              : "assets/images/trafficlights/traffic-light-dark.png",
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-radius * 0.08, 0),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // BOTTOM BUTTON
          if (ride.userSelectedSG != null)
            Transform.translate(
              offset: const Offset(0, (radius * 0.75)),
              child: CenterButton(
                radius: radius,
                gradient: LinearGradient(
                  colors: colors,
                  stops: stops,
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                ),
                onPressed: ride.unselectSG,
                rotation: pi / 4,
                child: const Icon(
                  Icons.close_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          // LEFT BUTTON
          if (signalGroupsAvailable)
            Transform.translate(
              offset: const Offset(-radius * 0.75, 0),
              child: CenterButton(
                radius: radius,
                gradient: LinearGradient(
                  colors: colors,
                  stops: stops,
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                onPressed: () => ride.jumpToSG(step: -1), // Jump backward.
                rotation: 3 * (pi / 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Image(
                        image: AssetImage(
                          Theme.of(context).brightness == Brightness.light
                              ? "assets/images/trafficlights/traffic-light-light.png"
                              : "assets/images/trafficlights/traffic-light-dark.png",
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-radius * 0.08, 0),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // TOP BUTTON
          Transform.translate(
            offset: const Offset(0, -radius * 0.75),
            child: CenterButton(
              radius: radius,
              gradient: LinearGradient(
                colors: colors,
                stops: stops,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPressed: widget.onTapDanger,
              rotation: -3 * (pi / 4),
              child: const Icon(
                Icons.warning_rounded,
                size: 35,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single button in the center of the speedometer.
class CenterButton extends StatelessWidget {
  /// The radius of the circle that the button is made of.
  final double radius;

  /// The gradient of the button.
  final LinearGradient gradient;

  /// The callback that is called when the button is pressed.
  final Function onPressed;

  /// The rotation of the button.
  final double rotation;

  /// The child of the button.
  final Widget child;

  const CenterButton(
      {Key? key,
      required this.radius,
      required this.onPressed,
      required this.gradient,
      required this.rotation,
      required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius,
      height: radius,
      child: Transform.rotate(
        angle: rotation,
        child: GestureDetector(
          onTap: () => onPressed(),
          child: Stack(
            children: [
              Container(color: Colors.transparent),
              SizedBox(
                width: radius,
                height: radius / 2,
                child: CustomPaint(
                  size: Size(radius, radius / 2),
                  painter: CenterButtonPainter(
                    gradient: gradient,
                  ),
                  child: Transform.translate(
                    offset: Offset(0, radius * 0.25),
                    child: Transform.rotate(
                      angle: -rotation,
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The painter for the special shape of the center buttons.
class CenterButtonPainter extends CustomPainter {
  /// The gradient of the shape.
  final LinearGradient gradient;

  /// The path of the shape.
  Path? buttonPath;

  CenterButtonPainter({required this.gradient});

  /// Draws the shadow of the button.
  void drawButtonShadow(Canvas canvas, Size size, Path path) {
    final paint = Paint()
      ..color = Colors.black
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(path, paint);
  }

  /// Draws the the button.
  void drawButton(Canvas canvas, Size size, Path path) {
    // Draw the main shape
    final paint = Paint()..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: size.width));
    // Draw the border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final holeRadius = size.width / 2;
    final outerRadius = size.width;

    const borderRadius = 5.0;

    // Starting point
    path.moveTo(0, size.height * 2 - borderRadius);
    // Line
    path.lineTo(0, holeRadius + borderRadius);
    // Rounded corner
    path.arcToPoint(
      Offset(borderRadius, holeRadius),
      radius: const Radius.circular(borderRadius),
      clockwise: true,
    );
    // Inner arc
    path.arcToPoint(
      Offset(holeRadius, 0 + borderRadius),
      radius: Radius.circular(holeRadius),
      clockwise: false,
    );
    // Rounded corner
    path.arcToPoint(
      Offset(holeRadius + borderRadius, 0),
      radius: const Radius.circular(borderRadius),
      clockwise: true,
    );
    // Line
    path.lineTo(size.width - borderRadius, 0);
    // Rounded corner
    path.arcToPoint(
      Offset(size.width, borderRadius),
      radius: const Radius.circular(borderRadius),
      clockwise: true,
    );
    // Outer arc
    path.arcToPoint(
      Offset(0 + borderRadius, size.height * 2),
      radius: Radius.circular(outerRadius),
      clockwise: true,
    );
    // Rounded corner
    path.arcToPoint(
      Offset(0, size.height * 2 - borderRadius),
      radius: const Radius.circular(borderRadius),
      clockwise: true,
    );
    path.close();

    buttonPath = path;

    drawButtonShadow(canvas, size, path);
    drawButton(canvas, size, path);
  }

  @override
  bool hitTest(Offset position) {
    if (buttonPath == null) return false;
    return buttonPath!.contains(position);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
