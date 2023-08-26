import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';

/// A pictogram of a shortcut.
/// The pictogram contains circles where the waypoints are located,
/// and lines between the waypoints. The coordinates of the waypoints
/// are normalized to the size of the pictogram.
class ShortcutRoutePictogram extends StatefulWidget {
  final ShortcutRoute shortcut;
  final double height;
  final double width;
  final Color color;

  const ShortcutRoutePictogram({
    Key? key,
    required this.shortcut,
    this.height = 200,
    this.width = 200,
    this.color = Colors.black,
  }) : super(key: key);

  @override
  ShortcutRoutePictogramState createState() => ShortcutRoutePictogramState();
}

class ShortcutRoutePictogramState extends State<ShortcutRoutePictogram> {
  /// The background image of the map for the track.
  MemoryImage? backgroundImage;

  @override
  void initState() {
    super.initState();

    // Load the background image
    MapboxTileImageCache.fetchTile(coords: widget.shortcut.waypoints.map((e) => LatLng(e.lat, e.lon)).toList())
        .then((value) {
      setState(() {
        backgroundImage = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
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
                      key: ValueKey(widget.shortcut.hashCode),
                    ),
                  )
                : Container(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: ShortcutRoutePainter(shortcut: widget.shortcut, color: widget.color),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ShortcutRoutePainter extends CustomPainter {
  final ShortcutRoute shortcut;
  final Color color;

  ShortcutRoutePainter({required this.shortcut, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final waypoints = shortcut.waypoints;
    final waypointCount = waypoints.length;

    final bbox = MapboxMapProjection.mercatorBoundingBox(waypoints.map((e) => LatLng(e.lat, e.lon)).toList());
    if (bbox == null) return;

    // Draw the lines between the waypoints
    for (var i = 0; i < waypointCount - 1; i++) {
      final waypoint1 = waypoints[i];
      final waypoint2 = waypoints[i + 1];

      final x1 = (waypoint1.lon - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y1 = (waypoint1.lat - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;
      final x2 = (waypoint2.lon - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y2 = (waypoint2.lat - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;

      // Draw a dashed line between the waypoints
      const dashCount = 5;
      for (var j = 0; j < dashCount; j++) {
        final x1_ = x1 + (x2 - x1) / dashCount * j;
        final y1_ = y1 + (y2 - y1) / dashCount * j;
        final x2_ = x1 + (x2 - x1) / dashCount * (j + 1);
        final y2_ = y1 + (y2 - y1) / dashCount * (j + 1);

        if (j % 2 == 0) {
          canvas.drawLine(Offset(x1_, y1_), Offset(x2_, y2_), paint);
        }
      }
    }

    // Draw the circles at the waypoints
    for (var i = 0; i < waypointCount; i++) {
      final waypoint = waypoints[i];

      final x = (waypoint.lon - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y = (waypoint.lat - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;

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

class ShortcutLocationPictogram extends StatefulWidget {
  final ShortcutLocation shortcut;
  final double height;
  final double width;
  final Color color;

  const ShortcutLocationPictogram({
    Key? key,
    required this.shortcut,
    this.height = 200,
    this.width = 200,
    this.color = Colors.black,
  }) : super(key: key);

  @override
  ShortcutLocationPictogramState createState() => ShortcutLocationPictogramState();
}

class ShortcutLocationPictogramState extends State<ShortcutLocationPictogram> {
  /// The background image of the map for the track.
  MemoryImage? backgroundImage;

  @override
  void initState() {
    super.initState();

    // Load the background image
    MapboxTileImageCache.fetchTile(coords: [
      LatLng(widget.shortcut.waypoint.lat - 0.01, widget.shortcut.waypoint.lon - 0.01),
      LatLng(widget.shortcut.waypoint.lat + 0.01, widget.shortcut.waypoint.lon + 0.01),
    ]).then((value) {
      setState(() {
        backgroundImage = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
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
                      key: ValueKey(widget.shortcut.hashCode),
                    ),
                  )
                : Container(),
          ),
          Transform.translate(
            offset: const Offset(0, -32),
            child: Icon(
              Icons.location_on,
              color: widget.color,
              size: 64,
            ),
          )
        ],
      ),
    );
  }
}
