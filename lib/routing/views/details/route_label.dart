import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/route_labels.dart';
import 'package:priobike/routing/services/routing.dart';

class RouteLabel extends StatefulWidget {
  /// The id of the route.
  final int routId;

  /// The alignment of the route label.
  final RouteLabelAlignment alignment;

  /// If the map is currently moving.
  final bool isMapMoving;

  const RouteLabel({
    super.key,
    required this.routId,
    required this.alignment,
    required this.isMapMoving,
  });

  @override
  RouteLabelState createState() => RouteLabelState();
}

class RouteLabelState extends State<RouteLabel> {
  /// The selected state of the route label.
  bool selected = false;

  /// The time text of the route label.
  String timeText = "";

  /// The secondary text of the route label.
  String? secondaryText;

  /// The corner margin for the icon that is applied to the route label.
  static const double cornerIconMargin = 10;

  /// The corner icon size for the route label.
  static const double cornerIconSize = 20;

  /// The max width used for calculations.
  static const double maxWidth = 160;

  /// The max height used for calculations.
  static const double maxHeight = 60;

  /// The opacity of the route label.
  double opacity = 0;

  /// The timer for the opacity animation.
  Timer? opacityTimer;

  @override
  void initState() {
    super.initState();

    final routing = getIt<Routing>();

    if (routing.selectedRoute != null) selected = routing.selectedRoute!.id == widget.routId;
    if (routing.allRoutes != null && routing.allRoutes!.length > widget.routId) {
      final route = routing.allRoutes![widget.routId];
      timeText = route.timeText;
      secondaryText = route.mostUniqueAttribute;
    }
  }

  Future<void> animateOpacity() async {
    opacityTimer?.cancel();
    opacityTimer = Timer(const Duration(milliseconds: 150), () {
      setState(() {
        opacity = 1;
      });
    });
  }

  @override
  void dispose() {
    opacityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late Alignment pointerAlignment;
    bool flipX = false;
    bool flipY = false;

    switch (widget.alignment) {
      case RouteLabelAlignment.topLeft:
        pointerAlignment = Alignment.topLeft;
        break;
      case RouteLabelAlignment.bottomLeft:
        pointerAlignment = Alignment.bottomLeft;
        flipY = true;
        break;
      case RouteLabelAlignment.topRight:
        pointerAlignment = Alignment.topRight;
        flipX = true;
        break;
      case RouteLabelAlignment.bottomRight:
        pointerAlignment = Alignment.bottomRight;
        flipX = true;
        flipY = true;
        break;
    }

    bool top = widget.alignment == RouteLabelAlignment.topLeft || widget.alignment == RouteLabelAlignment.topRight;
    bool bottom =
        widget.alignment == RouteLabelAlignment.bottomLeft || widget.alignment == RouteLabelAlignment.bottomRight;
    bool left = widget.alignment == RouteLabelAlignment.topLeft || widget.alignment == RouteLabelAlignment.bottomLeft;
    bool right =
        widget.alignment == RouteLabelAlignment.topRight || widget.alignment == RouteLabelAlignment.bottomRight;

    animateOpacity();

    return AnimatedOpacity(
      opacity: widget.isMapMoving ? 0 : opacity,
      duration: const Duration(milliseconds: 150),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: pointerAlignment,
              child: Transform.flip(
                flipX: flipX,
                flipY: flipY,
                child: CustomPaint(
                  painter: PointerPainter(
                    context: context,
                    color: selected ? CI.route : CI.secondaryRoute,
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
              left: left ? cornerIconMargin : 0,
              top: top ? cornerIconMargin : 0,
              right: right ? cornerIconMargin : 0,
              bottom: bottom ? cornerIconMargin : 0,
            ),
            decoration: BoxDecoration(
              color: selected ? CI.route : CI.secondaryRoute,
              borderRadius: BorderRadius.circular(7.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BoldSmall(
                  text: timeText,
                  context: context,
                  textAlign: TextAlign.center,
                  color: selected ? Colors.white : Colors.black,
                ),
                if (secondaryText != null)
                  Small(
                    text: secondaryText!,
                    context: context,
                    textAlign: TextAlign.center,
                    color: selected ? Colors.white : Colors.black,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
