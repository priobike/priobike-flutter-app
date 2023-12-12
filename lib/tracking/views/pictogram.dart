import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_projection.dart';
import 'package:priobike/common/mapbox_attribution.dart';

/// A pictogram of a track.
class TrackPictogram extends StatefulWidget {
  /// The Positions of the track.
  final List<Position> track;

  /// The list of colors for the speed gradient.
  final List<Color> colors;

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
  final bool showSpeedLegend;

  /// If the speed should be displayed.
  final double? speedLegendBottom;

  /// If the speed should be displayed.
  final double? speedLegendLeft;

  /// The ratio of the height of the fetched image.
  /// Has to be between 0 and 1.
  final double imageHeightRatio;

  /// The ratio of the height of the fetched image.
  /// Has to be between 0 and 1.
  final double imageWidthRatio;

  /// The mapbox attribution top value.
  final double? mapboxTop;

  /// The mapbox attribution left value.
  final double? mapboxRight;

  /// The mapbox attribution left value.
  final double? mapboxLeft;

  /// The mapbox attribution bottom value.
  final double? mapboxBottom;

  /// The mapbox attribution width value.
  final double mapboxWidth;

  const TrackPictogram({
    super.key,
    required this.track,
    required this.blurRadius,
    this.colors = const [
      CI.radkulturRedDark,
      Color.fromARGB(255, 0, 115, 255),
    ],
    this.startImage,
    this.destinationImage,
    this.lineWidth = 3.0,
    this.iconSize = 10,
    this.showSpeedLegend = true,
    this.imageHeightRatio = 1,
    this.imageWidthRatio = 1,
    this.mapboxTop = 12,
    this.mapboxRight = 8,
    this.mapboxLeft,
    this.mapboxBottom,
    this.mapboxWidth = 32,
    this.speedLegendBottom = 10,
    this.speedLegendLeft = 10,
  });

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

  /// The brightness of the background image.
  Brightness? backgroundImageBrightness;

  /// The future of the background image.
  Future? backgroundImageFuture;

  /// Loads the background image.
  void loadBackgroundImage() {
    final fetchedBrightness = Theme.of(context).brightness;
    if (fetchedBrightness == backgroundImageBrightness) return;

    backgroundImageFuture?.ignore();
    backgroundImageFuture = MapboxTileImageCache.requestTile(
      coords: widget.track.map((e) => LatLng(e.latitude, e.longitude)).toList(),
      brightness: fetchedBrightness,
      heightRatio: widget.imageHeightRatio,
      widthRatio: widget.imageWidthRatio,
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

    SchedulerBinding.instance.addPostFrameCallback((_) => loadBackgroundImage());
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
            colors: widget.colors,
            maxSpeed: maxSpeed,
            minSpeed: minSpeed,
            startImage: widget.startImage,
            destinationImage: widget.destinationImage,
            lineWidth: widget.lineWidth,
            iconSize: widget.iconSize,
            showSpeed: true,
            heightRatio: widget.imageHeightRatio,
            widthRatio: widget.imageWidthRatio,
          ),
        ),

        // Legend
        if (widget.showSpeedLegend)
          Positioned(
            bottom: widget.speedLegendBottom,
            left: widget.speedLegendLeft,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white.withOpacity(0.75)
                    : Colors.black.withOpacity(0.25),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4, left: 6, right: 6),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: widget.colors,
                        ),
                      ),
                    ),
                    const SmallHSpace(),
                    Text(
                      '0 bis ${((maxSpeed ?? 0) * 3.6).toInt()} km/h',
                      style: TextStyle(
                        fontSize: 8,
                        color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        //Mapbox Attribution Logo
        MapboxAttribution(
          top: widget.mapboxTop,
          right: widget.mapboxRight,
          left: widget.mapboxLeft,
          bottom: widget.mapboxBottom,
          width: widget.mapboxWidth,
        ),
      ],
    );
  }
}

class TrackPainter extends CustomPainter {
  final double fraction;
  final double blurRadius;
  final List<Position> track;
  final List<Color> colors;
  double? maxSpeed;
  double? minSpeed;
  final ui.Image? startImage;
  final ui.Image? destinationImage;
  final double lineWidth;
  final double iconSize;
  final bool showSpeed;
  final double heightRatio;
  final double widthRatio;

