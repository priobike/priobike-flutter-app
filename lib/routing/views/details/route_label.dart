import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/models/route_label.dart';

const double cornerMargin = 13.5;

class RouteLabelIcon extends StatelessWidget {
  final RouteLabel routeLabel;

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
                height: 20,
                width: 20,
              ),
            ),
          ),
        ),
      ),
      Container(
        // 1 pixel less then the height of the triangle so that the border gets hidden.
        margin: EdgeInsets.only(
          left: routeLabel.routeLabelOrientationHorizontal == RouteLabelOrientationHorizontal.left ? cornerMargin : 0,
          top: routeLabel.routeLabelOrientationVertical == RouteLabelOrientationVertical.top ? cornerMargin : 0,
          right: routeLabel.routeLabelOrientationHorizontal == RouteLabelOrientationHorizontal.right ? cornerMargin : 0,
          bottom: routeLabel.routeLabelOrientationVertical == RouteLabelOrientationVertical.bottom ? cornerMargin : 0,
        ),
        decoration: BoxDecoration(
          color: routeLabel.selected ? CI.route : CI.secondaryRoute,
          borderRadius: BorderRadius.circular(7.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BoldSmall(
              text: routeLabel.timeText,
              context: context,
              textAlign: TextAlign.center,
              color: routeLabel.selected ? Colors.white : null,
            ),
            if (routeLabel.secondaryText != null)
              Small(
                text: routeLabel.secondaryText!,
                context: context,
                textAlign: TextAlign.center,
                color: routeLabel.selected ? Colors.white : null,
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
      ..moveTo(x * 0.75, y)
      ..lineTo(0, 0)
      ..lineTo(x, y * 0.75);
  }

  @override
  bool shouldRepaint(PointerPainter oldDelegate) {
    return false;
  }
}
