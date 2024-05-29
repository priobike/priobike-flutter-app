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
import 'package:priobike/routing/models/navigation.dart';

/// A pictogram of a track.
class TrackPictogram extends StatefulWidget {
  /// The Positions of the track.
  final List<Position>? track;

  /// The optional positions of the route.
  final List<NavigationNode>? routeNodes;

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

  /// The bottom position of the speed legend.
  final double? speedLegendBottom;

  /// The left position of the speed legend.
  final double? speedLegendLeft;

  /// The bottom position of the route legend.
  final double? routeLegendBottom;

  /// The right position of the route legend.
  final double? routeLegendRight;

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
    required this.blurRadius,
    required this.colors,
    this.track,
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
    this.routeLegendBottom = 10,
    this.routeLegendRight = 10,
    this.routeNodes,
  });

  @override
  TrackPictogramState createState() => TrackPictogramState();
}

class TrackPictogramState extends State<TrackPictogram> with SingleTickerProviderStateMixin {
  double fraction = 0.0;
  late Animation<double> animation;
  late AnimationController controller;

  // Default values for min and max speed.
  // Set to 30 km/h (8.334 m/s).
  double maxSpeed = 8.334;
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

    List<LatLng> coords = [];

    if (widget.track != null && widget.track!.isNotEmpty) {
      coords.addAll(widget.track!.map((e) => LatLng(e.latitude, e.longitude)).toList());
    }

    if (widget.routeNodes != null && widget.routeNodes!.isNotEmpty) {
      coords.addAll(widget.routeNodes!.map((e) => LatLng(e.lat, e.lon)).toList());
    }

    // If there are no coords, there is nothing that can be fetched.
    if (coords.isEmpty) {
      setState(() {
        backgroundImageBrightness = Theme.of(context).brightness;
      });
      return;
    }

    backgroundImageFuture?.ignore();
    backgroundImageFuture = MapboxTileImageCache.requestTile(
      coords: coords,
      brightness: fetchedBrightness,
      // To make sure tracks fit horizontally.
      // 1 - screen ratio + 0.1 padding.
      mapPadding: 1 - (MediaQuery.of(context).size.width / MediaQuery.of(context).size.height) + 0.1,
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
    if (widget.track != null && widget.track!.isNotEmpty) {
      // Reset the max speed and calculate max speed depending on the track.
      maxSpeed = 0.0;
      for (var i = 0; i < widget.track!.length; i++) {
        final p = widget.track![i];
        if (p.speed > maxSpeed) {
          maxSpeed = p.speed;
        }
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
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: Image(
                        image: backgroundImage!,
                        fit: BoxFit.fitHeight,
                        key: UniqueKey(),
                      ),
                    ),
                  )
                : Container()),

