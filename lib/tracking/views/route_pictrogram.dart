import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/material.dart' as material show Image;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_projection.dart';

/// A pictogram of a route.
class RoutePictogram extends StatefulWidget {
  /// The route consisting of navigation nodes.
  final List<Position> route;

  /// The image for the start node.
  final Image? startImage;

  /// The image for the destination node.
  final Image? destinationImage;

  /// The width of the route line.
  final double lineWidth;

  /// The size of the icons.
  final double iconSize;

  const RoutePictogram({
    Key? key,
    required this.route,
    required this.startImage,
    required this.destinationImage,
    this.lineWidth = 3.0,
    this.iconSize = 10,
  }) : super(key: key);

  @override
  RoutePictogramState createState() => RoutePictogramState();
}

class RoutePictogramState extends State<RoutePictogram> with SingleTickerProviderStateMixin {
  double fraction = 0.0;
  late Animation<double> animation;
  late AnimationController controller;

  /// The background image of the map for the track.
  MemoryImage? backgroundImage;

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

    // Load the background image
    MapboxTileImageCache.fetchTile(coords: widget.route.map((e) => LatLng(e.latitude, e.longitude)).toList())
        .then((value) {
      setState(() {
        backgroundImage = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1000),
          child: backgroundImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: material.Image(
                    image: backgroundImage!,
                    fit: BoxFit.contain,
                    key: ValueKey(widget.route.hashCode),
                  ))
              : Container(),
        ),
        CustomPaint(
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
  final List<Position> route;
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
    // If the number of points is > 500, we reduce it to 500.
    // We do this by applying the following pattern:
    // - If n_points ~ or < 500, we keep all points
    // - If n_points < 1000, we keep every second point
    // - If n_points < 1500, we keep every third point
    // ...
    // Note: 1000 points is roughly 1000 seconds, which is 16 minutes of GPS.
    final List<Position> routeToDraw = [];
    const threshold = 500;
    if (route.length > threshold) {
      final step = route.length ~/ threshold;
      for (var i = 0; i < route.length; i += step) {
        routeToDraw.add(route[i]);
      }
    } else {
      routeToDraw.addAll(route);
    }

    final routeCount = routeToDraw.length;
    final routeCountFraction = routeCount * fraction;

    final bbox = MapboxMapProjection.mercatorBoundingBox(
        routeToDraw.map((Position e) => LatLng(e.latitude, e.longitude)).toList());
    if (bbox == null) return;

    final double maxLat = bbox.maxLat;
    final double minLat = bbox.minLat;
    final double maxLon = bbox.maxLon;
    final double minLon = bbox.minLon;

    // Draw the lines between the coordinates
    for (var i = 0; i < routeCountFraction - 1; i++) {
      final p1 = routeToDraw[i];
      final p2 = routeToDraw[i + 1];

      final x1 = (p1.longitude - minLon) / (maxLon - minLon) * size.width;
      final y1 = (p1.latitude - maxLat) / (minLat - maxLat) * size.height;
      final x2 = (p2.longitude - minLon) / (maxLon - minLon) * size.width;
      final y2 = (p2.latitude - maxLat) / (minLat - maxLat) * size.height;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint..color = CI.blue);
    }

    // Interpolate the last segment
    if (routeCountFraction + 1 < routeCount) {
      final p1 = routeToDraw[routeCountFraction.toInt()];
      final p2 = routeToDraw[routeCountFraction.toInt() + 1];
      final pct = routeCountFraction - routeCountFraction.toInt();
      final x1 = (p1.longitude - minLon) / (maxLon - minLon) * size.width;
      final y1 = (p1.latitude - maxLat) / (minLat - maxLat) * size.height;
      final x2 = (p2.longitude - minLon) / (maxLon - minLon) * size.width;
      final y2 = (p2.latitude - maxLat) / (minLat - maxLat) * size.height;
      final x2i = x1 + (x2 - x1) * pct;
      final y2i = y1 + (y2 - y1) * pct;

      canvas.drawLine(Offset(x1, y1), Offset(x2i, y2i), paint..color = CI.blue);
    }

    // Draw the circles at the start and end point.
    final pFirst = routeToDraw.first;
    final xFirst = (pFirst.longitude - minLon) / (maxLon - minLon) * size.width;
    final yFirst = (pFirst.latitude - maxLat) / (minLat - maxLat) * size.height;

    if (startImage != null) {
      paintImage(
          canvas: canvas,
          rect: Rect.fromCenter(center: Offset(xFirst, yFirst), width: iconSize, height: iconSize),
          image: startImage!);
    }
    final pLast = routeToDraw.last;
    final xLast = (pLast.longitude - minLon) / (maxLon - minLon) * size.width;
    final yLast = (pLast.latitude - maxLat) / (minLat - maxLat) * size.height;

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
