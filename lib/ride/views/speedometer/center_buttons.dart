import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride.dart';

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

class RideCenterButtonsView extends StatefulWidget {
  const RideCenterButtonsView({super.key});

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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    final orientation = MediaQuery.of(context).orientation;
    final double originalSpeedometerHeight;
    final double originalSpeedometerWidth;

    if (orientation == Orientation.portrait) {
      // Portrait mode
      originalSpeedometerHeight = MediaQuery.of(context).size.width;
      originalSpeedometerWidth = MediaQuery.of(context).size.width;
    } else {
      // Landscape mode
      originalSpeedometerHeight = MediaQuery.of(context).size.height;
      originalSpeedometerWidth = MediaQuery.of(context).size.height;
    }
    final size = Size(originalSpeedometerWidth, originalSpeedometerHeight);

    // Radii of the buttons
    final outerRadius = size.width / 2 - 52;
    final holeRadius = outerRadius / 2;

    const a1 = 115;
    final x1 = sin(a1 * (pi / 180)) * (holeRadius + (outerRadius - holeRadius) / 2);
    final y1 = cos(a1 * (pi / 180)) * (holeRadius + (outerRadius - holeRadius) / 2);
    Widget rightButton = Transform.translate(
      offset: Offset(x1, y1),
      child: Center(
        child: Container(
          width: size.width * 0.2,
          height: size.width * 0.25,
          padding: const EdgeInsets.only(top: 20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 40,
                color: Colors.white,
              ),
              Text(
                "Nächste\nAmpel",
                textAlign: TextAlign.center,
                style: textStyle,
              )
            ],
          ),
        ),
      ),
    );

    const a2 = -115;
    final x2 = sin(a2 * (pi / 180)) * (holeRadius + (outerRadius - holeRadius) / 2);
    final y2 = cos(a2 * (pi / 180)) * (holeRadius + (outerRadius - holeRadius) / 2);
    Widget leftButton = Transform.translate(
      offset: Offset(x2, y2),
      child: Center(
        child: Container(
          width: size.width * 0.2,
          height: size.width * 0.25,
          padding: const EdgeInsets.only(top: 20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.arrow_downward_rounded,
                size: 40,
                color: Colors.white,
              ),
              Text(
                "Vorherige\nAmpel",
                textAlign: TextAlign.center,
                style: textStyle,
              )
            ],
          ),
        ),
      ),
    );

    const angle = 135 * (pi / 180);

    return Stack(
      alignment: Alignment.center,
      children: [
        // RIGHT BUTTON
        CenterButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            ride.jumpToSG(step: 1);
          },
          rotation: angle / 2,
          size: size,
          angle: angle,
          child: Container(),
        ),
        // LEFT BUTTON
        CenterButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            ride.jumpToSG(step: -1);
          },
          rotation: -angle / 2,
          size: size,
          angle: angle,
          child: Container(),
        ),
        IgnorePointer(
          child: leftButton,
        ),
        IgnorePointer(
          child: rightButton,
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

  /// The angle of the button (what portion of a circle the button is taking, in radians).
  final double angle;

  const CenterButton({
    super.key,
    required this.onPressed,
    required this.rotation,
    required this.child,
    required this.size,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      origin: const Offset(0, 0),
      child: RawMaterialButton(
        shape: CenterButtonBorder(angle),
        onPressed: () => onPressed(),
        fillColor: Theme.of(context).brightness == Brightness.light
            ? Colors.black.withOpacity(0.25)
            : Colors.white.withOpacity(0.1),
        splashColor: Theme.of(context).colorScheme.surfaceTint,
        highlightColor: CI.radkulturRed,
        elevation: 0,
        child: Transform.rotate(
          angle: -rotation,
          origin: const Offset(0, 0),
          child: child,
        ),
      ),
    );
  }
}

/// A custom border for the center buttons.
class CenterButtonBorder extends OutlinedBorder {
  /// The angle of the button (what portion of a circle the button is taking, in radians).
  final double angle;

  const CenterButtonBorder(this.angle, {super.side});

