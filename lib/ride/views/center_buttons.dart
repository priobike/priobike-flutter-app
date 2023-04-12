import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride.dart';

class RideCenterButtonsView extends StatefulWidget {
  /// A callback that is called when the danger button is tapped.
  final Function onTapDanger;

  /// The size of the canvas for the custom painter.
  final Size size;

  const RideCenterButtonsView({Key? key, required this.onTapDanger, required this.size}) : super(key: key);

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
    Widget nextSignalGroupButtonIcons = Padding(
      padding: EdgeInsets.only(right: widget.size.width * 0.12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size.width * 0.06,
            ),
            SizedBox(
              width: widget.size.width * 0.09,
              height: widget.size.width * 0.09,
              child: Image(
                image: AssetImage(
                  Theme.of(context).brightness == Brightness.light
                      ? "assets/images/trafficlights/traffic-light-light.png"
                      : "assets/images/trafficlights/traffic-light-dark.png",
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(-10, 0),
              child: const Icon(
                Icons.arrow_upward_rounded,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    Widget previousSignalGroupButtonIcons = Padding(
      padding: EdgeInsets.only(left: widget.size.width * 0.12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size.width * 0.03,
            ),
            SizedBox(
              width: widget.size.width * 0.09,
              height: widget.size.width * 0.09,
              child: Image(
                image: AssetImage(
                  Theme.of(context).brightness == Brightness.light
                      ? "assets/images/trafficlights/traffic-light-light.png"
                      : "assets/images/trafficlights/traffic-light-dark.png",
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(-10, 0),
              child: const Icon(
                Icons.arrow_downward_rounded,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    Widget warningsButtonIcon = Padding(
      padding: EdgeInsets.only(top: widget.size.height * 0.18),
      child: const Align(
        alignment: Alignment.topCenter,
        child: Icon(
          Icons.warning_rounded,
          size: 40,
          color: Colors.white,
        ),
      ),
    );

    Widget cancelSGSelectionButtonIcon = Padding(
      padding: EdgeInsets.only(bottom: widget.size.height * 0.19),
      child: const Align(
        alignment: Alignment.bottomCenter,
        child: Icon(
          Icons.close_rounded,
          size: 40,
          color: Colors.white,
        ),
      ),
    );

    final signalGroupsAvailable = ride.route?.signalGroups != null && ride.route!.signalGroups.isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        // RIGHT BUTTON
        if (signalGroupsAvailable)
          CenterButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              ride.jumpToSG(step: 1);
            },
            rotation: pi / 2,
            size: widget.size,
            child: nextSignalGroupButtonIcons,
          ),
        // LEFT BUTTON
        if (signalGroupsAvailable)
          CenterButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              ride.jumpToSG(step: -1);
            },
            rotation: pi + pi / 2,
            size: widget.size,
            child: previousSignalGroupButtonIcons,
          ),
        // TOP BUTTON
        CenterButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            widget.onTapDanger();
          },
          rotation: 0,
          size: widget.size,
          child: warningsButtonIcon,
        ),
        // BOTTOM BUTTON
        if (ride.userSelectedSG != null)
          CenterButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              ride.unselectSG();
            },
            rotation: pi,
            size: widget.size,
            child: cancelSGSelectionButtonIcon,
          ),
      ],
    );
  }
}

/// A single button in the center of the speedometer.
class CenterButton extends StatelessWidget {
  /// The callback that is called when the button is pressed.
  final Function onPressed;

  /// The rotation of the button.
  final double rotation;

  /// The child of the button.
  final Widget child;

  /// The canvas size for the custom painter.
  final Size size;

