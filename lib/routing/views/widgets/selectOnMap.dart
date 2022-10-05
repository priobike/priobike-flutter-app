import 'dart:async';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/services/mapcontroller.dart';
import 'package:priobike/routing/views/widgets/ZoomInAndOutButton.dart';
import 'package:priobike/routing/views/widgets/compassButton.dart';
import 'package:priobike/routing/views/widgets/gpsButton.dart';
import 'package:provider/provider.dart';

class SelectOnMapView extends StatefulWidget {
  final int? index;
  final Waypoint? currentLocationWaypoint;

  const SelectOnMapView({Key? key, this.index, this.currentLocationWaypoint})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => SelectOnMapViewState();
}

class SelectOnMapViewState extends State<SelectOnMapView> {
  /// The associated routingOLD service, which is injected by the provider.
  late Routing routing;

  /// The associated shortcuts service, which is injected by the provider.
  late MapController mapController;

  /// The associated geosearch service, which is injected by the provider.
  late Geocoding geocoding;

  /// The associated geosearch service, which is injected by the provider.
  late Profile profile;

  /// The stream that receives notifications when the bottom sheet is dragged.
  final sheetMovement = StreamController<DraggableScrollableNotification>();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      await routing.loadRoutes(context);
    });
  }

  @override
  void didChangeDependencies() {
    routing = Provider.of<Routing>(context);
    mapController = Provider.of<MapController>(context);
    geocoding = Provider.of<Geocoding>(context);
    profile = Provider.of<Profile>(context);

    super.didChangeDependencies();
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
    mapController.zoomIn(ControllerType.selectOnMap);
  }

  /// Private ZoomOut Function which calls mapControllerService
  void _zoomOut() {
    mapController.zoomOut(ControllerType.selectOnMap);
  }

  /// Private GPS Centralization Function which calls mapControllerService
  void _gpsCentralization() {
    mapController.setMyLocationTrackingModeTracking(ControllerType.selectOnMap);
  }

  /// Private Center North Function which calls mapControllerService
  void _centerNorth() {
    mapController.centerNorth(ControllerType.selectOnMap);
  }

  /// A function that is executed when the complete button is pressed
  Future<void> onComplete(BuildContext context, double lat, double lon) async {
    String? address = await geocoding.reverseGeocodeLatLng(context, lat, lon);

    if (address == null) return;

    final waypoint = Waypoint(lat, lon, address: address);

    final waypoints = routing.selectedWaypoints ?? [];
    // exchange with new waypoint
    List<Waypoint> newWaypoints = waypoints.toList();
    if (widget.index != null) {
      newWaypoints[widget.index!] = waypoint;
    } else {
      // Insert current location as first waypoint if option is set
      if (profile.setLocationAsStart != null &&
          profile.setLocationAsStart! &&
          widget.currentLocationWaypoint != null &&
          waypoints.isEmpty &&
          waypoint.address != null) {
        newWaypoints = [widget.currentLocationWaypoint!, waypoint];
      } else {
        newWaypoints = [...waypoints, waypoint];
      }
    }

    if (waypoint.address != null) {
      profile.saveNewSearch(waypoint);
    }

    for (Waypoint waypoint in newWaypoints) {
      print("-------------------------");
      print(waypoint.lat);
      print(waypoint.lon);
      print(waypoint.address);
      print("-------------------------");
    }

    await routing.selectWaypoints(newWaypoints);

    // pop till routingScreen
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
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
                            icon: Icons.chevron_left_rounded,
                            onPressed: () => Navigator.pop(context),
                            elevation: 5),
                      ),
                      const SizedBox(width: 16),
                      Center(
                        child: SubHeader(
                            text: "Standort auf Karte wählen",
                            context: context),
                      ),
                      const SizedBox(width: 5),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          primary: Theme.of(context).colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () {
                          if (mapController.getCameraPosition(
                                  ControllerType.selectOnMap) !=
                              null) {
                            onComplete(
                                context,
                                mapController
                                    .getCameraPosition(
                                        ControllerType.selectOnMap)!
                                    .latitude,
                                mapController
                                    .getCameraPosition(
                                        ControllerType.selectOnMap)!
                                    .longitude);
                          }
                        },
                        child: Content(
                            text: "Fertig",
                            context: context,
                            color: Colors.white),
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
                    controllerType: ControllerType.selectOnMap),
                if (routing.isFetchingRoute) renderLoadingIndicator(),
                Padding(
                  /// Align with FAB
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          CompassButton(centerNorth: _centerNorth),
                          const SizedBox(height: 10),
                          ZoomInAndOutButton(
                              zoomIn: _zoomIn, zoomOut: _zoomOut),
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
            GPSButton(
                myLocationTrackingMode:
                    mapController.myLocationTrackingModeSelectOnMapView,
                gpsCentralization: _gpsCentralization),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  @override
  void dispose() {
    sheetMovement.close();
    super.dispose();
  }
}
