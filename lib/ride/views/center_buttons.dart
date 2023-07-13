import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/tracking/models/reported_bad_prediction.dart';
import 'package:priobike/tracking/services/tracking.dart';

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
  /// The size of the canvas for the custom painter.
  final Size size;

  const RideCenterButtonsView({Key? key, required this.size}) : super(key: key);

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

  void onTapDiscomfort() {
    // Get the current snapped position.
    final snap = getIt<Positioning>().snap;
    if (snap == null) {
      log.w("Cannot report a discomfort without a current snapped position.");
      return;
    }

    final discomforts = getIt<Discomforts>();
    discomforts.submitNew(snap, "discomfort");
    ToastMessage.showSuccess("Unkomfortable Stelle gemeldet!");
  }

  void onTapRecommendation() {
    // Get the current snapped position.
    final snap = getIt<Positioning>().snap;
    if (snap == null) {
      log.w("Cannot report a recommendation without a current snapped position.");
      return;
    }

    final discomforts = getIt<Discomforts>();
    discomforts.submitNew(snap, "recommendation");
    ToastMessage.showSuccess("Komfortable Stelle gemeldet!");
  }

  void onTapBadPrediction() {
    // TODO remove
    // Get the current snapped position.
    final lastPosition = getIt<Positioning>().lastPosition;
    if (lastPosition == null) {
      log.w("Cannot report a bad prediction without the last position.");
      return;
    }

    final tracking = getIt<Tracking>();
    tracking.track?.reportedBadPredictions.add(
      ReportedBadPrediction(
        snappedPositionOnRouteLng: lastPosition.longitude,
        snappedPositionOnRouteLat: lastPosition.latitude,
        timestampOfReport: DateTime.now().millisecondsSinceEpoch,
        sgUserSelected: getIt<Ride>().userSelectedSG != null,
      ),
    );
    ToastMessage.showSuccess("Schlechte Prognose gemeldet!");
  }

  @override
  Widget build(BuildContext context) {
    const opacity = 1.0;
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(opacity),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    Widget recommendationButtonIcons = Padding(
      padding: EdgeInsets.only(right: widget.size.width * 0.12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: widget.size.width * 0.2,
          height: widget.size.width * 0.25,
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.add_road_rounded,
                size: 40,
                color: Colors.white.withOpacity(opacity),
              ),
              Text(
                "Komfortable\nStelle",
                textAlign: TextAlign.center,
                style: textStyle,
              )
            ],
          ),
        ),
      ),
    );

    Widget discomfortButtonIcons = Padding(
      padding: EdgeInsets.only(left: widget.size.width * 0.12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: widget.size.width * 0.2,
          height: widget.size.width * 0.25,
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.remove_road_rounded,
                size: 40,
                color: Colors.white.withOpacity(opacity),
              ),
              Text(
                "Un-\nkomfortable\nStelle",
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
        Transform.rotate(
          angle: -angle / 2,
          origin: const Offset(0, 0),
          child: ShaderMask(
            shaderCallback: (Rect rect) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.white],
                //set stops as par your requirement
                stops: [0.6, 0.8], // 50% transparent, 50% white
              ).createShader(rect);
            },
            blendMode: BlendMode.dstOut,
            child: ShaderMask(
              shaderCallback: (Rect rect) {
                return const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.transparent, Colors.white],
                  //set stops as par your requirement
                  stops: [0.2, 0.6], // 50% transparent, 50% white
                ).createShader(rect);
              },
              blendMode: BlendMode.dstOut,
              child: CustomPaint(
                size: widget.size,
                painter: RoutePainter(angle, true),
              ),
            ),
          ),
        ),
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(pi),
          child: Transform.rotate(
            angle: -angle / 2,
            origin: const Offset(0, 0),
            child: ShaderMask(
            shaderCallback: (Rect rect) {
    return const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Colors.transparent, Colors.white],
    //set stops as par your requirement
    stops: [0.6, 0.8], // 50% transparent, 50% white
    ).createShader(rect);
    },
    blendMode: BlendMode.dstOut,
    child: ShaderMask(
    shaderCallback: (Rect rect) {
    return const LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Colors.transparent, Colors.white],
    //set stops as par your requirement
    stops: [0.2, 0.6], // 50% transparent, 50% white
    ).createShader(rect);
    },
    blendMode: BlendMode.dstOut,
    child: CustomPaint(
                size: widget.size,
                painter: RoutePainter(angle, false),
              ),
            ),),
          ),
        ),
        // RIGHT BUTTON
        CenterButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            onTapRecommendation();
          },
          rotation: angle / 2,
          size: widget.size,
          angle: angle,
          child: recommendationButtonIcons,
        ),
        // LEFT BUTTON
        CenterButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            onTapDiscomfort();
          },
          rotation: -angle / 2,
          size: widget.size,
          angle: angle,
          child: discomfortButtonIcons,
        ),
      ],
    );
  }
}

class RoutePainter extends CustomPainter {
  final double angle;

  final bool discomfort;

  RoutePainter(this.angle, this.discomfort);

