import 'dart:async';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/map_settings.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views_beta/map.dart';
import 'package:priobike/routing/views_beta/widgets/compass_button.dart';
import 'package:priobike/routing/views_beta/widgets/gps_button.dart';
import 'package:priobike/routing/views_beta/widgets/select_on_map_name.dart';
import 'package:priobike/routing/views_beta/widgets/zoom_in_and_out_button.dart';

class SelectOnMapView extends StatefulWidget {
  final int? index;
  final bool withName;

  const SelectOnMapView({Key? key, this.index, required this.withName}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SelectOnMapViewState();
}

class SelectOnMapViewState extends State<SelectOnMapView> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated MapSettings service, which is injected by the provider.
  late MapSettings mapSettings;

  /// The associated geocoding service, which is injected by the provider.
  late Geocoding geocoding;

  /// The associated profile service, which is injected by the provider.
  late Profile profile;

  /// The associated place service, which is injected by the provider.
  late Places places;

  /// The stream that receives notifications when the bottom sheet is dragged.
  final sheetMovement = StreamController<DraggableScrollableNotification>();

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await routing.loadRoutes();
    });

    update = () => setState(() {});

    routing = getIt<Routing>();
    routing.addListener(update);
    mapSettings = getIt<MapSettings>();
    mapSettings.addListener(update);
    geocoding = getIt<Geocoding>();
    geocoding.addListener(update);
    profile = getIt<Profile>();
    profile.addListener(update);
    places = getIt<Places>();
    places.addListener(update);
  }

  @override
  void dispose() {
    routing.removeListener(update);
    mapSettings.removeListener(update);
    geocoding.removeListener(update);
    profile.removeListener(update);
    places.removeListener(update);
    sheetMovement.close();
    super.dispose();
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Tile(
          fill: Theme.of(context).colorScheme.background,
          content: Center(
            child: SizedBox(
              height: 86,
              width: 256,
              child: Column(children: [
                const CircularProgressIndicator(),
                const VSpace(),
                BoldContent(text: "Lade...", maxLines: 1, context: context),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  /// Private ZoomIn Function which calls mapControllerService
  void _zoomIn() {
    mapSettings.zoomIn(ControllerType.selectOnMap);
  }

  /// Private ZoomOut Function which calls mapControllerService
  void _zoomOut() {
    mapSettings.zoomOut(ControllerType.selectOnMap);
  }

  /// Private GPS Centralization Function which calls mapControllerService
  void _gpsCentralization() {
    mapSettings.setCameraCenterOnUserLocation(true);
  }

  /// Private Center North Function which calls mapControllerService
  void _centerNorth() {
    mapSettings.centerNorth(ControllerType.selectOnMap);
  }

  /// A function that is executed when the complete button is pressed.
  Future<void> onComplete(double lat, double lon) async {
    String? address = await geocoding.reverseGeocodeLatLng(lat, lon);

    if (!mounted) return;

    address ??= "Wegpunkt";

    final waypoint = Waypoint(lat, lon, address: address);

    if (widget.withName) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => SelectOnMapNameView(waypoint: waypoint),
        ),
      );
    } else {
      if (waypoint.address != null && profile.saveSearchHistory) {
        profile.saveNewSearch(waypoint);
      }
      Navigator.of(context).pop(waypoint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Container(
            width: frame.size.width,
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Hero(
                        tag: 'appBackButton',
                        child: AppBackButton(
                            icon: Icons.chevron_left_rounded, onPressed: () => Navigator.pop(context), elevation: 5),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Center(
                          child: BoldContent(
                            text: "Standort auf Karte wählen",
                            context: context,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.secondary,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () async {
                          final Map<String?, Object?>? cameraPosition =
                              await mapSettings.getCameraPosition(ControllerType.selectOnMap);
                          if (cameraPosition != null && cameraPosition["coordinates"] != null) {
                            // Cast from Object to List.
                            final List coordinates = cameraPosition["coordinates"] as List;
                            // This should not happen, but just in case.
                            if (coordinates.length == 2) {
                              onComplete(
                                coordinates[1],
                                coordinates[0],
                              );
                            }
                          } else {
                            ToastMessage.showError(
                                "Es konnten keine Koordinaten geladen werden. Bitte erneut versuchen.");
                          }
                        },
                        child: Content(
                            text: widget.withName ? "Speichern" : "Fertig", context: context, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                    ]),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                RoutingMapView(
                    sheetMovement: sheetMovement.stream,
                    controllerType: ControllerType.selectOnMap,
                    withRouting: false),
                if (routing.isFetchingRoute) renderLoadingIndicator(),
                Padding(
                  /// Align with FAB
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                      const SizedBox(height: 10),
                      CompassButton(centerNorth: _centerNorth),
                      const SizedBox(height: 10),
                      ZoomInAndOutButton(zoomIn: _zoomIn, zoomOut: _zoomOut),
                    ]),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.location_on,
                    size: 34,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ]),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GPSButton(gpsCentralization: _gpsCentralization),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
