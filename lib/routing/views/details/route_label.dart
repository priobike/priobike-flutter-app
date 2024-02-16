import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/models/route_label.dart';

const double cornerMargin = 13.5;

class RouteLabelIcon extends StatelessWidget {
  final RouteLabel routeLabel;

  final Function onPressed;

  const RouteLabelIcon({super.key, required this.routeLabel, required this.onPressed});

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
      Container(
        // 1 pixel less then the height of the triangle so that the border gets hidden.
        margin: EdgeInsets.only(
          left: routeLabel.routeLabelOrientationHorizontal == RouteLabelOrientationHorizontal.left ? cornerMargin : 0,
          top: routeLabel.routeLabelOrientationVertical == RouteLabelOrientationVertical.top ? cornerMargin : 0,
          right: routeLabel.routeLabelOrientationHorizontal == RouteLabelOrientationHorizontal.right ? cornerMargin : 0,
          bottom: routeLabel.routeLabelOrientationVertical == RouteLabelOrientationVertical.bottom ? cornerMargin : 0,
        ),
        decoration: BoxDecoration(
          color: routeLabel.selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1, color: Theme.of(context).colorScheme.onTertiary),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BoldSmall(
              text: routeLabel.text,
              context: context,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      Positioned.fill(
        child: Align(
          alignment: pointerAlignment,
          child: Transform.flip(
            flipX: flipX,
            flipY: flipY,
            child: CustomPaint(
              painter: PointerPainter(
                context: context,
              ),
              child: const SizedBox(
                height: 20,
                width: 20,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class PointerPainter extends CustomPainter {
  final BuildContext context;

  PointerPainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()..color = Theme.of(context).colorScheme.background;

    Paint sidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Theme.of(context).colorScheme.onTertiary
      ..strokeWidth = 1;

    // Draw the background;
    canvas.drawPath(getTrianglePath(size.width, size.height), backgroundPaint);
    // Draw border lines to the top.
    canvas.drawPath(getTrianglePath(size.width, size.height), sidePaint);
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
