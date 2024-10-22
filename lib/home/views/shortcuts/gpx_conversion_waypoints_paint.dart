import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/home/services/gpx_conversion.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';

class GPXConversionWaypointsPaint extends StatefulWidget {
  /// waypoints from a gpx
  final List<Wpt> wpts;

  final GpxConversion gpxConversionNotifier;

  /// The color of the pictogram.
  final Color gpxColor;
  final Color approxColor;

  const GPXConversionWaypointsPaint({
    super.key,
    required this.wpts,
    this.gpxColor = CI.radkulturRed,
    required this.approxColor,
    required this.gpxConversionNotifier,
  });

  @override
  GPXConversionWaypointsPaintState createState() => GPXConversionWaypointsPaintState();
}

class GPXConversionWaypointsPaintState extends State<GPXConversionWaypointsPaint> {
  late Routing routing;

  List<Wpt> recWpts = [];

  void updateRecWpts() {
    setState(() => recWpts = widget.gpxConversionNotifier.wpts);
  }

  @override
  void initState() {
    super.initState();
    routing = getIt<Routing>();
    widget.gpxConversionNotifier.addListener(updateRecWpts);
  }

  @override
  void dispose() {
    widget.gpxConversionNotifier.removeListener(updateRecWpts);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MapboxMapProjectionBoundingBox? bbox =
        MapboxMapProjection.mercatorBoundingBox(widget.wpts.map((e) => LatLng(e.lat!, e.lon!)).toList(), 0.45);
    return CustomPaint(
      painter: WaypointsPainter(wpts: widget.wpts, color: widget.gpxColor, bbox: bbox),
      child: CustomPaint(painter: WaypointsPainter(wpts: recWpts, color: widget.approxColor, bbox: bbox)),
    );
  }
}

class WaypointsPainter extends CustomPainter {
  final List<Wpt> wpts;
  final Color color;
  MapboxMapProjectionBoundingBox? bbox;

  WaypointsPainter({required this.wpts, required this.color, this.bbox});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final waypoints = wpts;
    final waypointCount = waypoints.length;

    bbox ??= MapboxMapProjection.mercatorBoundingBox(waypoints.map((e) => LatLng(e.lat!, e.lon!)).toList(), 0.45);

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

      final x1 = (waypoint1.lon! - bbox!.minLon) / (bbox!.maxLon - bbox!.minLon) * size.width;
      final y1 = (waypoint1.lat! - bbox!.maxLat) / (bbox!.minLat - bbox!.maxLat) * size.height;
      final x2 = (waypoint2.lon! - bbox!.minLon) / (bbox!.maxLon - bbox!.minLon) * size.width;
      final y2 = (waypoint2.lat! - bbox!.maxLat) / (bbox!.minLat - bbox!.maxLat) * size.height;

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

      final x = (waypoint.lon! - bbox!.minLon) / (bbox!.maxLon - bbox!.minLon) * size.width;
      final y = (waypoint.lat! - bbox!.maxLat) / (bbox!.minLat - bbox!.maxLat) * size.height;

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
