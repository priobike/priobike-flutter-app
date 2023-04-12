import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride.dart';

class RideCenterButtonsView extends StatefulWidget {
  /// A callback that is called when the danger button is tapped.
  final Function onTapDanger;

  final double heightToPuck;

  final Size size;

  const RideCenterButtonsView({Key? key, required this.onTapDanger, required this.heightToPuck, required this.size})
      : super(key: key);

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
    final colors = [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.4)];
    final stops = [0.0, 0.8];
    double radius = widget.heightToPuck;

    const spacing = 0.73;

    final signalGroupsAvailable = ride.route?.signalGroups != null && ride.route!.signalGroups.isNotEmpty;

    return Stack(
      children: [
        CustomPaint(
          size: widget.size,
          painter: CenterButtonPaint(
            isDark: Theme.of(context).colorScheme.brightness == Brightness.dark,
            rotation: 0,
          ),
        ),
        CustomPaint(
          size: widget.size,
          painter: CenterButtonPaint(
            isDark: Theme.of(context).colorScheme.brightness == Brightness.dark,
            rotation: pi / 2,
          ),
        ),
        CustomPaint(
          size: widget.size,
          painter: CenterButtonPaint(
            isDark: Theme.of(context).colorScheme.brightness == Brightness.dark,
            rotation: pi,
          ),
        ),
        CustomPaint(
          size: widget.size,
          painter: CenterButtonPaint(
            isDark: Theme.of(context).colorScheme.brightness == Brightness.dark,
            rotation: pi + pi / 2,
          ),
        ),
      ],
    );
  }
}

class CenterButtonPaint extends CustomPainter {
  bool isDark;
  double rotation;

  CenterButtonPaint({
    required this.isDark,
    this.rotation = 0,
  });

  /// Draws the the button.
  void drawButton(Canvas canvas, Size size, Path path) {
    final paint = Paint()..color = Colors.red;
    canvas.drawPath(path, paint);
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
    final center = Offset(size.width / 2, size.height / 2);
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
    final topLeftX = center.dx - outerDistance / 2;
    final topLeftY = center.dy - outerDistance / 2;

    // The coordinates of the top left point (with padding).
    final paddedTopLeft = movePointOnCircle(topLeftX, topLeftY, outerRadius, center, paddingAngleOuter);
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
    final topRightX = topLeftX + outerDistance;
    final topRightY = topLeftY + 0;

    // The coordinates of the top right point (with padding).
    final paddedTopRight = movePointOnCircle(topRightX, topRightY, outerRadius, center, -paddingAngleOuter);
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
    final bottomRightX = topRightX - ((outerDistance - innerDistance) / 2);
    final bottomRightY = topRightY + (outerDistance - innerDistance) / 2;

    // The coordinates of the bottom right point (with padding).
    final paddedBottomRight = movePointOnCircle(bottomRightX, bottomRightY, holeRadius, center, -paddingAngleHole);

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
    final bottomLeftX = bottomRightX - innerDistance;
    final bottomLeftY = bottomRightY - 0;

    // The coordinates of the bottom left point (with padding).
    final paddedBottomLeft = movePointOnCircle(bottomLeftX, bottomLeftY, holeRadius, center, paddingAngleHole);

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

    // Rotate the path with the given angle.
    // The translation is necessary such that the rotation is done around the center of the button.
    // Thus it sets the anchor.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    drawButton(canvas, size, path);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CenterButtonPaint oldDelegate) => false;
}
