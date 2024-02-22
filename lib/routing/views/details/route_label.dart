import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/models/route_label.dart';

class RouteLabelIcon extends StatelessWidget {
  final RouteLabel routeLabel;

  /// The corner margin for the icon that is applied to the route label.
  static const double cornerIconMargin = 10;

  /// The corner icon size for the route label.
  static const double cornerIconSize = 20;

  /// The max width used for calculations.
  static const double maxWidth = 160;

  /// The max height used for calculations.
  static const double maxHeight = 60;

  const RouteLabelIcon({super.key, required this.routeLabel});

  @override
  Widget build(BuildContext context) {
    late Alignment pointerAlignment;
    bool flipX = false;
    bool flipY = false;

    if (routeLabel.routeLabelOrientationHorizontal == RouteLabelOrientationHorizontal.left) {
      if (routeLabel.routeLabelOrientationVertical == RouteLabelOrientationVertical.top) {
        pointerAlignment = Alignment.topLeft;
      } else {
        pointerAlignment = Alignment.bottomLeft;
        flipY = true;
      }
    } else {
      if (routeLabel.routeLabelOrientationVertical == RouteLabelOrientationVertical.top) {
        pointerAlignment = Alignment.topRight;
        flipX = true;
      } else {
        pointerAlignment = Alignment.bottomRight;
        flipX = true;
        flipY = true;
      }
    }

    return Stack(children: [
      Positioned.fill(
        child: Align(
          alignment: pointerAlignment,
          child: Transform.flip(
            flipX: flipX,
            flipY: flipY,
            child: CustomPaint(
              painter: PointerPainter(
                context: context,
                color: routeLabel.selected ? CI.route : CI.secondaryRoute,
              ),
              child: const SizedBox(
                height: cornerIconSize,
                width: cornerIconSize,
              ),
            ),
          ),
        ),
      ),
      Container(
        margin: EdgeInsets.only(
          left:
              routeLabel.routeLabelOrientationHorizontal == RouteLabelOrientationHorizontal.left ? cornerIconMargin : 0,
          top: routeLabel.routeLabelOrientationVertical == RouteLabelOrientationVertical.top ? cornerIconMargin : 0,
          right: routeLabel.routeLabelOrientationHorizontal == RouteLabelOrientationHorizontal.right
              ? cornerIconMargin
              : 0,
          bottom:
              routeLabel.routeLabelOrientationVertical == RouteLabelOrientationVertical.bottom ? cornerIconMargin : 0,
        ),
        decoration: BoxDecoration(
          color: routeLabel.selected ? CI.route : CI.secondaryRoute,
          borderRadius: BorderRadius.circular(7.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BoldSmall(
              text: routeLabel.timeText,
              context: context,
              textAlign: TextAlign.center,
              color: routeLabel.selected ? Colors.white : Colors.black,
            ),
            if (routeLabel.secondaryText != null)
              Small(
                text: routeLabel.secondaryText!,
                context: context,
                textAlign: TextAlign.center,
                color: routeLabel.selected ? Colors.white : Colors.black,
              ),
          ],
        ),
      ),
    ]);
  }
}

class PointerPainter extends CustomPainter {
  final BuildContext context;

  final Color color;

  PointerPainter({required this.context, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()..color = color;

    // Draw the background;
    canvas.drawPath(getTrianglePath(size.width, size.height), backgroundPaint);
  }

  Path getTrianglePath(double x, double y) {
    return Path()
      ..moveTo(x * 0.6, y)
      ..lineTo(x * 0.2, y * 0.3)
      ..cubicTo(x * 0.2, y * 0.3, x * 0.2, y * 0.2, x * 0.3, y * 0.2)
      ..lineTo(x, y * 0.6);
  }

  @override
  bool shouldRepaint(PointerPainter oldDelegate) {
    return false;
  }
}