  const CenterButton({
    Key? key,
    required this.onPressed,
    required this.rotation,
    required this.child,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPressed(),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: CustomPaint(
          size: size,
          painter: CenterButtonPaint(
            rotation: rotation,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The painter for the special shape of the center buttons.
class CenterButtonPaint extends CustomPainter {
  /// The rotation of the button.
  final double rotation;

  /// The path of the shape (gets set when the paint method is called).
  Path? buttonPath;

  /// The center of the shape (gets set when the paint method is called).
  Offset? center;

  CenterButtonPaint({
    this.rotation = 0,
  });

  /// Draws the the button.
  void drawButton(Canvas canvas, Size size, Path path) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
    canvas.drawPath(path, paintStroke);
  }

  /// Moves a point on a circle by a given angle. For positive angles the point is moved clockwise.
  /// For negative angles the point is moved counter-clockwise.
  Offset movePointOnCircle(double originalX, double originalY, double radius, Offset center, double paddingAngle) {
    final originalAngle = atan2(originalY - center.dy, originalX - center.dx);
    final paddedAngle = originalAngle + paddingAngle;

    final paddedPointXOffset = radius * cos(paddedAngle);
    final paddedPointYOffset = radius * sin(paddedAngle);
    final paddedPointX = center.dx + paddedPointXOffset;
    final paddedPointY = center.dy + paddedPointYOffset;

    return Offset(paddedPointX, paddedPointY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Roughly creates the following path (we start at the top left point and go clockwise):
    /*
                                   outer arc
                                  xxxxxxxxxxxx
                            xxxxx           xxxxxxxx
                        xxxxx                       xxxxx
                     xxxx                               xx
                   xxx                                    xx
                 xxx                                        xxx
       topLeft xx                                            xxx  topRight
                xx                 xxxxxxxxxxx                xxx
                  xx          xxxxx          xxxx           xxxxx
                    xxx    xxxx     inner arc  xxx       xxx
                      xxx xx                      xxx  xx
             bottomLeft xxx                         xxxx bottomRight
   */
    final path = Path();
    center = Offset(size.width / 2, size.height / 2);
    // The radius for the outside of the arc.
    final outerRadius = size.width / 2 - 52;
    // The radius for the inside of the arc.
    final holeRadius = outerRadius / 2;

    // The padding that gets subtracted from the buttons such that they are not exactly 1/4 of a circle but instead less.
    // Given in percent of the hole circle. When using multiple buttons, this results in a gap between the buttons.
    const paddingPct = 0.3;
    // Resulting angle in radians.
    const paddingAngleOuter = 2 * pi * paddingPct / 100;
    // Resulting angle in radians (angle needs to be bigger in the middle,
    // this is because the radius is less and thus the same angle would result in a padding of less physical units).
    const paddingAngleHole = 2 * pi * (paddingPct * 2) / 100;

    // The border radius of the buttons. Given in percent.
    const borderRadiusPct = 0.5;
    // For the border radius on the arcs (outside and inside), we need to transform it to an angle (radian).
    const borderRadiusAngle = 2 * pi * borderRadiusPct / 100;
    // For the border radius on the straight lines, we need to calculate the distance.
    final borderRadiusDistance = (2 * pi * outerRadius) * ((borderRadiusAngle * (180 / pi)) / 360);

    // The distance between topLeft and topRight.
    final outerDistance = sqrt(outerRadius * outerRadius + outerRadius * outerRadius);
    // The distance between bottomLeft and bottomRight.
    final innerDistance = sqrt(holeRadius * holeRadius + holeRadius * holeRadius);

    // The coordinates of the top left point (without padding and border radius).
    final topLeftX = center!.dx - outerDistance / 2;
    final topLeftY = center!.dy - outerDistance / 2;

    // The coordinates of the top left point (with padding).
    final paddedTopLeft = movePointOnCircle(topLeftX, topLeftY, outerRadius, center!, paddingAngleOuter);
    // For the border radius, we need to find two new points.
    // 1. The first one is in clockwise direction before the original paddedTopLeft corner
    // (calculated at the end of the path). Thus, it is on the left straight line.
    // 2. The second one is in clockwise direction after the original paddedTopLeft corner. Thus, it is on the outer arc.
    //
    // In between thos points we draw an arc for the border radius.
    // Thus, we don't use the original paddedTopLeft corner in the path, but only for intermediate calculation steps.
    final borderRadiusTopLeft2 =
        movePointOnCircle(paddedTopLeft.dx, paddedTopLeft.dy, outerRadius, center!, borderRadiusAngle);

    // MOVE TO START OF PATH (not drawing anything yet)
    path.moveTo(borderRadiusTopLeft2.dx, borderRadiusTopLeft2.dy);

    // The coordinates of the top right point (without padding and border radius).
    final topRightX = topLeftX + outerDistance;
    final topRightY = topLeftY + 0;

    // The coordinates of the top right point (with padding).
    final paddedTopRight = movePointOnCircle(topRightX, topRightY, outerRadius, center!, -paddingAngleOuter);
    // The first point for the border radius on the top right corner (in clockwise direction before the paddedTopRight point).
    // (same concept as for the top left corner,
    // only if the first and second point are lying on an arc or straight line may be different and depends on the specific corner)
    final borderRadiusTopRight1 =
        movePointOnCircle(paddedTopRight.dx, paddedTopRight.dy, outerRadius, center!, -borderRadiusAngle);

    // DRAW OUTER ARC
    path.arcToPoint(
      Offset(borderRadiusTopRight1.dx, borderRadiusTopRight1.dy),
      radius: Radius.circular(outerRadius),
      clockwise: true,
    );

    // Helper calculation.
    final distanceTopRightToCenter =
        sqrt(pow(paddedTopRight.dx - center!.dx, 2) + pow(paddedTopRight.dy - center!.dy, 2));
    // The second point for the border radius on the top right corner.
    final borderRadiusTopRight2X =
        center!.dx + ((1 - (borderRadiusDistance / distanceTopRightToCenter)) * (paddedTopRight.dx - center!.dx));
    final borderRadiusTopRight2Y =
        center!.dy + ((1 - (borderRadiusDistance / distanceTopRightToCenter)) * (paddedTopRight.dy - center!.dy));

    // DRAW BORDER RADIUS AT THE TOP RIGHT CORNER
    path.arcToPoint(
      Offset(borderRadiusTopRight2X, borderRadiusTopRight2Y),
      radius: Radius.circular(borderRadiusDistance),
      clockwise: true,
    );

    // The coordinates of the bottom right point (without padding and border radius).
    final bottomRightX = topRightX - ((outerDistance - innerDistance) / 2);
    final bottomRightY = topRightY + (outerDistance - innerDistance) / 2;

    // The coordinates of the bottom right point (with padding).
    final paddedBottomRight = movePointOnCircle(bottomRightX, bottomRightY, holeRadius, center!, -paddingAngleHole);

    // Helper calculation.
    final distanceBottomRightToTopRight =
        sqrt(pow(paddedTopRight.dx - paddedBottomRight.dx, 2) + pow(paddedTopRight.dy - paddedBottomRight.dy, 2));
    // The first point for the border radius on the bottom right corner (in clockwise direction before paddedBottomRight).
    final borderRadiusBottomRight1X = paddedBottomRight.dx +
        ((borderRadiusDistance / distanceBottomRightToTopRight) * (paddedTopRight.dx - paddedBottomRight.dx));
    final borderRadiusBottomRight1Y = paddedBottomRight.dy +
        ((borderRadiusDistance / distanceBottomRightToTopRight) * (paddedTopRight.dy - paddedBottomRight.dy));

    // DRAW THE STRAIGHT LINE ON THE RIGHT SIDE.
    path.lineTo(borderRadiusBottomRight1X, borderRadiusBottomRight1Y);

    // The second point for the border radius on the bottom right corner (in clockwise direction after paddedBottomRight).
    final borderRadiusBottomRight2 = movePointOnCircle(
      paddedBottomRight.dx,
      paddedBottomRight.dy,
      holeRadius,
      center!,
      -borderRadiusAngle,
    );

    // DRAW THE BORDER RADIUS ON THE BOTTOM RIGHT CORNER.
    path.arcToPoint(
      Offset(borderRadiusBottomRight2.dx, borderRadiusBottomRight2.dy),
      radius: Radius.circular(borderRadiusDistance),
      clockwise: true,
    );

    // The coordinates of the bottom left point (without padding and border radius).
    final bottomLeftX = bottomRightX - innerDistance;
    final bottomLeftY = bottomRightY - 0;

    // The coordinates of the bottom left point (with padding).
    final paddedBottomLeft = movePointOnCircle(bottomLeftX, bottomLeftY, holeRadius, center!, paddingAngleHole);

    // The first point for the border radius on the bottom left corner (in clockwise direction before paddedBottomLeft).
    final borderRadiusBottomLeft1 = movePointOnCircle(
      paddedBottomLeft.dx,
      paddedBottomLeft.dy,
      holeRadius,
      center!,
      borderRadiusAngle,
    );

    // DRAW INNER ARC
    path.arcToPoint(
      Offset(borderRadiusBottomLeft1.dx, borderRadiusBottomLeft1.dy),
      radius: Radius.circular(holeRadius),
      clockwise: false,
    );

    // Helper calculation.
    final distanceBottomLeftToTopLeft =
        sqrt(pow(paddedTopLeft.dx - paddedBottomLeft.dx, 2) + pow(paddedTopLeft.dy - paddedBottomLeft.dy, 2));
    // The second point for the border radius on the bottom left corner (in clockwise direction after paddedBottomLeft).
    final borderRadiusBottomLeft2X = paddedBottomLeft.dx +
        ((borderRadiusDistance / distanceBottomLeftToTopLeft) * (paddedTopLeft.dx - paddedBottomLeft.dx));
    final borderRadiusBottomLeft2Y = paddedBottomLeft.dy +
        ((borderRadiusDistance / distanceBottomLeftToTopLeft) * (paddedTopLeft.dy - paddedBottomLeft.dy));

    // DRAW THE BORDER RADIUS ON THE BOTTOM LEFT CORNER.
    path.arcToPoint(
      Offset(borderRadiusBottomLeft2X, borderRadiusBottomLeft2Y),
      radius: Radius.circular(borderRadiusDistance),
      clockwise: true,
    );

    // The first point for the border radius on the top left corner (in clockwise direction before paddedTopLeft).
    final borderRadiusTopLeft1X = paddedBottomLeft.dx +
        ((1 - (borderRadiusDistance / distanceBottomLeftToTopLeft)) * (paddedTopLeft.dx - paddedBottomLeft.dx));
    final borderRadiusTopLeft1Y = paddedBottomLeft.dy +
        ((1 - (borderRadiusDistance / distanceBottomLeftToTopLeft)) * (paddedTopLeft.dy - paddedBottomLeft.dy));

    // DRAW THE STRAIGHT LINE ON THE LEFT SIDE.
    path.lineTo(borderRadiusTopLeft1X, borderRadiusTopLeft1Y);

    // DRAW THE BORDER RADIUS ON THE TOP LEFT CORNER.
    path.arcToPoint(
      Offset(borderRadiusTopLeft2.dx, borderRadiusTopLeft2.dy),
      radius: Radius.circular(borderRadiusDistance),
      clockwise: true,
    );

    path.close();

    // Rotate the path with the given angle.
    // The translation is necessary such that the rotation is done around the center of the button.
    // Thus it sets the anchor.
    canvas.save();
    canvas.translate(center!.dx, center!.dy);
    canvas.rotate(rotation);
    canvas.translate(-center!.dx, -center!.dy);
    drawButton(canvas, size, path);
    canvas.restore();

    buttonPath = path;
  }

  @override
  bool hitTest(Offset position) {
    if (buttonPath == null) return false;
    if (center == null) return false;

    // IMPORTANT: Because we also rotate the buttons but don't apply the rotation directly to the path but instead
    // rotate the canvas (not possible otherwise), we have to rotate the tap position to
    // perform a hit test that also considers the rotation of the paths.
    final distanceToCenter = sqrt(pow(position.dx - center!.dx, 2) + pow(position.dy - center!.dy, 2));
    Offset rotatedPosition = movePointOnCircle(position.dx, position.dy, distanceToCenter, center!, rotation);

    return buttonPath!.contains(rotatedPosition);
  }

  @override
  bool shouldRepaint(covariant CenterButtonPaint oldDelegate) => true;
}
