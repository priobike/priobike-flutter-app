import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/controller.dart';
import 'package:priobike/common/map/layers.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';

class RoutingMapView extends StatefulWidget {
  /// The stream that receives notifications when the bottom sheet is dragged.
  final Stream<DraggableScrollableNotification>? sheetMovement;

  const RoutingMapView({required this.sheetMovement, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> with TickerProviderStateMixin {
  static const viewId = "routing.views.map";

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated discomfort service, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated location service, which is injected by the provider.
  late Positioning positioning;

  /// The associated layers service, which is injected by the provider.
  late Layers layers;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  /// A map controller for the map.
  MapboxMapController? mapController;

  /// A layer controller to safe add and remove layers.
  LayerController? layerController;

  /// The stream that receives notifications when the bottom sheet is dragged.
  StreamSubscription<DraggableScrollableNotification>? sheetMovementSubscription;

  /// Where the user is currently tapping.
  Offset? tapPosition;

  /// The animation controller for the on-tap animation.
  late AnimationController animationController;

  /// The animation for the on-tap animation.
  late Animation<double> animation;

  /// The offset for the draggable bottom sheet.
  double? bottomSheetOffset;

  /// The margins of the attribution.
  Point? attributionMargins;

  /// The default map insets.
  final defaultMapInsets = const EdgeInsets.only(
    top: 108,
    bottom: 120,
  );

  /// The extra distance between the bottom sheet and the attribution.
  final sheetPadding = 16.0;

  @override
  void initState() {
    super.initState();

    // Connect the sheet movement listener to adapt the map insets.
    sheetMovementSubscription = widget.sheetMovement?.listen(
      (n) => fitAttributionPosition(sheetHeightRelative: n.extent),
    );

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      reverseDuration: const Duration(milliseconds: 0),
    )..addListener(() => setState(() {}));
    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  void didChangeDependencies() {
    // Check if the selected map layers have changed.
    layers = Provider.of<Layers>(context);
    if (layers.needsLayout[viewId] != false) {
      loadGeoLayers();
      layers.needsLayout[viewId] = false;
    }

    // Check if the position has changed.
    positioning = Provider.of<Positioning>(context);
    if (positioning.needsLayout[viewId] != false) {
      displayCurrentUserLocation();
      positioning.needsLayout[viewId] = false;
    }

    // Check if route-related stuff has changed.
    routing = Provider.of<Routing>(context);
    discomforts = Provider.of<Discomforts>(context);
    status = Provider.of<PredictionSGStatus>(context);
    if (routing.needsLayout[viewId] != false ||
        discomforts.needsLayout[viewId] != false ||
        status.needsLayout[viewId] != false) {
      loadRouteMapLayers();
      fitCameraToRouteBounds();
      routing.needsLayout[viewId] = false;
      discomforts.needsLayout[viewId] = false;
      status.needsLayout[viewId] = false;
    }

    super.didChangeDependencies();
  }

  /// Fit the camera to the current route.
  fitCameraToRouteBounds() async {
    if (mapController == null || !mounted) return;
    if (routing.selectedRoute == null || mapController?.isCameraMoving != false) return;
    // The delay is necessary, otherwise sometimes the camera won't move.
    await Future.delayed(const Duration(milliseconds: 500));
    await mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(routing.selectedRoute!.paddedBounds),
      duration: const Duration(milliseconds: 1000),
    );
  }

  /// Show the user location on the map.
  displayCurrentUserLocation() async {
    if (mapController == null || !mounted) return;
    if (positioning.lastPosition == null) return;
    // NOTE: Don't await this function, it will hang forever.
    // This is a bug in our mapbox fork.
    mapController?.updateUserLocation(
      lat: positioning.lastPosition!.latitude,
      lon: positioning.lastPosition!.longitude,
      alt: positioning.lastPosition!.altitude,
      acc: positioning.lastPosition!.accuracy,
      heading: positioning.lastPosition!.heading,
      speed: positioning.lastPosition!.speed,
    );
  }

  /// Load the map layers.
  loadGeoLayers() async {
    if (layerController == null) return;
    // Load the map features.
    if (layers.showAirStations) {
      if (!mounted) return;
      await BikeAirStationLayer(context).install(layerController!);
    } else {
      if (!mounted) return;
      await BikeAirStationLayer.removeFrom(layerController!);
    }
    if (layers.showConstructionSites) {
      if (!mounted) return;
      await ConstructionSitesLayer(context).install(layerController!);
    } else {
      if (!mounted) return;
      await ConstructionSitesLayer.removeFrom(layerController!);
    }
    if (layers.showParkingStations) {
      if (!mounted) return;
      await ParkingStationsLayer(context).install(layerController!);
    } else {
      if (!mounted) return;
      await ParkingStationsLayer.removeFrom(layerController!);
    }
    if (layers.showRentalStations) {
      if (!mounted) return;
      await RentalStationsLayer(context).install(layerController!);
    } else {
      if (!mounted) return;
      await RentalStationsLayer.removeFrom(layerController!);
    }
    if (layers.showRepairStations) {
      if (!mounted) return;
      await BikeShopLayer(context).install(layerController!);
    } else {
      if (!mounted) return;
      await BikeShopLayer.removeFrom(layerController!);
    }
    if (layers.showAccidentHotspots) {
      if (!mounted) return;
      await AccidentHotspotsLayer(context).install(layerController!);
    } else {
      if (!mounted) return;
      await AccidentHotspotsLayer.removeFrom(layerController!);
    }
  }

  /// Load the map layers for the route.
  loadRouteMapLayers() async {
    if (layerController == null) return;
    if (!mounted) return;
    await AllRoutesLayer(context).update(layerController!);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await SelectedRouteLayer(context).update(layerController!);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await WaypointsLayer(context).update(layerController!);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await DiscomfortsLayer(context).update(layerController!);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await TrafficLightsLayer(context).update(layerController!);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await OfflineCrossingsLayer(context).update(layerController!);
  }

  /// A callback that is called when the user taps a feature.
  onFeatureTapped(dynamic id, Point<double> point, LatLng coordinates) async {
    if (id is! String) return;
    // Map the ids of the layers to the corresponding feature.
    if (id.startsWith("route-")) {
      final routeIdx = int.tryParse(id.split("-")[1]);
      if (routeIdx == null) return;
      routing.switchToRoute(context, routeIdx);
    } else if (id.startsWith("discomfort-")) {
      final discomfortIdx = int.tryParse(id.split("-")[1]);
      if (discomfortIdx == null) return;
      discomforts.selectDiscomfort(discomfortIdx);
    }
  }

  /// Fit the attribution position to the position of the bottom sheet.
  fitAttributionPosition({double? sheetHeightRelative}) {
    final frame = MediaQuery.of(context);
    final sheetHeightAbs = sheetHeightRelative == null
        ? 114 + frame.padding.bottom + sheetPadding // Default value.
        : sheetHeightRelative * frame.size.height + sheetPadding;
    final maxBottomInset = frame.size.height - frame.padding.top - 100;
    double newBottomInset = min(maxBottomInset, sheetHeightAbs);
    mapController?.updateContentInsets(
      EdgeInsets.fromLTRB(
        defaultMapInsets.left,
        defaultMapInsets.top,
        defaultMapInsets.left,
        newBottomInset,
      ),
      false,
    );
    setState(
      () {
        bottomSheetOffset = newBottomInset;
        // On Android, the bottom inset needs to be added to the attribution margins.
        if (Platform.isAndroid) {
          attributionMargins = Point(20, newBottomInset);
        } else {
          attributionMargins = const Point(20, 0);
        }
      },
    );
  }

  /// A callback which is executed when the map was created.
  onMapCreated(MapboxMapController controller) async {
    mapController = controller;

    displayCurrentUserLocation();

    // Wrap the map controller in a layer controller for safer layer access.
    layerController = LayerController(mapController: controller);

    // Bind the interaction callbacks.
    controller.onFeatureTapped.add(onFeatureTapped);

    // Dont call any line/symbol/... removal/add operations here.
    // The mapcontroller won't have the necessary line/symbol/...manager.
  }

  /// A callback which is executed when the map style was (re-)loaded.
  onStyleLoaded(BuildContext context) async {
    if (mapController == null || layerController == null || !mounted) return;

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // Fit the content below the top and the bottom stuff.
    fitAttributionPosition();

    // Clear all layers and sources from the layer controller.
    layerController?.notifyStyleLoaded();
    // Trigger an update of the map layers.
    final ppi = MediaQuery.of(context).devicePixelRatio;

    fitCameraToRouteBounds();
    displayCurrentUserLocation();
    loadGeoLayers();

    if (!mounted) return;
    final offlineCrossings = await OfflineCrossingsLayer(context).install(
      layerController!,
      iconSize: ppi / 2.5,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final trafficLights = await TrafficLightsLayer(context).install(
      layerController!,
      iconSize: ppi / 2.5,
      below: offlineCrossings,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final discomforts = await DiscomfortsLayer(context).install(
      layerController!,
      iconSize: ppi / 4,
      below: trafficLights,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final waypoints = await WaypointsLayer(context).install(
      layerController!,
      iconSize: ppi / 4,
      below: discomforts,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final selectedRoute = await SelectedRouteLayer(context).install(
      layerController!,
      below: waypoints,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await AllRoutesLayer(context).install(
      layerController!,
      below: selectedRoute,
    );
  }

  /// A callback that is executed when the map was longclicked.
  onMapLongClick(BuildContext context, double x, double y) async {
    if (mapController == null) return;
    // Convert x and y into a lat/lon.
    final ppi = MediaQuery.of(context).devicePixelRatio;
    // On android, we need to multiply by the ppi.
    if (Platform.isAndroid) {
      x *= ppi;
      y *= ppi;
    }
    final point = Point(x, y);
    final coord = await mapController!.toLatLng(point);
    final geocoding = Provider.of<Geocoding>(context, listen: false);
    String fallback = "Wegpunkt ${(routing.selectedWaypoints?.length ?? 0) + 1}";
    String address = await geocoding.reverseGeocode(context, coord) ?? fallback;
    await routing.addWaypoint(Waypoint(coord.latitude, coord.longitude, address: address));
    await routing.loadRoutes(context);
  }

  @override
  void dispose() {
    animationController.dispose();
    // Unbind the sheet movement listener.
    sheetMovementSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Show the map.
        GestureDetector(
          onLongPressDown: (details) {
            tapPosition = details.localPosition;
            animationController.forward();
          },
          onLongPressCancel: () {
            animationController.reverse();
          },
          onLongPressEnd: (details) {
            animationController.reverse();
            onMapLongClick(context, details.localPosition.dx, details.localPosition.dy);
          },
          behavior: HitTestBehavior.translucent,
          child: AppMap(
            puckImage: Theme.of(context).brightness == Brightness.dark
                ? 'assets/images/position-static-dark.png'
                : 'assets/images/position-static-light.png',
            puckSize: 64,
            onMapCreated: onMapCreated,
            onStyleLoaded: () => onStyleLoaded(context),
            // On iOS, the logoViewMargins and attributionButtonMargins will be set by
            // updateContentInsets. This is why we set them to 0 here.
            logoViewMargins: attributionMargins,
            attributionButtonMargins: attributionMargins,
          ),
        ),

        // Show an animation when the user taps the map.
        if (tapPosition != null)
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  left: tapPosition!.dx - animation.value * 128 - 12,
                  top: tapPosition!.dy - animation.value * 128 - 12,
                  child: Opacity(
                    opacity: max(0, min(1, (animation.value) * 4)),
                    child: Container(
                      width: animation.value * 256 + 24,
                      height: animation.value * 256 + 24,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(1.0 - animation.value),
                          width: 8.0 - animation.value * 8,
                        ),
                        borderRadius: BorderRadius.circular(128),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: tapPosition!.dx - (1.0 - animation.value) * 64 - 12,
                  top: tapPosition!.dy - (1.0 - animation.value) * 64 - 12,
                  child: Opacity(
                    opacity: max(0, (animation.value - 0.5) * 2),
                    child: Container(
                      width: (1.0 - animation.value) * 128 + 24,
                      height: (1.0 - animation.value) * 128 + 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2 * animation.value),
                        borderRadius: BorderRadius.circular(128),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: tapPosition!.dx - 12,
                  top: min(12 + tapPosition!.dy - 256 + 256 * max(0, (animation.value - 0.25) * 4 / 3),
                          tapPosition!.dy) -
                      12,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Opacity(
                      opacity: max(0, (animation.value - 0.5) * 2),
                      child: Image.asset(
                        'assets/images/pin.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: tapPosition!.dx - 12,
                  top: (tapPosition!.dy - 256 + 256 * max(0, (animation.value - 0.25) * 4 / 3)) - 12,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Opacity(
                      opacity: max(0, (animation.value - 0.5) * 2),
                      child: Image.asset(
                        'assets/images/waypoint.drawio.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
