import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/views/shortcuts/gpx_conversion.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';

class WaypointsPaint extends StatefulWidget {
  /// waypoints from a gpx
  final List<Wpt> wpts;

  /// The color of the pictogram.
  final Color gpxColor;
  final Color approxColor;

  const WaypointsPaint({
    Key? key,
    required this.wpts,
    this.gpxColor = CI.radkulturRed,
    this.approxColor = CI.radkulturGreen,
  }) : super(key: key);

  @override
  WaypointsPaintState createState() => WaypointsPaintState();
}

class WaypointsPaintState extends State<WaypointsPaint> {
  /// The background image of the map for the track.
  MemoryImage? backgroundImage;

  /// The brightness of the background image.
  Brightness? backgroundImageBrightness;

  /// The future of the background image.
  Future? backgroundImageFuture;

  late Routing routing;

  /// Loads the background image.
  void loadBackgroundImage() {
    final fetchedBrightness = Theme.of(context).brightness;
    if (fetchedBrightness == backgroundImageBrightness) return;

    backgroundImageFuture?.ignore();
    List<LatLng> coords;
    List<Wpt> wpts = widget.wpts;
    coords = wpts.map((Wpt e) => LatLng(e.lat!, e.lon!)).toList();
    backgroundImageFuture = MapboxTileImageCache.requestTile(
      coords: coords,
      brightness: fetchedBrightness,
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

  Future<void> convertGpxToWaypoints(List<Wpt> points) async {
    if (points.isEmpty) return;
    List<Waypoint> waypoints = await reduceWpts(points, routing);
    if (mounted) {
      showSaveShortcutSheet(context,
        shortcut: ShortcutRoute(
          id: UniqueKey().toString(),
          name: "Strecke aus GPX",
          waypoints: waypoints,
        ));
    }
    return;
  }

  @override
  void didUpdateWidget(covariant WaypointsPaint oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadBackgroundImage();
  }

  @override
  void initState() {
    super.initState();
    routing = getIt<Routing>();
    SchedulerBinding.instance.addPostFrameCallback((_) => loadBackgroundImage());
  }

  @override
  void dispose() {
    backgroundImageFuture?.ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WaypointsPainter(
      wpts: widget.wpts,
        color: widget.gpxColor,
      ),
      child: CustomPaint(
        painter: WaypointsPainter(
          wpts: widget.wpts.sublist(0, 400),
          color: widget.approxColor,
        ),
      ),
    );
  }
}


class WaypointsPainter extends CustomPainter {
  final List<Wpt> wpts;
  final Color color;

  WaypointsPainter({required this.wpts, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final waypoints = wpts;
    final waypointCount = waypoints.length;

    final bbox = MapboxMapProjection.mercatorBoundingBox(waypoints.map((e) => LatLng(e.lat!, e.lon!)).toList());
    if (bbox == null) return;

    List<double> distances = [];
    double maxDistance = 0.0;
    for (var i = 0; i < waypointCount - 1; i++) {
      final waypoint1 = waypoints[i];
      final waypoint2 = waypoints[i + 1];
      final distance = sqrt(pow(waypoint2.lat! - waypoint1.lat!, 2) + pow(waypoint2.lon! - waypoint1.lon!, 2));
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

      final x1 = (waypoint1.lon! - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y1 = (waypoint1.lat! - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;
      final x2 = (waypoint2.lon! - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y2 = (waypoint2.lat! - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;

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

      final x = (waypoint.lon! - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y = (waypoint.lat! - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;

      if (i == 0) {
        canvas.drawCircle(Offset(x, y), 3, paint);
      } else if (i == waypointCount - 1) {
        canvas.drawCircle(Offset(x, y), 6, paint);
      } else {
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
