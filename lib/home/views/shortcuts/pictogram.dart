import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';

/// A pictogram of a shortcut.
/// The pictogram contains circles where the waypoints are located,
/// and lines between the waypoints. The coordinates of the waypoints
/// are normalized to the size of the pictogram.
class ShortcutPictogram extends StatelessWidget {
  final Shortcut shortcut;
  final double height;
  final double width;
  final Color color;

  const ShortcutPictogram({
    Key? key,
    required this.shortcut,
    this.height = 200,
    this.width = 200,
    this.color = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: width,
        height: height,
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: ShortcutPainter(shortcut: shortcut, color: color),
          ),
        ),
      ),
    );
  }
}

class ShortcutPainter extends CustomPainter {
  final Shortcut shortcut;
  final Color color;

  ShortcutPainter({required this.shortcut, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final waypoints = shortcut.waypoints;
    final waypointCount = waypoints.length;

    double? maxLat;
    double? minLat;
    double? maxLon;
    double? minLon;

    // Find the bounding box of the waypoints
    for (var i = 0; i < waypointCount; i++) {
      final waypoint = waypoints[i];
      if (maxLat == null || waypoint.lat > maxLat) {
        maxLat = waypoint.lat;
      }
      if (minLat == null || waypoint.lat < minLat) {
        minLat = waypoint.lat;
      }
      if (maxLon == null || waypoint.lon > maxLon) {
        maxLon = waypoint.lon;
      }
      if (minLon == null || waypoint.lon < minLon) {
        minLon = waypoint.lon;
      }
    }
    if (maxLat == null || minLat == null || maxLon == null || minLon == null) {
      return;
    }
    if (maxLat == minLat || maxLon == minLon) {
      return;
    }

    // If dLat > dLon, pad the longitude, otherwise pad the latitude to ensure that the aspect ratio is 1.
    // Don't center the padding, but align the padding to the top left.
    final dLat = maxLat - minLat;
    final dLon = maxLon - minLon;
    if (dLat > dLon) {
      final d = (dLat - dLon);
      maxLon += d;
    } else {
      final d = (dLon - dLat);
      minLat -= d;
    }

    // Draw the lines between the waypoints
    for (var i = 0; i < waypointCount - 1; i++) {
      final waypoint1 = waypoints[i];
      final waypoint2 = waypoints[i + 1];

      final x1 = (waypoint1.lon - minLon) / (maxLon - minLon) * size.width;
      final y1 = (waypoint1.lat - maxLat) / (minLat - maxLat) * size.height;
      final x2 = (waypoint2.lon - minLon) / (maxLon - minLon) * size.width;
      final y2 = (waypoint2.lat - maxLat) / (minLat - maxLat) * size.height;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // Draw the circles at the waypoints
    for (var i = 0; i < waypointCount; i++) {
      final waypoint = waypoints[i];

      final x = (waypoint.lon - minLon) / (maxLon - minLon) * size.width;
      final y = (waypoint.lat - maxLat) / (minLat - maxLat) * size.height;

      if (i == 0) {
        canvas.drawCircle(Offset(x, y), 4, paint);
      } else if (i == waypointCount - 1) {
        canvas.drawCircle(Offset(x, y), 8, paint);
      } else {
        canvas.drawCircle(Offset(x, y), 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
