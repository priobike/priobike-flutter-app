import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/text.dart';

class TargetMarkerIcon extends StatelessWidget {
  /// The index of the tapped waypoint.
  final int idx;

  /// The number of waypoints of the selected route.
  final int waypointSize;

  const TargetMarkerIcon({super.key, required this.idx, required this.waypointSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            CustomPaint(
              painter: TargetMarkerLocationPainter(
                context: context,
              ),
              child: const SizedBox(height: 40, width: 22),
            ),
            if (idx == 0)
              const Padding(
                padding: EdgeInsets.only(top: 1, left: 1),
                child: StartIcon(width: 20, height: 20),
              )
            else if (idx == waypointSize - 1)
              const Padding(
                padding: EdgeInsets.only(top: 1, left: 1),
                child: DestinationIcon(width: 20, height: 20),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 1, left: 1),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const WaypointIcon(width: 20, height: 20),
                    Padding(
                      padding: EdgeInsets.only(top: Platform.isAndroid ? 3 : 0),
                      child: BoldSmall(
                        text: (idx + 1).toString(),
                        color: Colors.black,
                        context: context,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        Center(
          child: CustomPaint(
            painter: TargetMarkerPainter(
              context: context,
            ),
            child: const SizedBox(height: 10, width: 10),
          ),
        ),
        const SizedBox(
          height: 48,
        )
      ],
    );
  }
}

class TargetMarkerPainter extends CustomPainter {
  final BuildContext context;

  TargetMarkerPainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Theme.of(context).colorScheme.onBackground
      ..strokeWidth = 3;

    canvas.drawPath(getTargetPath(size.width, size.height), paint);
  }

  Path getTargetPath(double x, double y) {
    return Path()
      ..lineTo(x, y)
      ..moveTo(x, 0)
      ..lineTo(0, y);
  }

  @override
  bool shouldRepaint(TargetMarkerPainter oldDelegate) {
    return false;
  }
}

class TargetMarkerLocationPainter extends CustomPainter {
  final BuildContext context;

  TargetMarkerLocationPainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Theme.of(context).brightness == Brightness.dark ? CI.darkModeRoute : CI.lightModeRoute;

    canvas.drawCircle(Offset(size.width / 2, size.width / 2), size.width / 2, paint);
    canvas.drawPath(getTargetLocationPath(size.width, size.height), paint);
  }

  Path getTargetLocationPath(double x, double y) {
    return Path()
      ..moveTo(0, y * 0.33)
      ..cubicTo(x * 0.2, y * 0.5, x * 0.45, y * 0.8, x * 0.5, y)
      ..cubicTo(x * 0.55, y * 0.8, x * 0.8, y * 0.5, x, y * 0.33)
      ..lineTo(0, x / 2);
  }

  @override
  bool shouldRepaint(TargetMarkerLocationPainter oldDelegate) {
    return false;
  }
}
