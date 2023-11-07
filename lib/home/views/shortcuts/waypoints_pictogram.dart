import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/mapbox_attribution.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/views/shortcuts/gpx_conversion.dart';
import 'package:priobike/home/views/shortcuts/waypoints_painter.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';

class RecWptsModel with ChangeNotifier{
  List<Wpt> _recWpts = [];
  List<Wpt> get recWpts => _recWpts;

  void updateWpts(List<Wpt> newWpts) {
    _recWpts = newWpts;
    notifyListeners();
  }
}

class WaypointsPictogram extends StatefulWidget {
  /// waypoints from a gpx
  final List<Wpt> wpts;

  /// The height of the shortcut (width == height, because the it is a square)
  final double height;

  /// The color of the pictogram.
  final Color color;

  const WaypointsPictogram({
    Key? key,
    required this.wpts,
    this.height = 400,
    this.color = CI.radkulturRedDark,
  }) : super(key: key);

  @override
  WaypointsPictogramState createState() => WaypointsPictogramState();
}

class WaypointsPictogramState extends State<WaypointsPictogram> {
  /// The background image of the map for the track.
  MemoryImage? backgroundImage;

  /// The brightness of the background image.
  Brightness? backgroundImageBrightness;

  /// The future of the background image.
  Future? backgroundImageFuture;

  late Routing routing;

  RecWptsModel recWptsNotifier = RecWptsModel();

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
    List<Waypoint> waypoints = await reduceWpts(points, routing, (List<Wpt> newWpts) => {recWptsNotifier.updateWpts(newWpts)});
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
  void didUpdateWidget(covariant WaypointsPictogram oldWidget) {
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
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        SizedBox(
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: WaypointsPaint(
                  wpts: widget.wpts,
                  listenable: recWptsNotifier
                )
              ),
              const MapboxAttribution(
                top: 8,
                right: 8,
              ),
            ],
          ),
        ),
        const Tile(content: Text('Die konvertierte Route kann von der GPX Datei abweichen.')),
        Padding(
          padding: const EdgeInsets.all(16),
          child: BigButton(
          label: 'Konvertieren',
          onPressed: () async => await convertGpxToWaypoints(widget.wpts),
        ))
      ],
    ));
  }
}
