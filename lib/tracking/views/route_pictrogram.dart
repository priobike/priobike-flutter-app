import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/routing/models/navigation.dart';

/// A pictogram of a route.
class RoutePictogram extends StatefulWidget {
  /// The route consisting of navigation nodes.
  final List<NavigationNode> route;

  /// The image for the start node.
  final Image? startImage;

  /// The image for the destination node.
  final Image? destinationImage;

  /// The width of the route line.
  final double lineWidth;

  /// The size of the icons.
  final double iconSize;

  const RoutePictogram({
    super.key,
    required this.route,
    required this.startImage,
    required this.destinationImage,
    this.lineWidth = 3.0,
    this.iconSize = 10,
  });

  @override
  RoutePictogramState createState() => RoutePictogramState();
}

class RoutePictogramState extends State<RoutePictogram> with SingleTickerProviderStateMixin {
  double fraction = 0.0;
  late Animation<double> animation;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    animation = Tween<double>(begin: 0, end: 1).animate(controller)
      ..addListener(() {
        setState(() {
          fraction = animation.value;
        });
      });
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // Glow
        Opacity(
          opacity: Theme.of(context).colorScheme.brightness == Brightness.dark ? 0.5 : 0,
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: RoutePainter(
                fraction: fraction,
                route: widget.route,
                blurRadius: 2,
                startImage: widget.startImage,
                destinationImage: widget.destinationImage,
                lineWidth: widget.lineWidth,
                iconSize: widget.iconSize,
              ),
            ),
          ),
        ),
        // Shadow
        Opacity(
          opacity: Theme.of(context).colorScheme.brightness == Brightness.dark ? 0 : 0.4,
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: RoutePainter(
                fraction: fraction,
                route: widget.route,
                blurRadius: 2,
                startImage: widget.startImage,
                destinationImage: widget.destinationImage,
                lineWidth: widget.lineWidth,
                iconSize: widget.iconSize,
              ),
            ),
          ),
        ),
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: RoutePainter(
              fraction: fraction,
              route: widget.route,
              blurRadius: 0,
              startImage: widget.startImage,
              destinationImage: widget.destinationImage,
              lineWidth: widget.lineWidth,
              iconSize: widget.iconSize,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.stop();
    controller.dispose();
    super.dispose();
  }
}

class RoutePainter extends CustomPainter {
  final double fraction;
  final double blurRadius;
  final List<NavigationNode> route;
  final Image? startImage;
  final Image? destinationImage;

  final double lineWidth;
  final double iconSize;

  RoutePainter({
    required this.fraction,
    required this.blurRadius,
    required this.route,
    required this.startImage,
    required this.destinationImage,
    required this.lineWidth,
    required this.iconSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (blurRadius > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
    }

    // If the route is too long, it will slow down the app.
    // Therefore, we need to reduce the number of points.
    // If the number of points is > 1000, we reduce it to 1000.
    // We do this by applying the following pattern:
    // - If n_points ~ or < 1000, we keep all points
    // - If n_points < 2000, we keep every second point
    // - If n_points < 3000, we keep every third point
    // ...
    // Note: 1000 points is roughly 1000 seconds, which is 16 minutes of GPS.
    final List<NavigationNode> routeToDraw = [];
    if (route.length > 1000) {
      final step = route.length ~/ 1000;
      for (var i = 0; i < route.length; i += step) {
        routeToDraw.add(route[i]);
      }
    } else {
      routeToDraw.addAll(route);
    }

    final routeCount = routeToDraw.length;
    final routeCountFraction = routeCount * fraction;

    double? maxLat;
    double? minLat;
    double? maxLon;
    double? minLon;

    // Find the bounding box of the waypoints
    for (var i = 0; i < routeCount; i++) {
      final p = routeToDraw[i];
      if (maxLat == null || p.lat > maxLat) {
        maxLat = p.lat;
      }
      if (minLat == null || p.lat < minLat) {
        minLat = p.lat;
      }
      if (maxLon == null || p.lon > maxLon) {
        maxLon = p.lon;
      }
      if (minLon == null || p.lon < minLon) {
        minLon = p.lon;
      }
    }
    if (maxLat == null || minLat == null || maxLon == null || minLon == null) {
      return;
    }
    if (maxLat == minLat || maxLon == minLon) {
      return;
    }

    // If dLat > dLon, pad the longitude, otherwise pad the latitude to ensure that the aspect ratio is 1.
    final dLat = maxLat - minLat;
    final dLon = maxLon - minLon;
    if (dLat > dLon) {
      final d = (dLat - dLon) / 2;
      minLon -= d;
      maxLon += d;
    } else {
      final d = (dLon - dLat) / 2;
      minLat -= d;
      maxLat += d;
    }

    // Draw the lines between the coordinates
    for (var i = 0; i < routeCountFraction - 1; i++) {
      final p1 = routeToDraw[i];
      final p2 = routeToDraw[i + 1];

      final x1 = (p1.lon - minLon) / (maxLon - minLon) * size.width;
      final y1 = (p1.lat - maxLat) / (minLat - maxLat) * size.height;
      final x2 = (p2.lon - minLon) / (maxLon - minLon) * size.width;
      final y2 = (p2.lat - maxLat) / (minLat - maxLat) * size.height;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint..color = CI.blue);
    }

    // Interpolate the last segment
    if (routeCountFraction + 1 < routeCount) {
      final p1 = routeToDraw[routeCountFraction.toInt()];
      final p2 = routeToDraw[routeCountFraction.toInt() + 1];
      final pct = routeCountFraction - routeCountFraction.toInt();
      final x1 = (p1.lon - minLon) / (maxLon - minLon) * size.width;
      final y1 = (p1.lat - maxLat) / (minLat - maxLat) * size.height;
      final x2 = (p2.lon - minLon) / (maxLon - minLon) * size.width;
      final y2 = (p2.lat - maxLat) / (minLat - maxLat) * size.height;
      final x2i = x1 + (x2 - x1) * pct;
      final y2i = y1 + (y2 - y1) * pct;

      canvas.drawLine(Offset(x1, y1), Offset(x2i, y2i), paint..color = CI.blue);
    }

    // Draw the circles at the start and end point.
    final pFirst = routeToDraw.first;
    final xFirst = (pFirst.lon - minLon) / (maxLon - minLon) * size.width;
    final yFirst = (pFirst.lat - maxLat) / (minLat - maxLat) * size.height;

    if (startImage != null) {
      paintImage(
          canvas: canvas,
          rect: Rect.fromCenter(center: Offset(xFirst, yFirst), width: iconSize, height: iconSize),
          image: startImage!);
    }
    final pLast = routeToDraw.last;
    final xLast = (pLast.lon - minLon) / (maxLon - minLon) * size.width;
    final yLast = (pLast.lat - maxLat) / (minLat - maxLat) * size.height;

    if (destinationImage != null) {
      paintImage(
          canvas: canvas,
          rect: Rect.fromCenter(center: Offset(xLast, yLast), width: iconSize, height: iconSize),
          image: destinationImage!);
    }
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}