  void paintPredictionArcBackground(Canvas canvas, Size size) {
    final path = Path();
    Offset center = Offset(size.width / 2, size.height / 2);
    // The radius for the outside of the arc.
    final outerRadius = size.width / 2 - 52;
    // The radius for the inside of the arc.
    final holeRadius = outerRadius / 2 + 12;

    const padding = 0.1;
    final factor = outerRadius / holeRadius;

    // The padding that gets subtracted from the buttons such that they are not exactly 1/4 of a circle but instead less.
    // Given in percent of the hole circle. When using multiple buttons, this results in a gap between the buttons.
    const paddingPct = 0.3;
    // Resulting angle in radians.
    const paddingAngleOuter = 2 * pi * paddingPct / 100;
    // Resulting angle in radians (angle needs to be bigger in the middle,
    // this is because the radius is less and thus the same angle would result in a padding of less physical units).
    const paddingAngleHole = 2 * pi * (paddingPct * 2) / 100;

    // The border radius of the buttons. Given in percent.
    var borderRadiusPct = 0.5;
    // For the border radius on the arcs (outside and inside), we need to transform it to an angle (radian).
    var borderRadiusAngle = 2 * pi * borderRadiusPct / 100;
    // For the border radius on the straight lines, we need to calculate the distance.
    var borderRadiusDistance = (2 * pi * outerRadius) * ((borderRadiusAngle * (180 / pi)) / 360);

    // The coordinates of the top right point (without padding and border radius).
    final topRight = movePointOnCircle(size.width / 2, 0, outerRadius, center, angle / 2 - padding);

    // The coordinates of the top right point (with padding).
    final paddedTopRight = movePointOnCircle(topRight.dx, topRight.dy, outerRadius, center, -paddingAngleOuter);

    // Helper calculation.
    final distanceTopRightToCenter =
        sqrt(pow(paddedTopRight.dx - center.dx, 2) + pow(paddedTopRight.dy - center.dy, 2));
    // The second point for the border radius on the top right corner.
    final borderRadiusTopRight2X =
        center.dx + ((1 - (borderRadiusDistance / distanceTopRightToCenter)) * (paddedTopRight.dx - center.dx));
    final borderRadiusTopRight2Y =
        center.dy + ((1 - (borderRadiusDistance / distanceTopRightToCenter)) * (paddedTopRight.dy - center.dy));

    // MOVE TO START OF PATH (not drawing anything yet)
    path.moveTo(borderRadiusTopRight2X, borderRadiusTopRight2Y);

    // The coordinates of the bottom right point (without padding and border radius).
    final bottomRight =
        movePointOnCircle(size.width / 2, outerRadius - holeRadius, holeRadius, center, angle / 2 - padding * factor);

    // The coordinates of the bottom right point (with padding).
    final paddedBottomRight = movePointOnCircle(bottomRight.dx, bottomRight.dy, holeRadius, center, -paddingAngleHole);

    // The border radius of the buttons. Given in percent.
    borderRadiusPct = 4;
    // For the border radius on the arcs (outside and inside), we need to transform it to an angle (radian).
    borderRadiusAngle = 2 * pi * borderRadiusPct / 100;
    // For the border radius on the straight lines, we need to calculate the distance.
    borderRadiusDistance = (2 * pi * outerRadius) * ((borderRadiusAngle * (180 / pi)) / 360);

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
      -borderRadiusAngle - 0.2,
    );

    // DRAW THE BORDER RADIUS ON THE BOTTOM RIGHT CORNER.
    path.arcToPoint(
      Offset(borderRadiusBottomRight2.dx, borderRadiusBottomRight2.dy),
      radius: Radius.circular(borderRadiusDistance + 50),
      clockwise: true,
    );

    // The coordinates of the bottom left point (without padding and border radius).
    final bottomLeft =
        movePointOnCircle(bottomRight.dx, bottomRight.dy, holeRadius, center, -angle * 0.7 + padding * factor);

    // DRAW INNER ARC
    path.arcToPoint(
      Offset(bottomLeft.dx, bottomLeft.dy),
      radius: Radius.circular(holeRadius),
      clockwise: false,
    );

    // The coordinates of the top left point (without padding and border radius).
    final topLeft = movePointOnCircle(size.width / 2, 0, outerRadius, center, -angle * 0.9 / 2);

    // DRAW INNER ARC
    path.arcToPoint(
      Offset(topLeft.dx + 10, topLeft.dy + 5),
      radius: Radius.circular(holeRadius + 60),
      clockwise: true,
    );

    final paint = Paint()
      ..color = CI.blue
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);

    final paintDashes = Paint()
      ..color = Colors.black
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (discomfort) {
      Path dashPath = Path();

      double dashWidth = 10.0;
      double dashSpace = 20.0;
      double distance = 0.0;

      for (PathMetric pathMetric in path.computeMetrics()) {
        while (distance < pathMetric.length) {
          dashPath.addPath(
            pathMetric.extractPath(distance, distance + dashWidth),
            Offset.zero,
          );
          distance += dashWidth;
          distance += dashSpace;
        }
      }
      canvas.drawPath(dashPath, paintDashes);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintPredictionArcBackground(canvas, size);
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) => false;
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
    Key? key,
    required this.onPressed,
    required this.rotation,
    required this.child,
    required this.size,
    required this.angle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      origin: const Offset(0, 0),
      child: RawMaterialButton(
        shape: CenterButtonBorder(angle),
        onPressed: () => onPressed(),
        fillColor: Colors.black.withOpacity(0.4),
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

  const CenterButtonBorder(this.angle, {BorderSide side = BorderSide.none}) : super(side: side);

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
