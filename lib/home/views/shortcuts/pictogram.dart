import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/common/mapbox_attribution.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';

class ShortcutPictogram extends StatefulWidget {
  /// The route of the shortcut, if it is a route shortcut.
  final Shortcut? shortcut;

  /// The height of the shortcut (width == height, because it is a square)
  final double height;

  /// The color of the pictogram.
  final Color color;

  /// The icon size of the pictogram.
  final double iconSize;

  /// The stroke width of the pictogram.
  final double strokeWidth;

  const ShortcutPictogram({
    super.key,
    this.shortcut,
    this.height = 200,
    this.color = Colors.black,
    this.iconSize = 64,
    this.strokeWidth = 6,
  });

  @override
  ShortcutPictogramState createState() => ShortcutPictogramState();
}

class ShortcutPictogramState extends State<ShortcutPictogram> {
  /// The background image of the map for the track.
  MemoryImage? backgroundImage;

  /// The brightness of the background image.
  Brightness? backgroundImageBrightness;

  /// The future of the background image.
  Future? backgroundImageFuture;

  /// Loads the background image.
  void loadBackgroundImage() {
    final fetchedBrightness = Theme.of(context).brightness;
    if (fetchedBrightness == backgroundImageBrightness) return;

    backgroundImageFuture?.ignore();
    List<LatLng> coords;
    if (widget.shortcut is ShortcutRoute) {
      final s = widget.shortcut as ShortcutRoute;
      coords = s.waypoints.map((e) => LatLng(e.lat, e.lon)).toList();
    } else if (widget.shortcut is ShortcutLocation) {
      final s = widget.shortcut as ShortcutLocation;
      coords = [
        LatLng(s.waypoint.lat - 0.01, s.waypoint.lon - 0.01),
        LatLng(s.waypoint.lat + 0.01, s.waypoint.lon + 0.01),
      ];
    } else {
      throw ArgumentError('Shortcut is neither ShortcutRoute nor ShortcutLocation');
    }
    backgroundImageFuture = MapboxTileImageCache.requestTile(
      coords: coords,
      brightness: fetchedBrightness,
      mapPadding: 0.45,
    ).then((value) {
      if (!mounted) return;
      if (value == null) return;
      final brightnessNow = Theme.of(context).brightness;
      if (fetchedBrightness != brightnessNow) return;

      setState(() {
        backgroundImage = value;
        backgroundImageBrightness = brightnessNow;
      });
    });
  }

  @override
  void didUpdateWidget(covariant ShortcutPictogram oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadBackgroundImage();
  }

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) => loadBackgroundImage());
  }

  @override
  void dispose() {
    backgroundImageFuture?.ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width == height, because the map is a square
      width: widget.height,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            child: backgroundImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image(
                      image: backgroundImage!,
                      fit: BoxFit.contain,
                      key: UniqueKey(),
                    ),
                  )
                : Container(),
          ),
          if (widget.shortcut is ShortcutLocation)
            Transform.translate(
              offset: Offset(0, -(widget.iconSize / 2)),
              child: Icon(
                Icons.location_on,
                color: widget.color,
                size: widget.iconSize,
              ),
            )
          else if (widget.shortcut is ShortcutRoute)
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomPaint(
                painter: ShortcutRoutePainter(
                  shortcut: widget.shortcut as ShortcutRoute,
                  color: widget.color,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
            ),
          const MapboxAttribution(
            top: 8,
            right: 8,
          ),
        ],
      ),
    );
  }
}

class ShortcutRoutePainter extends CustomPainter {
  final ShortcutRoute shortcut;
  final Color color;
  final double strokeWidth;

  ShortcutRoutePainter({required this.shortcut, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final waypoints = shortcut.waypoints;
    final waypointCount = waypoints.length;

    final bbox = MapboxMapProjection.mercatorBoundingBox(waypoints.map((e) => LatLng(e.lat, e.lon)).toList(), 0.45);
    if (bbox == null) return;

    List<double> distances = [];
    double maxDistance = 0.0;
    for (var i = 0; i < waypointCount - 1; i++) {
      final waypoint1 = waypoints[i];
      final waypoint2 = waypoints[i + 1];
      final distance = sqrt(pow(waypoint2.lat - waypoint1.lat, 2) + pow(waypoint2.lon - waypoint1.lon, 2));
      if (distance > maxDistance) maxDistance = distance;
      distances.add(distance);
    }

    // #steps heuristic
    List<int> steps = [];
    final distancesCount = distances.length;
    for (var i = 0; i < distancesCount; i++) {
      final step = (15 * distances[i] / maxDistance).ceil();
      steps.add(step);
    }

    // Draw the lines between the waypoints
    for (var i = 0; i < waypointCount - 1; i++) {
      final waypoint1 = waypoints[i];
      final waypoint2 = waypoints[i + 1];

      final x1 = (waypoint1.lon - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y1 = (waypoint1.lat - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;
      final x2 = (waypoint2.lon - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y2 = (waypoint2.lat - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;

      // Draw a dashed ballistic line between the waypoints
      // offset
      final x2Off = x2 - x1;
      final y2Off = y2 - y1;
      // rotation
      double rotX(double x, double y, double alpha) {
        return x * cos(alpha) - y * sin(alpha);
      }

      double rotY(double x, double y, double alpha) {
        return x * sin(alpha) + y * cos(alpha);
      }

      final alphaOff = atan((y2Off) / (x2Off));
      final x2Rot = rotX(x2Off, y2Off, -alphaOff);
      double x1_ = x1;
      double y1_ = y1;
      int j = 0;
      for (var x = 0.0; x.abs() < (x2Rot - (x2Rot / steps[i])).abs(); x += x2Rot / steps[i]) {
        double y = 0.02 * (pow(x, 2) - x2Rot * x);
        double x2_ = rotX(x, y, alphaOff) + x1;
        double y2_ = rotY(x, y, alphaOff) + y1;
        if (j % 4 == 0) canvas.drawLine(Offset(x1_, y1_), Offset(x2_, y2_), paint);
        x1_ = x2_;
        y1_ = y2_;
        j++;
      }
    }

    // Draw the circles at the waypoints
    for (var i = 0; i < waypointCount; i++) {
      final waypoint = waypoints[i];

      final x = (waypoint.lon - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y = (waypoint.lat - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;

      if (i == 0) {
        canvas.drawCircle(Offset(x, y), strokeWidth / 2, paint);
      } else if (i == waypointCount - 1) {
        canvas.drawCircle(Offset(x, y), strokeWidth, paint);
      } else {
        canvas.drawCircle(Offset(x, y), strokeWidth / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
