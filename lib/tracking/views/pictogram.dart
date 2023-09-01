import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/common/mapbox_attribution.dart';

/// A pictogram of a track.
class TrackPictogram extends StatefulWidget {
  /// The Positions of the track.
  final List<Position> track;

  /// The color of the line for the minimum speed.
  final Color minSpeedColor;

  /// The color of the line for the maximum speed.
  final Color maxSpeedColor;

  /// The blur radius of the line.
  final double blurRadius;

  /// The image for the start node.
  final ui.Image? startImage;

  /// The image for the destination node.
  final ui.Image? destinationImage;

  /// The width of the route line.
  final double lineWidth;

  /// The size of the icons.
  final double iconSize;

  /// If the speed should be displayed.
  final bool showSpeed;

  const TrackPictogram({
    Key? key,
    required this.track,
    required this.blurRadius,
    this.minSpeedColor = Colors.green,
    this.maxSpeedColor = Colors.red,
    this.startImage,
    this.destinationImage,
    this.lineWidth = 3.0,
    this.iconSize = 10,
    this.showSpeed = true,
  }) : super(key: key);

  @override
  TrackPictogramState createState() => TrackPictogramState();
}

class TrackPictogramState extends State<TrackPictogram> with SingleTickerProviderStateMixin {
  double fraction = 0.0;
  late Animation<double> animation;
  late AnimationController controller;
  double? maxSpeed;
  double minSpeed = 0.0;

  /// The background image of the map for the track.
  MemoryImage? backgroundImage;

  /// The future of the background image.
  Future? backgroundImageFuture;

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

    // Find the min and max speed
    for (var i = 0; i < widget.track.length; i++) {
      final p = widget.track[i];
      if (maxSpeed == null || p.speed > maxSpeed!) {
        maxSpeed = p.speed;
      }
    }

    // Load the background image
    backgroundImageFuture =
        MapboxTileImageCache.requestTile(coords: widget.track.map((e) => LatLng(e.latitude, e.longitude)).toList())
            .then((value) {
      setState(() {
        backgroundImage = value;
      });
    });
  }

  @override
  void dispose() {
    backgroundImageFuture?.ignore();
    controller.stop();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1000),
          child: backgroundImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image(
                    image: backgroundImage!,
                    fit: BoxFit.contain,
                    key: UniqueKey(),
                  ),
                )
              : Container(),
        ),

        CustomPaint(
          painter: TrackPainter(
            fraction: fraction,
            track: widget.track,
            blurRadius: 0,
            minSpeedColor: widget.minSpeedColor,
            maxSpeedColor: widget.maxSpeedColor,
            maxSpeed: maxSpeed,
            minSpeed: minSpeed,
            startImage: widget.startImage,
            destinationImage: widget.destinationImage,
            lineWidth: widget.lineWidth,
            iconSize: widget.iconSize,
            showSpeed: widget.showSpeed,
          ),
        ),

        // Legend
        if (widget.showSpeed)
          Positioned(
            bottom: 8,
            left: 12,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [widget.minSpeedColor, widget.maxSpeedColor],
                    ),
                  ),
                ),
                const SmallHSpace(),
                Content(text: '0 - ${((maxSpeed ?? 0) * 3.6).toInt()} km/h', context: context),
              ],
            ),
          ),
        //Mapbox Attribution Logo
        const MapboxAttribution(
          top: 10,
          right: 10,
          width: 64,
        ),
      ],
    );
  }
}

class TrackPainter extends CustomPainter {
  final double fraction;
  final double blurRadius;
  final List<Position> track;
  final Color minSpeedColor;
  final Color maxSpeedColor;
  double? maxSpeed;
  double? minSpeed;
  final ui.Image? startImage;
  final ui.Image? destinationImage;
  final double lineWidth;
  final double iconSize;
  final bool showSpeed;

  TrackPainter({
    required this.fraction,
    required this.blurRadius,
    required this.track,
    required this.minSpeedColor,
    required this.maxSpeedColor,
    required this.lineWidth,
    required this.iconSize,
    required this.showSpeed,
    this.maxSpeed,
    this.minSpeed,
    this.startImage,
    this.destinationImage,
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

    // If the track is too long, it will slow down the app.
    // Therefore, we need to reduce the number of points.
    // If the number of points is > 500, we reduce it to 500.
    // We do this by applying the following pattern:
    // - If n_points ~ or < 500, we keep all points
    // - If n_points < 1000, we keep every second point
    // - If n_points < 1500, we keep every third point
    // ...
    // Note: 1000 points is roughly 1000 seconds, which is 16 minutes of GPS.
    final List<Position> trackToDraw = [];
    const threshold = 500;
    if (track.length > threshold) {
      final step = track.length ~/ threshold;
      for (var i = 0; (i + step) < track.length; i += step) {
        trackToDraw.add(track[i]);
      }
    } else {
      trackToDraw.addAll(track);
    }

    final trackCount = trackToDraw.length;
    final trackCountFraction = trackCount * fraction;

    final bbox = MapboxMapProjection.mercatorBoundingBox(
        trackToDraw.map((Position p) => LatLng(p.latitude, p.longitude)).toList());
    if (bbox == null) return;

    // Draw the lines between the coordinates
    for (var i = 0; i < trackCountFraction - 1; i++) {
      final p1 = trackToDraw[i];
      final p2 = trackToDraw[i + 1];

      final x1 = (p1.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y1 = (p1.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;
      final x2 = (p2.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y2 = (p2.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;

      var color = CI.blue;
      if (showSpeed && minSpeed != null && maxSpeed != null && minSpeed != maxSpeed) {
        color = Color.lerp(minSpeedColor, maxSpeedColor, (p1.speed - minSpeed!) / (maxSpeed! - minSpeed!))!;
      }
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint..color = color);
    }

    // Interpolate the last segment
    if (trackCountFraction + 1 < trackCount) {
      final p1 = trackToDraw[trackCountFraction.toInt()];
      final p2 = trackToDraw[trackCountFraction.toInt() + 1];
      final pct = trackCountFraction - trackCountFraction.toInt();
      final x1 = (p1.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y1 = (p1.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;
      final x2 = (p2.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
      final y2 = (p2.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;
      final x2i = x1 + (x2 - x1) * pct;
      final y2i = y1 + (y2 - y1) * pct;

      var color = CI.blue;
      if (showSpeed && minSpeed != null && maxSpeed != null && minSpeed != maxSpeed) {
        color = Color.lerp(minSpeedColor, maxSpeedColor, (p1.speed - minSpeed!) / (maxSpeed! - minSpeed!))!;
      }
      canvas.drawLine(Offset(x1, y1), Offset(x2i, y2i), paint..color = color);
    }

    // Draw the circles at the start and end point.
    final pFirst = trackToDraw.first;
    final xFirst = (pFirst.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
    final yFirst = (pFirst.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;

    if (startImage != null) {
      paintImage(
          canvas: canvas,
          rect: Rect.fromCenter(center: Offset(xFirst, yFirst), width: iconSize, height: iconSize),
          image: startImage!);
    }
    final pLast = trackToDraw.last;
    final xLast = (pLast.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * size.width;
    final yLast = (pLast.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * size.height;

    if (destinationImage != null) {
      paintImage(
          canvas: canvas,
          rect: Rect.fromCenter(center: Offset(xLast, yLast), width: iconSize, height: iconSize),
          image: destinationImage!);
    }
  }

  @override
  bool shouldRepaint(covariant TrackPainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}
