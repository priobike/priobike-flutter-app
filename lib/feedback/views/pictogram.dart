import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/background_image.dart';

/// A pictogram of a track.
class TrackPictogram extends StatefulWidget {
  final List<Position> tracks;
  final Color minSpeedColor;
  final Color maxSpeedColor;
  final double blurRadius;
  final int height;

  /// The session id of the track, used for the background image.
  final Track track;

  const TrackPictogram({
    Key? key,
    required this.tracks,
    required this.blurRadius,
    required this.track,
    required this.height,
    this.minSpeedColor = Colors.green,
    this.maxSpeedColor = Colors.red,
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

  /// The background image service.
  late BackgroundImage backgroundImageService;

  /// The background image of the map for the track.
  MemoryImage? backgroundImage;

  @override
  void initState() {
    super.initState();
    backgroundImageService = getIt<BackgroundImage>();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    animation = Tween<double>(begin: 0, end: 1).animate(controller)
      ..addListener(() {
        setState(() {
          fraction = animation.value;
        });
      });
    controller.forward();

    // Find the min and max speed
    for (var i = 0; i < widget.tracks.length; i++) {
      final p = widget.tracks[i];
      if (maxSpeed == null || p.speed > maxSpeed!) {
        maxSpeed = p.speed;
      }
    }
  }

  /// Load the background image of the map for the track.
  Future<void> loadBackgroundImage() async {
    final oldBackgroundImage = backgroundImage;

    double? minLon;
    double? minLat;
    double? maxLon;
    double? maxLat;

    // calculate the bounding box of the route
    for (final position in widget.tracks) {
      if (minLon == null || position.longitude < minLon) minLon = position.longitude;
      if (minLat == null || position.latitude < minLat) minLat = position.latitude;
      if (maxLon == null || position.longitude > maxLon) maxLon = position.longitude;
      if (maxLat == null || position.latitude > maxLat) maxLat = position.latitude;
    }

    if (minLon != null || minLat != null || maxLon != null || maxLat != null) {
      backgroundImage = await backgroundImageService.loadImage(
        sessionId: widget.track.sessionId,
        minLat: minLat!,
        minLon: minLon!,
        maxLat: maxLat!,
        maxLon: maxLon!,
        height: widget.height,
      );
    }
    // only update if the image has changed
    if (backgroundImage != null && (backgroundImage != oldBackgroundImage)) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // The background image of the map for the track.
    loadBackgroundImage();

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // Background image
        ClipRect(
          child: SizedBox(
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0.05, 0.5, 0.95],
                  colors: [Colors.transparent, Colors.black, Colors.transparent],
                ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.05, 0.5, 0.95],
                    colors: [Colors.transparent, Colors.black, Colors.transparent],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.dstIn,
                //TODO: Es gibt noch das Problem, dass die Animation des Tracks neugeladen wird,
                // sobald das Bild da ist. Das ist Mist.
                child: AnimatedSwitcher(
                  duration: const Duration(seconds: 1),
                  child: backgroundImage == null
                      ? Container()
                      : Image(
                          key: UniqueKey(),
                          image: backgroundImage!,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
          ),
        ),
        //   ),
        // ),
        // Glow
        Opacity(
          opacity: Theme.of(context).colorScheme.brightness == Brightness.dark ? 0.5 : 0,
          child: AspectRatio(
            aspectRatio: 1,
            child: Padding(
              // Necessary to avoid overlapping with the legend at the bottom. Padding needs to be added to all sides to keep the aspect ratio.
              padding: const EdgeInsets.all(30.0),
              child: CustomPaint(
                painter: TrackPainter(
                  fraction: fraction,
                  track: widget.tracks,
                  blurRadius: widget.blurRadius,
                  minSpeedColor: widget.minSpeedColor,
                  maxSpeedColor: widget.maxSpeedColor,
                  maxSpeed: maxSpeed,
                  minSpeed: minSpeed,
                ),
              ),
            ),
          ),
        ),
        // Shadow
        Opacity(
          opacity: Theme.of(context).colorScheme.brightness == Brightness.dark ? 0 : 0.4,
          child: AspectRatio(
            aspectRatio: 1,
            child: Padding(
              // Necessary to avoid overlapping with the legend at the bottom. Padding needs to be added to all sides to keep the aspect ratio.
              padding: const EdgeInsets.all(30.0),
              child: CustomPaint(
                painter: TrackPainter(
                  fraction: fraction,
                  track: widget.tracks,
                  blurRadius: widget.blurRadius / 2,
                  minSpeedColor: HSLColor.fromColor(widget.minSpeedColor).withLightness(0.4).toColor(),
                  maxSpeedColor: HSLColor.fromColor(widget.maxSpeedColor).withLightness(0.4).toColor(),
                  maxSpeed: maxSpeed,
                  minSpeed: minSpeed,
                ),
              ),
            ),
          ),
        ),
        AspectRatio(
          aspectRatio: 1,
          child: Padding(
            // Necessary to avoid overlapping with the legend at the bottom. Padding needs to be added to all sides to keep the aspect ratio.
            padding: const EdgeInsets.all(30.0),
            child: CustomPaint(
              painter: TrackPainter(
                fraction: fraction,
                track: widget.tracks,
                blurRadius: 0,
                minSpeedColor: widget.minSpeedColor,
                maxSpeedColor: widget.maxSpeedColor,
                maxSpeed: maxSpeed,
                minSpeed: minSpeed,
              ),
            ),
          ),
        ),
        // Legend
        Positioned(
          bottom: 0,
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
        Positioned(
          bottom: 30,
          right: 0,
          child: Image.asset(
            'assets/images/mapbox-logo-transparent.png',
            width: 80,
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

class TrackPainter extends CustomPainter {
  final double fraction;
  final double blurRadius;
  final List<Position> track;
  final Color minSpeedColor;
  final Color maxSpeedColor;
  double? maxSpeed;
  double? minSpeed;

  TrackPainter({
    required this.fraction,
    required this.blurRadius,
    required this.track,
    required this.minSpeedColor,
    required this.maxSpeedColor,
    this.maxSpeed,
    this.minSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 6
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
    final trackToDraw = [];
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

    double? maxLat;
    double? minLat;
    double? maxLon;
    double? minLon;

    // Find the bounding box of the waypoints
    for (var i = 0; i < trackCount; i++) {
      final p = trackToDraw[i];
      if (maxLat == null || p.latitude > maxLat) {
        maxLat = p.latitude;
      }
      if (minLat == null || p.latitude < minLat) {
        minLat = p.latitude;
      }
      if (maxLon == null || p.longitude > maxLon) {
        maxLon = p.longitude;
      }
      if (minLon == null || p.longitude < minLon) {
        minLon = p.longitude;
      }
    }
    if (maxLat == null || minLat == null || maxLon == null || minLon == null) {
      return;
    }
    if (maxLat == minLat || maxLon == minLon) {
      return;
    }

    // If dLat > dLon, pad the longitude, otherwise pad the latitude to ensure that the aspect ratio is 1.
    final dLat = maxLat - minLat;
    final dLon = maxLon - minLon;
    if (dLat > dLon) {
      final d = (dLat - dLon) / 2;
      minLon -= d;
      maxLon += d;
    } else {
      final d = (dLon - dLat) / 2;
      minLat -= d;
      maxLat += d;
    }

    // Draw the lines between the coordinates
    for (var i = 0; i < trackCountFraction - 1; i++) {
      final p1 = trackToDraw[i];
      final p2 = trackToDraw[i + 1];

      final x1 = (p1.longitude - minLon) / (maxLon - minLon) * size.width;
      final y1 = (p1.latitude - maxLat) / (minLat - maxLat) * size.height;
      final x2 = (p2.longitude - minLon) / (maxLon - minLon) * size.width;
      final y2 = (p2.latitude - maxLat) / (minLat - maxLat) * size.height;

      var color = minSpeedColor;
      if (minSpeed != null && maxSpeed != null && minSpeed != maxSpeed) {
        color = Color.lerp(minSpeedColor, maxSpeedColor, (p1.speed - minSpeed!) / (maxSpeed! - minSpeed!))!;
      }
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint..color = color);
    }

    // Interpolate the last segment
    if (trackCountFraction + 1 < trackCount) {
      final p1 = trackToDraw[trackCountFraction.toInt()];
      final p2 = trackToDraw[trackCountFraction.toInt() + 1];
      final pct = trackCountFraction - trackCountFraction.toInt();
      final x1 = (p1.longitude - minLon) / (maxLon - minLon) * size.width;
      final y1 = (p1.latitude - maxLat) / (minLat - maxLat) * size.height;
      final x2 = (p2.longitude - minLon) / (maxLon - minLon) * size.width;
      final y2 = (p2.latitude - maxLat) / (minLat - maxLat) * size.height;
      final x2i = x1 + (x2 - x1) * pct;
      final y2i = y1 + (y2 - y1) * pct;

      var color = minSpeedColor;
      if (minSpeed != null && maxSpeed != null && minSpeed != maxSpeed) {
        color = Color.lerp(minSpeedColor, maxSpeedColor, (p1.speed - minSpeed!) / (maxSpeed! - minSpeed!))!;
      }
      canvas.drawLine(Offset(x1, y1), Offset(x2i, y2i), paint..color = color);
    }

    // Draw the circles at the start and end point.
    final pFirst = trackToDraw.first;
    final xFirst = (pFirst.longitude - minLon) / (maxLon - minLon) * size.width;
    final yFirst = (pFirst.latitude - maxLat) / (minLat - maxLat) * size.height;

    var color = minSpeedColor;
    if (minSpeed != null && maxSpeed != null && minSpeed != maxSpeed) {
      color = Color.lerp(minSpeedColor, maxSpeedColor, (pFirst.speed - minSpeed!) / (maxSpeed! - minSpeed!))!;
    }
    canvas.drawCircle(Offset(xFirst, yFirst), 4, paint..color = color);
    final pLast = trackToDraw.last;
    final xLast = (pLast.longitude - minLon) / (maxLon - minLon) * size.width;
    final yLast = (pLast.latitude - maxLat) / (minLat - maxLat) * size.height;
    if (minSpeed != null && maxSpeed != null && minSpeed != maxSpeed) {
      color = Color.lerp(minSpeedColor, maxSpeedColor, (pLast.speed - minSpeed!) / (maxSpeed! - minSpeed!))!;
    }
    canvas.drawCircle(Offset(xLast, yLast), 8, paint..color = color);
  }

  @override
  bool shouldRepaint(covariant TrackPainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}