  TrackPainter({
    required this.fraction,
    required this.blurRadius,
    required this.track,
    required this.colors,
    required this.lineWidth,
    required this.iconSize,
    required this.showSpeed,
    required this.heightRatio,
    required this.widthRatio,
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
    // If the number of points is > threshold, we reduce it to threshold.
    // We do this by applying the following pattern:
    // - If n_points ~ or < threshold, we keep all points
    // - If n_points < 2x threshold, we keep every second point
    // - If n_points < 3x threshold, we keep every third point
    // ...
    // Note: 1000 points is roughly 1000 seconds, which is 16 minutes of GPS.
    final List<Position> trackToDraw = [];
    const threshold = 300;
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

      // Calculation:
      // longitude/latitude - bbox / (bbox max - bbox min) (Ratio) * Space available (height or width).
      // If not square: multiply the opposite ratio to make sure, the route is displayed square.
      // Also add half the size of the site with ratio to the point to center it.
      final x1 = (p1.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * (size.width * (heightRatio)) +
          (size.width * (1 - heightRatio) * 0.5);
      final y1 = (p1.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * (size.height * (widthRatio)) +
          (size.height * (1 - widthRatio) * 0.5);
      final x2 = (p2.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * (size.width * (heightRatio)) +
          (size.width * (1 - heightRatio) * 0.5);
      final y2 = (p2.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * (size.height * (widthRatio)) +
          (size.height * (1 - widthRatio) * 0.5);

      var color = CI.radkulturRed;
      if (showSpeed && minSpeed != null && maxSpeed != null && minSpeed != maxSpeed) {
        if (colors.length < 2) {
          throw Exception('The colors list must have at least two colors.');
        }
        final frac = (p1.speed - minSpeed!) / (maxSpeed! - minSpeed!);
        var index = (frac * (colors.length - 1)).toInt();
        index = min(index, colors.length - 2);
        // Normalize the fraction between the two colors
        final fracIndex = frac * (colors.length - 1) - index;
        color = Color.lerp(colors[index], colors[index + 1], fracIndex)!;
      }
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint..color = color);
    }

    // Interpolate the last segment
    if (trackCountFraction + 1 < trackCount) {
      final p1 = trackToDraw[trackCountFraction.toInt()];
      final p2 = trackToDraw[trackCountFraction.toInt() + 1];
      final pct = trackCountFraction - trackCountFraction.toInt();
      final x1 = (p1.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * (size.width * (heightRatio)) +
          (size.width * (1 - heightRatio) * 0.5);
      final y1 = (p1.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * (size.height * (widthRatio)) +
          (size.height * (1 - widthRatio) * 0.5);
      final x2 = (p2.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * (size.width * (heightRatio)) +
          (size.width * (1 - heightRatio) * 0.5);
      final y2 = (p2.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * (size.height * (widthRatio)) +
          (size.height * (1 - widthRatio) * 0.5);
      final x2i = x1 + (x2 - x1) * pct;
      final y2i = y1 + (y2 - y1) * pct;

      var color = CI.radkulturRed;
      if (showSpeed && minSpeed != null && maxSpeed != null && minSpeed != maxSpeed) {
        // Calculate the fraction based on a power function
        // This makes the color change more visible for lower speeds
        if (colors.length < 2) {
          throw Exception('The colors list must have at least two colors.');
        }
        final frac = (p1.speed - minSpeed!) / (maxSpeed! - minSpeed!);
        var index = (frac * (colors.length - 1)).toInt();
        index = min(index, colors.length - 2);
        final fracIndex = frac * (colors.length - 1) - index;
        color = Color.lerp(colors[index], colors[index + 1], fracIndex)!;
      }
      canvas.drawLine(Offset(x1, y1), Offset(x2i, y2i), paint..color = color);
    }

    // Draw the circles at the start and end point.
    final pFirst = trackToDraw.first;
    final xFirst = (pFirst.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * (size.width * (heightRatio)) +
        (size.width * (1 - heightRatio) * 0.5);
    final yFirst = (pFirst.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * (size.height * (widthRatio)) +
        (size.height * (1 - widthRatio) * 0.5);

    if (startImage != null) {
      paintImage(
          canvas: canvas,
          rect: Rect.fromCenter(center: Offset(xFirst, yFirst), width: iconSize, height: iconSize),
          image: startImage!);
    }
    final pLast = trackToDraw.last;
    final xLast = (pLast.longitude - bbox.minLon) / (bbox.maxLon - bbox.minLon) * (size.width * (heightRatio)) +
        (size.width * (1 - heightRatio) * 0.5);
    final yLast = (pLast.latitude - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * (size.height * (widthRatio)) +
        (size.height * (1 - widthRatio) * 0.5);

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
