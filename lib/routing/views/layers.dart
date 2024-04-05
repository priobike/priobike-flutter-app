import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/common/mapbox_attribution.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/layers.dart';

class LayerSelectionView extends StatefulWidget {
  const LayerSelectionView({super.key});

  @override
  State<StatefulWidget> createState() => LayerSelectionViewState();
}

class LayerSelectionViewState extends State<LayerSelectionView> {
  /// The layers service, which is injected by the provider.
  late Layers layers;

  /// The map designs service, which is injected by the provider.
  late MapDesigns mapDesigns;

  /// The future of the background images by map design name.
  Map<String, Future<MemoryImage?>> screenshotFutures = {};

  /// The background images by map design.
  Map<MapDesign, MemoryImage> screenshots = {};

  /// How many screenshots we have already fetched (if counter is same as count of designs we have finished loading).
  int loadingCounter = 0;

  /// Whether to show the layer explanations.
  bool showLayerExplanations = false;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  void loadScreenshots() {
    for (final design in MapDesign.designs) {
      Future<MemoryImage?>? screenshotFuture = screenshotFutures[design.name];
      if (screenshotFuture != null) {
        screenshotFuture.ignore();
      }

      List<LatLng> coords;
      final boundingBox = getIt<Boundary>().getRoughBoundingBox();
      final latDiff = boundingBox["maxLat"]! - boundingBox["minLat"]!;
      final lonDiff = boundingBox["maxLon"]! - boundingBox["minLon"]!;
      const zoomFactor = 0.495;
      coords = [
        LatLng(boundingBox["minLat"]! + latDiff * zoomFactor, boundingBox["minLon"]! + lonDiff * zoomFactor),
        LatLng(boundingBox["maxLat"]! - latDiff * zoomFactor, boundingBox["maxLon"]! - lonDiff * zoomFactor),
      ];

      final styleUri = Theme.of(context).brightness == Brightness.light ? design.lightStyle : design.darkStyle;

      final future = MapboxTileImageCache.requestTile(
              coords: coords, brightness: Theme.of(context).brightness, styleUri: styleUri, mapPadding: 0.45)
          .then((image) {
        if (image == null) return;
        setState(() {
          screenshots[design] = image;
          loadingCounter++;
        });
      });

      screenshotFutures[design.name] = future;
    }
  }

