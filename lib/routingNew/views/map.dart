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
import 'package:priobike/routingNew/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routingNew/services/mapcontroller.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';

class RoutingMapView extends StatefulWidget {
  /// The stream that receives notifications when the bottom sheet is dragged.
  final Stream<DraggableScrollableNotification>? sheetMovement;

  /// The selected ControllerType
  final ControllerType controllerType;

  /// The bool that decides if the Route will be displayed.
  final bool withRouting;

  const RoutingMapView({required this.sheetMovement, required this.controllerType, required this.withRouting, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> with TickerProviderStateMixin {
  static const viewId = "routingNew.views.map";

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated discomfort service, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated location service, which is injected by the provider.
  late Positioning positioning;

  /// The associated layers service, which is injected by the provider.
  late Layers layers;

  /// The associated settings service, which is injected by the provider.
  late MapController mapController;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  /// A map controller for the map.
  MapboxMapController? mapboxMapController;

  /// All routes that are displayed, if they were fetched.
  List<Line>? allRoutes;

  /// The route that is displayed, if a route is selected.
  Line? route;

  /// The discomfort sections that are displayed, if they were fetched.
  List<Line>? discomfortSections;

  /// The discomfort locations that are displayed, if they were fetched.
  List<Symbol>? discomfortLocations;

  /// The route label locations that are displayed, if they were fetched.
  List<Symbol>? routeLabelLocations;

  /// The traffic lights that are displayed, if there are traffic lights on the route.
  List<Symbol>? trafficLights;

  /// The offline crossings that are displayed, if there are offline crossings on the route.
  List<Symbol>? offlineCrossings;

  /// The current waypoints, if the route is selected.
  List<Symbol>? waypoints;

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

    mapController = Provider.of<MapController>(context);

    super.didChangeDependencies();
  }

  /// Fit the camera to the current route.
  fitCameraToRouteBounds() async {
    if (mapboxMapController == null || !mounted) return;
    if (routing.selectedRoute == null || mapboxMapController?.isCameraMoving != false) return;
    // The delay is necessary, otherwise sometimes the camera won't move.
    await Future.delayed(const Duration(milliseconds: 500));
    await mapboxMapController?.animateCamera(
      CameraUpdate.newLatLngBounds(routing.selectedRoute!.paddedBounds),
      duration: const Duration(milliseconds: 1000),
    );
  }

  /// Show the user location on the map.
  displayCurrentUserLocation() async {
    if (mapboxMapController == null || !mounted) return;
    if (positioning.lastPosition == null) return;
    await mapboxMapController?.updateUserLocation(
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
    if (mapboxMapController == null || !mounted) return;
    // Load the map features.
    if (layers.showAirStations) {
      BikeAirStationLayer(context).install(layerController!);
    } else {
      BikeAirStationLayer.removeFrom(layerController!);
    }
    if (layers.showConstructionSites) {
      ConstructionSitesLayer(context).install(layerController!);
    } else {
      ConstructionSitesLayer.removeFrom(layerController!);
    }
    if (layers.showParkingStations) {
      ParkingStationsLayer(context).install(layerController!);
    } else {
      ParkingStationsLayer.removeFrom(layerController!);
    }
    if (layers.showRentalStations) {
      RentalStationsLayer(context).install(layerController!);
    } else {
      RentalStationsLayer.removeFrom(layerController!);
    }
    if (layers.showRepairStations) {
      BikeShopLayer(context).install(layerController!);
    } else {
      BikeShopLayer.removeFrom(layerController!);
    }
    if (layers.showAccidentHotspots) {
      AccidentHotspotsLayer(context).install(layerController!);
    } else {
      AccidentHotspotsLayer.removeFrom(layerController!);
    }
  }

  /// Load the map layers for the route.
  loadRouteMapLayers() async {
    if (layerController == null) return;
    await AllRoutesLayer(context).update(layerController!);
    await SelectedRouteLayer(context).update(layerController!);
    await WaypointsLayer(context).update(layerController!);
    await DiscomfortsLayer(context).update(layerController!);
    await TrafficLightsLayer(context).update(layerController!);
    await OfflineCrossingsLayer(context).update(layerController!);
    await RouteLabelLayer(context).update(layerController!);
  }

  /// A callback that is called when the user taps a feature.
  onFeatureTapped(dynamic id, Point<double> point, LatLng coordinates) async {
    // Check if symbol is a RouteLabel.
    // if (symbol.data != null && symbol.data!["isRouteLabel"] != null && symbol.data!["isRouteLabel"]) {
    //   r.Route selectedRoute = r.Route.fromJson(symbol.data!["data"]);
    //   routing.switchToRoute(context, selectedRoute);
    // }

    if (id is! String) return;
    // Map the ids of the layers to the corresponding feature.
    if (id.startsWith("route-")) {
      final routeIdx = int.tryParse(id.split("-")[1]);
      if (routeIdx == null) return;
      routing.switchToRoute(context, routeIdx);
      discomforts.unselectDiscomfort();
      discomforts.unselectTrafficLight();
    } else if (id.startsWith("discomfort-")) {
      final discomfortIdx = int.tryParse(id.split("-")[1]);
      if (discomfortIdx == null) return;
      discomforts.selectDiscomfort(discomfortIdx);
    } else if (id.startsWith("traffic-light")) {
      discomforts.selectTrafficLight();
      discomforts.unselectDiscomfort();
    } else if (id.startsWith("routeLabel")) {
      final routeLabelIdx = int.tryParse(id.split("-")[1]);
      if (routeLabelIdx == null || (routing.selectedRoute != null && routeLabelIdx == routing.selectedRoute!.id)) {
        return;
      }
      routing.switchToRoute(context, routeLabelIdx);
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
    mapboxMapController?.updateContentInsets(
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
  Future<void> onMapCreated(MapboxMapController controller) async {
    switch (widget.controllerType) {
      case ControllerType.main:
        mapController.controller = controller;
        break;
      case ControllerType.selectOnMap:
        mapController.controllerSelectOnMap = controller;
        break;
    }

    mapboxMapController = controller;

    // Wrap the map controller in a layer controller for safer layer access.
    layerController = LayerController(mapController: controller);

    // Bind the interaction callbacks.
    controller.onFeatureTapped.add(onFeatureTapped);

    // Dont call any line/symbol/... removal/add operations here.
    // The mapcontroller won't have the necessary line/symbol/...manager.
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(BuildContext context) async {
    if (mapboxMapController == null) return;

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapboxMapController!).loadSymbols();

    // Fit the content below the top and the bottom stuff.
    fitAttributionPosition();

    // Clear all layers and sources from the layer controller.
    layerController?.notifyStyleLoaded();
    // Trigger an update of the map layers.
    final ppi = MediaQuery.of(context).devicePixelRatio;
    final offlineCrossings = await OfflineCrossingsLayer(context).install(
      layerController!,
      iconSize: ppi / 2.5,
    );
    final trafficLights = await TrafficLightsLayer(context).install(
      layerController!,
      iconSize: ppi / 2.5,
      below: offlineCrossings,
    );
    final discomforts = await DiscomfortsLayer(context).install(
      layerController!,
      iconSize: ppi / 4,
      below: trafficLights,
    );
    final waypoints = await WaypointsLayer(context).install(
      layerController!,
      iconSize: ppi / 4,
      below: discomforts,
    );
    final selectedRoute = await SelectedRouteLayer(context).install(
      layerController!,
      below: waypoints,
    );
    await AllRoutesLayer(context).install(
      layerController!,
      below: selectedRoute,
    );
    await RouteLabelLayer(context).install(layerController!, iconSize: ppi / 3);

    await loadRouteMapLayers();
    await fitCameraToRouteBounds();
    await displayCurrentUserLocation();
    await loadGeoLayers();
  }

  /// A callback that is executed when the map was longclicked.
  onMapLongClick(BuildContext context, double x, double y) async {
    if (mapboxMapController == null) return;
    // Convert x and y into a lat/lon.
    final ppi = MediaQuery.of(context).devicePixelRatio;
    // On android, we need to multiply by the ppi.
    if (Platform.isAndroid) {
      x *= ppi;
      y *= ppi;
    }
    final point = Point(x, y);
    final coord = await mapboxMapController!.toLatLng(point);
    final geocoding = Provider.of<Geocoding>(context, listen: false);
    String fallback = "Wegpunkt ${(routing.selectedWaypoints?.length ?? 0) + 1}";
    String address = await geocoding.reverseGeocode(context, coord) ?? fallback;
    await routing.addWaypoint(Waypoint(coord.latitude, coord.longitude, address: address));
    await routing.loadRoutes(context);
  }

  /// A callback that is executed when the map was clicked.
  void onMapClick(Point<double> point, LatLng coord) {
    if (discomforts.selectedDiscomfort != null) {
      discomforts.unselectDiscomfort();
    }
    if (discomforts.trafficLightClicked) discomforts.unselectTrafficLight();
  }

  void onCameraTrackingDismissed() {
    mapController.setMyLocationTrackingModeNone(widget.controllerType);
  }

  /// A callback that is executed when the camera movement of the user stopped.
  Future<void> onCameraIdle() async {
    // Check if the route labels have to be positionally adjusted.
    if (widget.withRouting) {
      //FIXME check if necessary
      await RouteLabelLayer(context).update(layerController!);
    }
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
            onMapClick: onMapClick,
            onCameraIdle: () => onCameraIdle(),
            myLocationTrackingMode: ControllerType.main == widget.controllerType
                ? mapController.myLocationTrackingMode
                : mapController.myLocationTrackingModeSelectOnMapView,
            onStyleLoaded: () => onStyleLoaded(context),
            onCameraTrackingDismissed: onCameraTrackingDismissed,
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
