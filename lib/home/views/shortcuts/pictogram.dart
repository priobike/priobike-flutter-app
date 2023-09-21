import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/common/mapbox_attribution.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';

enum ShortcutType {
  route,
  location,
}

class ShortcutPictogram extends StatefulWidget {
  /// The type of the shortcut: route or location.
  final ShortcutType type;

  /// The route of the shortcut, if it is a route shortcut.
  final ShortcutRoute? shortcutRoute;

  /// The location of the shortcut, if it is a location shortcut.
  final ShortcutLocation? shortcutLocation;

  /// The height of the shortcut (width == height, because the it is a square)
  final double height;

  /// The color of the shortcut.
  final Color color;

  const ShortcutPictogram({
    Key? key,
    required this.type,
    this.shortcutRoute,
    this.shortcutLocation,
    this.height = 200,
    this.color = Colors.black,
  }) : super(key: key);

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
    final coords = widget.type == ShortcutType.route
        ? widget.shortcutRoute!.waypoints.map((e) => LatLng(e.lat, e.lon)).toList()
        : [
            LatLng(widget.shortcutLocation!.waypoint.lat - 0.01, widget.shortcutLocation!.waypoint.lon - 0.01),
            LatLng(widget.shortcutLocation!.waypoint.lat + 0.01, widget.shortcutLocation!.waypoint.lon + 0.01),
          ];
    backgroundImageFuture = MapboxTileImageCache.requestTile(
      coords: coords,
      brightness: Theme.of(context).brightness,
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
    if (widget.type == ShortcutType.route && widget.shortcutRoute == null) {
      throw ArgumentError.notNull('shortcutRoute');
    }
    if (widget.type == ShortcutType.location && widget.shortcutLocation == null) {
      throw ArgumentError.notNull('shortcutLocation');
    }

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
          widget.type == ShortcutType.location
              ? Transform.translate(
                  offset: const Offset(0, -26),
                  child: Icon(
                    Icons.location_on,
                    color: widget.color,
                    size: 64,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomPaint(
                    painter: ShortcutRoutePainter(
                      shortcut: widget.shortcutRoute!,
                      color: widget.color,
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

        if (j % 2 == 0) canvas.drawLine(Offset(x1_, y1_), Offset(x2_, y2_), paint);
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