  @override
  OutlinedBorder copyWith({BorderSide? side}) {
    return CenterButtonBorder(angle, side: side ?? this.side);
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getCenterButtonShape(Size(rect.width, rect.height));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return getCenterButtonShape(Size(rect.width, rect.height));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        canvas.drawPath(
            getCenterButtonShape(Size(rect.width, rect.height)),
            Paint()
              ..style = PaintingStyle.stroke
              ..color = Colors.black
              ..strokeWidth = 1.0);
    }
  }

  @override
  ShapeBorder scale(double t) => CenterButtonBorder(angle, side: side.scale(t));

  /// Returns the path of the center button.
  Path getCenterButtonShape(Size size) {
    final path = Path();
    Offset center = Offset(size.width / 2, size.height / 2);
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

    // The coordinates of the top left point (without padding and border radius).
    final topLeft = movePointOnCircle(size.width / 2, 0, outerRadius, center, -angle / 2);

    // The coordinates of the top left point (with padding).
    final paddedTopLeft = movePointOnCircle(topLeft.dx, topLeft.dy, outerRadius, center, paddingAngleOuter);
    // For the border radius, we need to find two new points.
    // 1. The first one is in clockwise direction before the original paddedTopLeft corner
    // (calculated at the end of the path). Thus, it is on the left straight line.
    // 2. The second one is in clockwise direction after the original paddedTopLeft corner. Thus, it is on the outer arc.
    //
    // In between thos points we draw an arc for the border radius.
    // Thus, we don't use the original paddedTopLeft corner in the path, but only for intermediate calculation steps.
    final borderRadiusTopLeft2 =
        movePointOnCircle(paddedTopLeft.dx, paddedTopLeft.dy, outerRadius, center, borderRadiusAngle);

    // MOVE TO START OF PATH (not drawing anything yet)
    path.moveTo(borderRadiusTopLeft2.dx, borderRadiusTopLeft2.dy);

    // The coordinates of the top right point (without padding and border radius).
    final topRight = movePointOnCircle(topLeft.dx, topLeft.dy, outerRadius, center, angle);

    // The coordinates of the top right point (with padding).
    final paddedTopRight = movePointOnCircle(topRight.dx, topRight.dy, outerRadius, center, -paddingAngleOuter);
    // The first point for the border radius on the top right corner (in clockwise direction before the paddedTopRight point).
    // (same concept as for the top left corner,
    // only if the first and second point are lying on an arc or straight line may be different and depends on the specific corner)
    final borderRadiusTopRight1 =
        movePointOnCircle(paddedTopRight.dx, paddedTopRight.dy, outerRadius, center, -borderRadiusAngle);

    // DRAW OUTER ARC
    path.arcToPoint(
      Offset(borderRadiusTopRight1.dx, borderRadiusTopRight1.dy),
      radius: Radius.circular(outerRadius),
      clockwise: true,
    );

    // Helper calculation.
    final distanceTopRightToCenter =
        sqrt(pow(paddedTopRight.dx - center.dx, 2) + pow(paddedTopRight.dy - center.dy, 2));
    // The second point for the border radius on the top right corner.
    final borderRadiusTopRight2X =
        center.dx + ((1 - (borderRadiusDistance / distanceTopRightToCenter)) * (paddedTopRight.dx - center.dx));
    final borderRadiusTopRight2Y =
        center.dy + ((1 - (borderRadiusDistance / distanceTopRightToCenter)) * (paddedTopRight.dy - center.dy));

    // DRAW BORDER RADIUS AT THE TOP RIGHT CORNER
    path.arcToPoint(
      Offset(borderRadiusTopRight2X, borderRadiusTopRight2Y),
      radius: Radius.circular(borderRadiusDistance),
      clockwise: true,
    );

    // The coordinates of the bottom right point (without padding and border radius).
    final bottomRight = movePointOnCircle(size.width / 2, outerRadius - holeRadius, holeRadius, center, angle / 2);

    // The coordinates of the bottom right point (with padding).
    final paddedBottomRight = movePointOnCircle(bottomRight.dx, bottomRight.dy, holeRadius, center, -paddingAngleHole);

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
      center,
      -borderRadiusAngle,
    );

    // DRAW THE BORDER RADIUS ON THE BOTTOM RIGHT CORNER.
    path.arcToPoint(
      Offset(borderRadiusBottomRight2.dx, borderRadiusBottomRight2.dy),
      radius: Radius.circular(borderRadiusDistance),
      clockwise: true,
    );

    // The coordinates of the bottom left point (without padding and border radius).
    final bottomLeft = movePointOnCircle(bottomRight.dx, bottomRight.dy, holeRadius, center, -angle);

    // The coordinates of the bottom left point (with padding).
    final paddedBottomLeft = movePointOnCircle(bottomLeft.dx, bottomLeft.dy, holeRadius, center, paddingAngleHole);

    // The first point for the border radius on the bottom left corner (in clockwise direction before paddedBottomLeft).
    final borderRadiusBottomLeft1 = movePointOnCircle(
      paddedBottomLeft.dx,
      paddedBottomLeft.dy,
      holeRadius,
      center,
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

    return path;
  }
}
