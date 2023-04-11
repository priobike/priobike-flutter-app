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

  Offset addPaddingOnCircle(double originalX, double originalY, double radius, Offset center, double paddingAngle) {
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
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 52;
    final holeRadius = outerRadius / 2;

    const paddingPct = 0.3;
    const paddingAngleOuter = 2 * pi * paddingPct / 100;
    const paddingAngleHole = 2 * pi * (paddingPct * 2) / 100;

    const borderRadiusPct = 0.5;
    const borderRadiusAngle = 2 * pi * borderRadiusPct / 100;
    final borderRadiusDistance = (2 * pi * outerRadius) * ((borderRadiusAngle * (180 / pi)) / 360);

    final outerDistance = sqrt(outerRadius * outerRadius + outerRadius * outerRadius);
    final innerDistance = sqrt(holeRadius * holeRadius + holeRadius * holeRadius);

    final topLeftX = center.dx - outerDistance / 2;
    final topLeftY = center.dy - outerDistance / 2;

    final paddedTopLeft = addPaddingOnCircle(topLeftX, topLeftY, outerRadius, center, paddingAngleOuter);
    final borderRadiusTopLeft2 =
        addPaddingOnCircle(paddedTopLeft.dx, paddedTopLeft.dy, outerRadius, center, borderRadiusAngle);

    path.moveTo(borderRadiusTopLeft2.dx, borderRadiusTopLeft2.dy);

    final topRightX = topLeftX + outerDistance;
    final topRightY = topLeftY + 0;

    final paddedTopRight = addPaddingOnCircle(topRightX, topRightY, outerRadius, center, -paddingAngleOuter);
    final borderRadiusTopRight1 =
        addPaddingOnCircle(paddedTopRight.dx, paddedTopRight.dy, outerRadius, center, -borderRadiusAngle);

    path.arcToPoint(
      Offset(borderRadiusTopRight1.dx, borderRadiusTopRight1.dy),
      radius: Radius.circular(outerRadius),
      clockwise: true,
    );

    final distanceTopRightToCenter =
        sqrt(pow(paddedTopRight.dx - center.dx, 2) + pow(paddedTopRight.dy - center.dy, 2));
    final borderRadiusTopRight2X =
        center.dx + ((1 - (borderRadiusDistance / distanceTopRightToCenter)) * (paddedTopRight.dx - center.dx));
    final borderRadiusTopRight2Y =
        center.dy + ((1 - (borderRadiusDistance / distanceTopRightToCenter)) * (paddedTopRight.dy - center.dy));

    path.arcToPoint(
      Offset(borderRadiusTopRight2X, borderRadiusTopRight2Y),
      radius: Radius.circular(borderRadiusDistance),
      clockwise: true,
    );

    final bottomRightX = topRightX - ((outerDistance - innerDistance) / 2);
    final bottomRightY = topRightY + (outerDistance - innerDistance) / 2;

    final paddedBottomRight = addPaddingOnCircle(bottomRightX, bottomRightY, holeRadius, center, -paddingAngleHole);

    final distanceBottomRightToTopRight =
        sqrt(pow(paddedTopRight.dx - paddedBottomRight.dx, 2) + pow(paddedTopRight.dy - paddedBottomRight.dy, 2));
    final borderRadiusBottomRight1X = paddedBottomRight.dx +
        ((borderRadiusDistance / distanceBottomRightToTopRight) * (paddedTopRight.dx - paddedBottomRight.dx));
    final borderRadiusBottomRight1Y = paddedBottomRight.dy +
        ((borderRadiusDistance / distanceBottomRightToTopRight) * (paddedTopRight.dy - paddedBottomRight.dy));

    path.lineTo(borderRadiusBottomRight1X, borderRadiusBottomRight1Y);

    final borderRadiusBottomRight2 = addPaddingOnCircle(
      paddedBottomRight.dx,
      paddedBottomRight.dy,
      holeRadius,
      center,
      -borderRadiusAngle,
    );

    path.arcToPoint(
      Offset(borderRadiusBottomRight2.dx, borderRadiusBottomRight2.dy),
      radius: Radius.circular(borderRadiusDistance),
      clockwise: true,
    );

    final bottomLeftX = bottomRightX - innerDistance;
    final bottomLeftY = bottomRightY - 0;

    final paddedBottomLeft = addPaddingOnCircle(bottomLeftX, bottomLeftY, holeRadius, center, paddingAngleHole);

    final borderRadiusBottomLeft1 = addPaddingOnCircle(
      paddedBottomLeft.dx,
      paddedBottomLeft.dy,
      holeRadius,
      center,
      borderRadiusAngle,
    );

    path.arcToPoint(
      Offset(borderRadiusBottomLeft1.dx, borderRadiusBottomLeft1.dy),
      radius: Radius.circular(holeRadius),
      clockwise: false,
    );

    final distanceBottomLeftToTopLeft =
        sqrt(pow(paddedTopLeft.dx - paddedBottomLeft.dx, 2) + pow(paddedTopLeft.dy - paddedBottomLeft.dy, 2));
    final borderRadiusBottomLeft2X = paddedBottomLeft.dx +
        ((borderRadiusDistance / distanceBottomLeftToTopLeft) * (paddedTopLeft.dx - paddedBottomLeft.dx));
    final borderRadiusBottomLeft2Y = paddedBottomLeft.dy +
        ((borderRadiusDistance / distanceBottomLeftToTopLeft) * (paddedTopLeft.dy - paddedBottomLeft.dy));

    path.arcToPoint(
      Offset(borderRadiusBottomLeft2X, borderRadiusBottomLeft2Y),
      radius: Radius.circular(borderRadiusDistance),
      clockwise: true,
    );

    final borderRadiusTopLeft1X = paddedBottomLeft.dx +
        ((1 - (borderRadiusDistance / distanceBottomLeftToTopLeft)) * (paddedTopLeft.dx - paddedBottomLeft.dx));
    final borderRadiusTopLeft1Y = paddedBottomLeft.dy +
        ((1 - (borderRadiusDistance / distanceBottomLeftToTopLeft)) * (paddedTopLeft.dy - paddedBottomLeft.dy));

    path.lineTo(borderRadiusTopLeft1X, borderRadiusTopLeft1Y);

    path.arcToPoint(
      Offset(borderRadiusTopLeft2.dx, borderRadiusTopLeft2.dy),
      radius: Radius.circular(borderRadiusDistance),
      clockwise: true,
    );

    path.close();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    //drawButtonShadow(canvas, size, path);
    drawButton(canvas, size, path);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CenterButtonPaint oldDelegate) => false;
}