        if (widget.track != null)
          CustomPaint(
            painter: TrackPainter(
              fraction: fraction,
              track: widget.track!,
              blurRadius: 0,
              colors: widget.colors,
              routeColor: Theme.of(context).brightness == Brightness.dark
                  ? CI.darkModeSecondaryRoute
                  : CI.lightModeSecondaryRoute,
              maxSpeed: maxSpeed,
              minSpeed: minSpeed,
              startImage: widget.startImage,
              destinationImage: widget.destinationImage,
              lineWidth: widget.lineWidth,
              iconSize: widget.iconSize,
              showSpeed: true,
              heightRatio: widget.imageHeightRatio,
              widthRatio: widget.imageWidthRatio,
              // To make sure tracks fit horizontally.
              // 1 - screen ratio + 0.1 padding.
              mapPadding: 1 - (MediaQuery.of(context).size.width / MediaQuery.of(context).size.height) + 0.1,
              routeNodes: widget.routeNodes,
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
                      '0 bis ${(maxSpeed * 3.6).toInt()} km/h',
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

        // Legend for route.
        if (widget.routeNodes != null && widget.routeNodes!.isNotEmpty)
          Positioned(
            bottom: widget.routeLegendBottom,
            right: widget.routeLegendRight,
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
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? CI.darkModeSecondaryRoute
                            : CI.lightModeSecondaryRoute,
                      ),
                    ),
                    const SmallHSpace(),
                    Text(
                      'Urspr. geplante Route',
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
  final List<Position>? track;
  final List<Color> colors;
  final Color routeColor;
  double? maxSpeed;
  double? minSpeed;
  final ui.Image? startImage;
  final ui.Image? destinationImage;
  final double lineWidth;
  final double iconSize;
  final bool showSpeed;
  final double heightRatio;
  final double widthRatio;
  final double mapPadding;
  final List<NavigationNode>? routeNodes;

  TrackPainter({
    required this.fraction,
    required this.blurRadius,
    required this.colors,
    required this.routeColor,
    required this.lineWidth,
    required this.iconSize,
    required this.showSpeed,
    required this.heightRatio,
    required this.widthRatio,
    required this.mapPadding,
    this.track,
    this.maxSpeed,
    this.minSpeed,
    this.startImage,
    this.destinationImage,
    this.routeNodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

    if (track != null) {
      if (track!.length > threshold) {
        final step = track!.length ~/ threshold;
        for (var i = 0; (i + step) < track!.length; i += step) {
          trackToDraw.add(track![i]);
        }
      } else {
        trackToDraw.addAll(track!);
      }
    }

    List<LatLng> coords = trackToDraw.map((e) => LatLng(e.latitude, e.longitude)).toList();
    if (routeNodes != null && routeNodes!.isNotEmpty) {
      coords.addAll(routeNodes!.map((e) => LatLng(e.lat, e.lon)).toList());
    }

    final bbox = MapboxMapProjection.mercatorBoundingBox(coords, mapPadding);
    if (bbox == null) return;

    if (routeNodes != null && routeNodes!.isNotEmpty) {
      drawRoute(canvas, routeNodes!, size, bbox);
    }

    if (trackToDraw.isNotEmpty) {
      drawGps(canvas, trackToDraw, size, bbox);
    }
  }

  /// Draws the initial calculated route.
  void drawRoute(Canvas canvas, List<NavigationNode> routeToDraw, Size size, MapboxMapProjectionBoundingBox bbox) {
    final colorDarker = HSLColor.fromColor(routeColor).withLightness(0.2).toColor();
    final paint = Paint()
      ..strokeWidth = lineWidth / 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = routeColor;
    final backgroundPaint = Paint()
      ..strokeWidth = lineWidth / 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = colorDarker;
    if (blurRadius > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
      backgroundPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
    }
    final routeCount = routeToDraw.length;
    final routeCountFraction = routeCount * fraction;

    // Draw the lines between the coordinates
    var linesToDraw = [];
    for (var i = 0; i < routeCountFraction - 1; i++) {
      final p1 = routeToDraw[i];
      final p2 = routeToDraw[i + 1];

      // Calculation:
      // longitude/latitude - bbox / (bbox max - bbox min) (Ratio) * Space available (height or width).
      // If not square: multiply the opposite ratio to make sure, the route is displayed square.
      // Also add half the size of the site with ratio to the point to center it.
      final x1 = (p1.lon - bbox.minLon) / (bbox.maxLon - bbox.minLon) * (size.width * (heightRatio)) +
          (size.width * (1 - heightRatio) * 0.5);
      final y1 = (p1.lat - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * (size.height * (widthRatio)) +
          (size.height * (1 - widthRatio) * 0.5);
      final x2 = (p2.lon - bbox.minLon) / (bbox.maxLon - bbox.minLon) * (size.width * (heightRatio)) +
          (size.width * (1 - heightRatio) * 0.5);
      final y2 = (p2.lat - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * (size.height * (widthRatio)) +
          (size.height * (1 - widthRatio) * 0.5);

      linesToDraw.add((x1, y1, x2, y2));
    }

    // Interpolate the last segment
    if (routeCountFraction + 1 < routeCount) {
      final p1 = routeToDraw[routeCountFraction.toInt()];
      final p2 = routeToDraw[routeCountFraction.toInt() + 1];
      final pct = routeCountFraction - routeCountFraction.toInt();
      final x1 = (p1.lon - bbox.minLon) / (bbox.maxLon - bbox.minLon) * (size.width * (heightRatio)) +
          (size.width * (1 - heightRatio) * 0.5);
      final y1 = (p1.lat - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * (size.height * (widthRatio)) +
          (size.height * (1 - widthRatio) * 0.5);
      final x2 = (p2.lon - bbox.minLon) / (bbox.maxLon - bbox.minLon) * (size.width * (heightRatio)) +
          (size.width * (1 - heightRatio) * 0.5);
      final y2 = (p2.lat - bbox.maxLat) / (bbox.minLat - bbox.maxLat) * (size.height * (widthRatio)) +
          (size.height * (1 - widthRatio) * 0.5);
      final x2i = x1 + (x2 - x1) * pct;
      final y2i = y1 + (y2 - y1) * pct;

      linesToDraw.add((x1, y1, x2i, y2i));
    }

    for (var line in linesToDraw) {
      final (x1, y1, x2, y2) = line;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), backgroundPaint);
    }
    for (var line in linesToDraw) {
      final (x1, y1, x2, y2) = line;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  /// Draws the driven track (List of GPS coordinates).
  void drawGps(Canvas canvas, List<Position> trackToDraw, Size size, MapboxMapProjectionBoundingBox bbox) {
    final paint = Paint()
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (blurRadius > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
    }
    final trackCount = trackToDraw.length;
    final trackCountFraction = trackCount * fraction;

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