  @override
  void initState() {
    super.initState();

    layers = getIt<Layers>();
    layers.addListener(update);
    mapDesigns = getIt<MapDesigns>();
    mapDesigns.addListener(update);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      loadScreenshots();
    });
  }

  @override
  void dispose() {
    layers.removeListener(update);
    mapDesigns.removeListener(update);
    for (final future in screenshotFutures.values) {
      future.ignore();
    }
    super.dispose();
  }

  Widget showExplanations() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 8,
              child: Column(
                children: [
                  Small(
                    text: "¹",
                    context: context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            const SmallHSpace(),
            SizedBox(
              width: MediaQuery.of(context).size.width - 48,
              child: Small(
                text: "Orte, an denen vermehrt Unfälle mit Radfahrenden-Beteiligung passiert sind.",
                context: context,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SmallVSpace(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 8,
              child: Column(
                children: [
                  Small(
                    text: "²",
                    context: context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            const SmallHSpace(),
            SizedBox(
              width: MediaQuery.of(context).size.width - 48,
              child: Small(
                text: "Statische Grüne Wellen. Passierbar bei einer Geschwindigkeit von 18 km/h.",
                context: context,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SmallVSpace(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 8,
              child: Column(
                children: [
                  Small(
                    text: "³",
                    context: context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            const SmallHSpace(),
            SizedBox(
              width: MediaQuery.of(context).size.width - 48,
              child: Small(
                text: "Für Radfahrende optimierte Wege.",
                context: context,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Content(text: "Orte anzeigen", context: context),
            const SmallVSpace(),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                // The layer for the elevation.
                LayerSelectionItem(
                  icon: Theme.of(context).colorScheme.brightness == Brightness.light
                      ? Image.asset("assets/images/rent-light.png")
                      : Image.asset("assets/images/rent-dark.png"),
                  title: 'Ausleihen',
                  selected: layers.showRentalStations,
                  onTap: () => layers.setShowRentalStations(!layers.showRentalStations),
                ),
                LayerSelectionItem(
                  icon: Theme.of(context).colorScheme.brightness == Brightness.light
                      ? Image.asset("assets/images/park-light.png")
                      : Image.asset("assets/images/park-dark.png"),
                  title: 'Parken',
                  selected: layers.showParkingStations,
                  onTap: () => layers.setShowParkingStations(!layers.showParkingStations),
                ),
                LayerSelectionItem(
                  icon: Theme.of(context).colorScheme.brightness == Brightness.light
                      ? Image.asset("assets/images/air-light.png")
                      : Image.asset("assets/images/air-dark.png"),
                  title: 'Aufpumpen',
                  selected: layers.showAirStations,
                  onTap: () => layers.setShowAirStations(!layers.showAirStations),
                ),
                LayerSelectionItem(
                  icon: Theme.of(context).colorScheme.brightness == Brightness.light
                      ? Image.asset("assets/images/repair-light.png")
                      : Image.asset("assets/images/repair-dark.png"),
                  title: 'Reparieren',
                  selected: layers.showRepairStations,
                  onTap: () => layers.setShowRepairStations(!layers.showRepairStations),
                ),
                LayerSelectionItem(
                  icon: Theme.of(context).colorScheme.brightness == Brightness.light
                      ? Image.asset("assets/images/accident-light.png")
                      : Image.asset("assets/images/accident-dark.png"),
                  title: 'Unfallstellen¹',
                  selected: layers.showAccidentHotspots,
                  onTap: () => layers.setShowAccidentHotspots(!layers.showAccidentHotspots),
                ),
                LayerSelectionItem(
                  icon: Theme.of(context).colorScheme.brightness == Brightness.light
                      ? Image.asset("assets/images/green-wave-light.png")
                      : Image.asset("assets/images/green-wave-dark.png"),
                  title: 'Grüne Wellen²',
                  selected: layers.showGreenWaveLayer,
                  onTap: () => layers.setShowGreenWaveLayer(!layers.showGreenWaveLayer),
                ),
                LayerSelectionItem(
                  icon: Theme.of(context).colorScheme.brightness == Brightness.light
                      ? Image.asset("assets/images/velo-routes-light.png")
                      : Image.asset("assets/images/velo-routes-dark.png"),
                  title: 'Velorouten³',
                  selected: layers.showVeloRoutesLayer,
                  onTap: () => layers.setShowVeloRoutesLayer(!layers.showVeloRoutesLayer),
                ),
                LayerSelectionItem(
                  icon: Theme.of(context).colorScheme.brightness == Brightness.light
                      ? Image.asset("assets/images/traffic-layer-light.png")
                      : Image.asset("assets/images/traffic-layer-dark.png"),
                  title: 'Verkehr',
                  selected: layers.showTrafficLayer,
                  onTap: () => layers.setShowTrafficLayer(!layers.showTrafficLayer),
                ),
              ],
            ),
            const SmallVSpace(),
            GestureDetector(
              onTap: () => setState(() {
                showLayerExplanations = !showLayerExplanations;
              }),
              child: Center(
                child: Text(
                  "Mehr Informationen",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    decorationColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstCurve: Curves.easeInOutCubic,
              secondCurve: Curves.easeInOutCubic,
              sizeCurve: Curves.easeInOutCubic,
              duration: const Duration(milliseconds: 1000),
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: showExplanations(),
              ),
              secondChild: Container(),
              crossFadeState: showLayerExplanations ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            ),
            const VSpace(),
            Content(text: "Kartendesign", context: context),
            const SmallVSpace(),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: loadingCounter >= MapDesign.designs.length
                  ? MapDesign.designs
                      .map(
                        (design) => LayerSelectionItem(
                          isScreenshot: true,
                          icon: !screenshots.containsKey(design) || screenshots[design] == null
                              ? Theme.of(context).colorScheme.brightness == Brightness.light
                                  ? Image.asset(design.fallbackLightScreenshot)
                                  : Image.asset(design.fallbackDarkScreenshot)
                              : Image.memory(screenshots[design]!.bytes),
                          title: design.name,
                          selected: mapDesigns.mapDesign == design,
                          onTap: () => mapDesigns.setMapDesign(design),
                        ),
                      )
                      .toList()
                  : [
                      LayerSelectionItem(
                        isScreenshot: false,
                        icon: const SizedBox(),
                        title: "Lädt..",
                        selected: false,
                        onTap: () => {},
                      )
                    ],
            ),
            const VSpace(),
          ],
        ),
      ),
    );
  }
}

class LayerSelectionItem extends StatelessWidget {
  /// Whether the item is a screenshot of the map.
  final bool isScreenshot;

  /// The icon of the item.
  final Widget icon;

  /// The title of the item.
  final String title;

  /// Whether the item is selected.
  final bool selected;

  /// The callback that will be executed when the item is tapped.
  final void Function() onTap;

  const LayerSelectionItem({
    this.isScreenshot = false,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Tile(
          padding: const EdgeInsets.all(0),
          borderRadius: BorderRadius.circular(26),
          splash: Theme.of(context).colorScheme.surfaceTint,
          fill: Theme.of(context).colorScheme.surfaceVariant,
          onPressed: onTap,
          content: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(4),
            // Draw a blue border around the selected item.
            decoration: selected
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  )
                : BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                BoldSmall(text: title, context: context),
              ],
            ),
          ),
        ),
        IgnorePointer(
          child: isScreenshot
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: icon,
                  ),
                )
              : Transform.scale(
                  scale: 1.25,
                  child: Transform.translate(
                    offset: const Offset(0, 12),
                    child: icon,
                  ),
                ),
        ),
        // Show a checkmark icon if the item is selected.
        if (selected)
          IgnorePointer(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
        //Mapbox Attribution Logo
        if (isScreenshot)
          const MapboxAttribution(
            top: 12,
            right: 12,
          ),
      ],
    );
  }
}
