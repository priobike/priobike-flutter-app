import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/mapbox_attribution.dart';
import 'package:priobike/common/shimmer.dart';
import 'package:priobike/home/services/gpx_conversion.dart';
import 'package:priobike/home/views/shortcuts/gpx_conversion_waypoints_paint.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';

class GpxConversionWaypointsPictogram extends StatefulWidget {
  /// waypoints from a gpx
  final List<Wpt> wpts;

  /// The height of the shortcut (width == height, because the it is a square)
  final double height;

  /// The color of the pictogram.
  final Color color;

  final GpxConversion gpxConversionNotifier;

  const GpxConversionWaypointsPictogram({
    Key? key,
    required this.wpts,
    this.height = 400,
    this.color = CI.radkulturRedDark,
    required this.gpxConversionNotifier,
  }) : super(key: key);

  @override
  GpxConversionWaypointsPictogramState createState() => GpxConversionWaypointsPictogramState();
}

class GpxConversionWaypointsPictogramState extends State<GpxConversionWaypointsPictogram> {
  /// The background image of the map for the track.
  MemoryImage? backgroundImage;

  /// The brightness of the background image.
  Brightness? backgroundImageBrightness;

  /// The future of the background image.
  Future? backgroundImageFuture;

  late Routing routing;

  GpxConversionState gpxConversionState = GpxConversionState.init;

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

  @override
  void didUpdateWidget(covariant GpxConversionWaypointsPictogram oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadBackgroundImage();
  }

  void updateGpxConversionState() {
    setState(() => gpxConversionState = widget.gpxConversionNotifier.gpxConversionState);
  }

  @override
  void initState() {
    super.initState();
    routing = getIt<Routing>();
    widget.gpxConversionNotifier.addListener(updateGpxConversionState);
    SchedulerBinding.instance.addPostFrameCallback((_) => loadBackgroundImage());
  }

  @override
  void dispose() {
    backgroundImageFuture?.ignore();
    widget.gpxConversionNotifier.removeListener(updateGpxConversionState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CI.radkulturRed,
          borderRadius: BorderRadius.circular(48),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 4,
              blurRadius: 32,
              offset: const Offset(0, 20), // changes position of shadow
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Tile(
            fill: Theme.of(context).colorScheme.background,
            shadowIntensity: 0.05,
            shadow: Colors.black,
            borderRadius: BorderRadius.circular(32),
            padding: const EdgeInsets.all(0),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
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
                                borderRadius: BorderRadius.circular(32),
                                child: Image(
                                  image: backgroundImage!,
                                  fit: BoxFit.contain,
                                  key: UniqueKey(),
                                ),
                              )
                            : Container(),
                      ),
                      GPXConversionWaypointsPaint(
                          wpts: widget.wpts, gpxConversionNotifier: widget.gpxConversionNotifier),
                      const MapboxAttribution(
                        top: 8,
                        right: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Shimmer(
        linearGradient: const LinearGradient(
          colors: [
            CI.radkulturRed,
            Colors.white,
            CI.radkulturRed,
          ],
          stops: [0, 0.3, 0.35],
          begin: Alignment(0.0, -1.0),
          end: Alignment(1.0, 2.0),
          tileMode: TileMode.clamp,
        ),
        child: ShimmerLoading(
          isLoading: gpxConversionState == GpxConversionState.loading,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(48),
              border: Border.all(
                color: CI.radkulturRed,
                width: 4,
              ),
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
      )
    ]);
  }
}
