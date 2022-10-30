import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as LatLng2;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/geo.dart';
import 'package:priobike/common/map/layers.dart';
import 'package:priobike/common/map/markers.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/mapcontroller.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';

/// The zoomToGeographicalDistance map includes all zoom level and maps it to the distance in meter per pixel.
/// Taken from +-60 Latitude since it only needs to be approximate and its closer to 53 than +-40.
/// Its also to small in worst case.
final Map<int, double> zoomToGeographicalDistance = {
  0: 39135.742,
  1: 19567.871,
  2: 9783.936,
  3: 4891.968,
  4: 2445.984,
  5: 1222.992,
  6: 611.496,
  7: 305.748,
  8: 152.874,
  9: 76.437,
  10: 38.218,
  11: 19.109,
  12: 9.555,
  13: 4.777,
  14: 2.389,
  15: 1.194,
  16: 0.597,
  17: 0.299,
  18: 0.149,
  19: 0.075,
  20: 0.047,
  21: 0.019,
  22: 0.009
};

class RoutingMapView extends StatefulWidget {
  /// The stream that receives notifications when the bottom sheet is dragged.
  final Stream<DraggableScrollableNotification>? sheetMovement;

  /// The selected ControllerType
  final ControllerType controllerType;

  const RoutingMapView(
      {required this.sheetMovement, required this.controllerType, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> {
  static const viewId = "routingOLD.views.map";

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

  /// A map controller for the map.
  MapboxMapController? mapboxMapController;

  /// The geo feature loader for the map.
  GeoFeatureLoader? geoFeatureLoader;

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

  /// The stream that receives notifications when the bottom sheet is dragged.
  StreamSubscription<DraggableScrollableNotification>?
      sheetMovementSubscription;

  /// The default map insets.
  static const defaultMapInsets = EdgeInsets.only(
    top: 108,
    bottom: 80,
    left: 8,
    right: 8,
  );

  @override
  void initState() {
    super.initState();
    sheetMovementSubscription =
        widget.sheetMovement?.listen(onScrollBottomSheet);
  }

  /// A callback that gets fired when the bottom sheet of the parent view is dragged.
  Future<void> onScrollBottomSheet(DraggableScrollableNotification n) async {
    final frame = MediaQuery.of(context);
    final maxBottomInset = frame.size.height - frame.padding.top - 300;
    final newBottomInset = min(maxBottomInset, n.extent * frame.size.height);
    mapboxMapController?.updateContentInsets(
        EdgeInsets.fromLTRB(defaultMapInsets.left, defaultMapInsets.top,
            defaultMapInsets.left, newBottomInset),
        false);
  }

  @override
  void didChangeDependencies() {
    routing = Provider.of<Routing>(context);
    if (routing.needsLayout[viewId] != false) {
      onRoutingUpdate();
      routing.needsLayout[viewId] = false;
    }

    discomforts = Provider.of<Discomforts>(context);
    if (discomforts.needsLayout[viewId] != false) {
      onDiscomfortsUpdate();
      discomforts.needsLayout[viewId] = false;
    }

    positioning = Provider.of<Positioning>(context);
    if (positioning.needsLayout[viewId] != false) {
      onPositioningUpdate();
      positioning.needsLayout[viewId] = false;
    }

    layers = Provider.of<Layers>(context);
    if (layers.needsLayout[viewId] != false) {
      onLayersUpdate();
      layers.needsLayout[viewId] = false;
    }

    mapController = Provider.of<MapController>(context);

    // selectOnMapView should not display RouteLayers since it causes problems on dispose
    // if (widget.controllerType == ControllerType.main) adaptMap();

    super.didChangeDependencies();
  }

  Future<void> onRoutingUpdate() async {
    await loadAllRouteLayers();
    await loadSelectedRouteLayer();
    await loadTrafficLightMarkers();
    await loadOfflineCrossingMarkers();
    await loadWaypointMarkers();
    await moveMap();
    await loadRouteLabels();
  }

  Future<void> onDiscomfortsUpdate() async {
    await loadDiscomforts();
  }

  Future<void> onPositioningUpdate() async {
    await showUserLocation();
  }

  Future<void> onLayersUpdate() async {
    await loadLayers();
  }

  /// Load the route layerouting.
  Future<void> loadAllRouteLayers() async {
    // If we have no map controller, we cannot load the layerouting.
    if (mapboxMapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldRoutes = allRoutes;
    // Add the new layers, if they exist.
    allRoutes = [];
    for (r.Route altRoute in routing.allRoutes ?? []) {
      allRoutes!.add(await mapboxMapController!.addLine(
        RouteBackgroundLayer(
            points: altRoute.route.map((e) => LatLng(e.lat, e.lon)).toList()),
        altRoute.toJson(),
      ));
      // Make it easier to click the alt route layer.
      allRoutes!.add(await mapboxMapController!.addLine(
        RouteBackgroundClickLayer(
            points: altRoute.route.map((e) => LatLng(e.lat, e.lon)).toList()),
        altRoute.toJson(),
      ));
    }
    // Remove the old layerouting.
    await mapboxMapController?.removeLines(oldRoutes ?? []);
  }

  /// Load the current route layer.
  Future<void> loadSelectedRouteLayer() async {
    // If we have no map controller, we cannot load the route layer.
    if (mapboxMapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldRoute = route;
    if (routing.selectedRoute == null) return;
    // Add the new route layer.
    route = await mapboxMapController!.addLine(
      RouteLayer(
          points: routing.selectedRoute!.route
              .map((e) => LatLng(e.lat, e.lon))
              .toList()),
      routing.selectedRoute!.toJson(),
    );
    if (oldRoute != null) await mapboxMapController?.removeLine(oldRoute);
  }

  /// Load the discomforts.
  Future<void> loadDiscomforts() async {
    // If we have no map controller, we cannot load the layerouting.
    if (mapboxMapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldDiscomfortLocations = discomfortLocations;
    final oldDiscomfortSections = discomfortSections;
    // Add the new layerouting.
    discomfortLocations = [];
    discomfortSections = [];
    final iconSize = MediaQuery.of(context).devicePixelRatio / 4;
    for (MapEntry<int, DiscomfortSegment> e
        in discomforts.foundDiscomforts?.asMap().entries ?? []) {
      if (e.value.coordinates.isEmpty) continue;
      if (e.value.coordinates.length == 1) {
        // A single location.
        final location = e.value.coordinates.first;
        discomfortLocations!.add(await mapboxMapController!.addSymbol(
          DiscomfortLocationMarker(
              geo: location,
              number: e.key + 1,
              zIndex: discomforts.selectedDiscomfort == e.value ? 2 : 1,
              iconSize: discomforts.selectedDiscomfort == e.value
                  ? iconSize * 1.33
                  : iconSize),
          e.value.toJson(),
        ));
      } else {
        // A section of the route.
        discomfortLocations!.add(await mapboxMapController!.addSymbol(
          DiscomfortLocationMarker(
              geo: e.value.coordinates.first,
              number: e.key + 1,
              zIndex: discomforts.selectedDiscomfort == e.value ? 2 : 1,
              iconSize: discomforts.selectedDiscomfort == e.value
                  ? iconSize * 1.33
                  : iconSize),
          e.value.toJson(),
        ));
        discomfortSections!.add(await mapboxMapController!.addLine(
          DiscomfortSectionLayer(points: e.value.coordinates),
          e.value.toJson(),
        ));
        // Make it easier to click the discomfort section layer.
        discomfortSections!.add(await mapboxMapController!.addLine(
          DiscomfortSectionClickLayer(points: e.value.coordinates),
          e.value.toJson(),
        ));
      }
    }
    // Remove the old layerouting.
    await mapboxMapController?.removeSymbols(oldDiscomfortLocations ?? []);
    await mapboxMapController?.removeLines(oldDiscomfortSections ?? []);
  }

  /// Load the Route labels.
  Future<void> loadRouteLabels() async {
    // If we have no map controller, we cannot load the routing labels.
    if (mapboxMapController == null ||
        mapboxMapController!.cameraPosition == null ||
        routing.allRoutes == null ||
        routing.allRoutes!.length != 2 ||
        routing.selectedRoute == null) return;

    final iconSize = MediaQuery.of(context).devicePixelRatio / 3;

    final oldRouteLabelLocations = routeLabelLocations;
    routeLabelLocations = [];

    var distance = const LatLng2.Distance();

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double meterPerPixel = zoomToGeographicalDistance[
            mapboxMapController!.cameraPosition!.zoom.toInt()] ??
        0;
    double cameraPosLat = mapboxMapController!.cameraPosition!.target.latitude;
    double cameraPosLong =
        mapboxMapController!.cameraPosition!.target.longitude;

    // Cast to LatLng2 format.
    LatLng2.LatLng cameraPos = LatLng2.LatLng(cameraPosLat, cameraPosLong);

    // Getting the bounds north, east, south, west.
    // Calculation of Bounding Points: Distance between camera position and the distance to the edge of the screen.
    LatLng2.LatLng north =
        distance.offset(cameraPos, height / 2 * meterPerPixel, 0);
    LatLng2.LatLng east =
        distance.offset(cameraPos, width / 2 * meterPerPixel, 90);
    LatLng2.LatLng south =
        distance.offset(cameraPos, height / 2 * meterPerPixel, 180);
    LatLng2.LatLng west =
        distance.offset(cameraPos, width / 2 * meterPerPixel, 270);

    // Search appropriate Point in Route
    for (r.Route route in routing.allRoutes!) {
      // Find closest to camera in bounds
      GHCoordinate? chosenCoordinate;
      List<GHCoordinate> uniqueInBounceCoordinates = [];

      // go through all coordinates.
      for (GHCoordinate coordinate in route.path.points.coordinates) {
        // Check if the coordinate is unique and not on the same line.
        bool unique = true;
        // Loop through all route coordinates.
        for (r.Route routeToBeChecked in routing.allRoutes!) {
          // Would always be not unique without this check.
          if (routeToBeChecked.id != route.id) {
            // Compare coordinate to all coordinates in other route.
            for (GHCoordinate coordinateToBeChecked
                in routeToBeChecked.path.points.coordinates) {
              if (!unique) {
                break;
              }
              if (coordinateToBeChecked.lon == coordinate.lon &&
                  coordinateToBeChecked.lat == coordinate.lat) {
                unique = false;
              }
            }
          }
        }

        if (unique) {
          // Check bounds, no check for side of earth needed since in Hamburg.
          if (coordinate.lat > south.latitude &&
              coordinate.lat < north.latitude &&
              coordinate.lon > west.longitude &&
              coordinate.lon < east.longitude) {
            uniqueInBounceCoordinates.add(coordinate);
          }
        }
      }

      // Determine which coordinate to use.
      if (uniqueInBounceCoordinates.isNotEmpty) {
        chosenCoordinate =
            uniqueInBounceCoordinates[uniqueInBounceCoordinates.length ~/ 2];
      }

      if (chosenCoordinate != null) {
        // Found coordinate and add Label with time.
        routeLabelLocations!.add(await mapboxMapController!.addSymbol(
          RouteLabel(
              primary: routing.selectedRoute!.id == route.id,
              geo: LatLng(chosenCoordinate.lat, chosenCoordinate.lon),
              number: ((route.path.time * 0.001) * 0.016).round(),
              iconSize: iconSize),
          {"data": route.toJson(), "isRouteLabel": true},
        ));
      }
    }
    // Remove the old labels.
    await mapboxMapController?.removeSymbols(oldRouteLabelLocations ?? []);
  }

  /// Load the current traffic lights.
  Future<void> loadTrafficLightMarkers() async {
    // If we have no map controller, we cannot load the traffic lights.
    if (mapboxMapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldTrafficLights = trafficLights;
    // Create a new traffic light marker for each traffic light.
    trafficLights = [];
    final settings = Provider.of<Settings>(context, listen: false);
    final willShowLabels = settings.sgLabelsMode == SGLabelsMode.enabled;
    // Check the prediction status of the traffic light.
    final statusProvider =
        Provider.of<PredictionSGStatus>(context, listen: false);
    final iconSize = MediaQuery.of(context).devicePixelRatio / 3;
    for (Sg sg in routing.selectedRoute?.signalGroups ?? []) {
      final status = statusProvider.cache[sg.id];
      if (status == null) {
        trafficLights!.add(await mapboxMapController!.addSymbol(
            OfflineMarker(
              iconSize: iconSize,
              geo: LatLng(sg.position.lat, sg.position.lon),
              label: willShowLabels ? sg.label : null,
            ),
            {"trafficLightMarker": true}));
      } else if (status.predictionState == SGPredictionState.offline) {
        trafficLights!.add(await mapboxMapController!.addSymbol(
            OfflineMarker(
              iconSize: iconSize,
              geo: LatLng(sg.position.lat, sg.position.lon),
              label: willShowLabels ? sg.label : null,
            ),
            {"trafficLightMarker": true}));
      } else if (status.predictionState == SGPredictionState.bad) {
        trafficLights!.add(await mapboxMapController!.addSymbol(
            BadSignalMarker(
              iconSize: iconSize,
              geo: LatLng(sg.position.lat, sg.position.lon),
              label: willShowLabels ? sg.label : null,
            ),
            {"trafficLightMarker": true}));
      } else {
        trafficLights!.add(await mapboxMapController!.addSymbol(
            OnlineMarker(
              iconSize: iconSize,
              geo: LatLng(sg.position.lat, sg.position.lon),
              label: willShowLabels ? sg.label : null,
            ),
            {"trafficLightMarker": true}));
      }
    }
    // Remove the old traffic lights.
    await mapboxMapController?.removeSymbols(oldTrafficLights ?? []);
  }

  /// Load the current crossings.
  Future<void> loadOfflineCrossingMarkers() async {
    // If we have no map controller, we cannot load the crossings.
    if (mapboxMapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldCrossings = offlineCrossings;
    // Create a new crossing marker for each crossing.
    offlineCrossings = [];
    final settings = Provider.of<Settings>(context, listen: false);
    final willShowLabels = settings.sgLabelsMode == SGLabelsMode.enabled;
    // Check the prediction status of the traffic light.
    final iconSize = MediaQuery.of(context).devicePixelRatio / 3;
    for (Crossing crossing in routing.selectedRoute?.crossings ?? []) {
      if (crossing.connected) continue;
      offlineCrossings!.add(await mapboxMapController!.addSymbol(
          DisconnectedMarker(
            iconSize: iconSize,
            geo: LatLng(crossing.position.lat, crossing.position.lon),
            label: willShowLabels ? crossing.name : null,
          ),
          {"trafficLightMarker": true}));
    }
    // Remove the old crossings.
    await mapboxMapController?.removeSymbols(oldCrossings ?? []);
  }

  /// Load the current waypoint markerouting.
  Future<void> loadWaypointMarkers() async {
    // If we have no map controller, we cannot load the waypoint layer.
    if (mapboxMapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldWaypoints = waypoints;
    waypoints = [];
    // Create a new waypoint marker for each waypoint.
    for (MapEntry<int, Waypoint> entry
        in routing.selectedWaypoints?.asMap().entries ?? []) {
      if (entry.key == 0) {
        waypoints!.add(await mapboxMapController!.addSymbol(
          StartMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      } else if (entry.key == routing.selectedWaypoints!.length - 1) {
        waypoints!.add(await mapboxMapController!.addSymbol(
          DestinationMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      } else {
        waypoints!.add(await mapboxMapController!.addSymbol(
          WaypointMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      }
    }
    // Remove the old waypoints.
    await mapboxMapController?.removeSymbols(oldWaypoints ?? []);
  }

  /// Adapt the map controller.
  Future<void> moveMap() async {
    if (mapboxMapController == null) return;
    if (routing.selectedRoute != null && !mapboxMapController!.isCameraMoving) {
      // The delay is necessary, otherwise sometimes the camera won't move.
      await Future.delayed(const Duration(milliseconds: 500));
      await mapboxMapController?.animateCamera(
        CameraUpdate.newLatLngBounds(routing.selectedRoute!.paddedBounds),
        duration: const Duration(milliseconds: 1000),
      );
    }
  }

  /// Show the user location on the map.
  Future<void> showUserLocation() async {
    if (mapboxMapController == null) return;
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
  Future<void> loadLayers() async {
    if (mapboxMapController == null) return;

    // Load the map features.
    geoFeatureLoader = GeoFeatureLoader(mapboxMapController!);
    await geoFeatureLoader!.removeFeatures();
    await geoFeatureLoader!.loadFeatures(context);
  }

  /// A callback that is called when the user taps a fill.
  Future<void> onFillTapped(Fill fill) async {
    /* Do nothing */
  }

  /// A callback that is called when the user taps a circle.
  Future<void> onCircleTapped(Circle circle) async {
    /* Do nothing */
  }

  /// A callback that is called when the user taps a line.
  Future<void> onLineTapped(Line line) async {
    // If the line corresponds to a discomfort line, we select the discomfort.
    for (Line discomfortLine in discomfortSections ?? []) {
      if (line.id == discomfortLine.id) {
        final discomfort = DiscomfortSegment.fromJson(line.data);
        discomforts.selectDiscomfort(discomfort);
        return;
      }
    }
    // If the line corresponds to an alternative route, we select that one.
    for (Line routeLine in allRoutes ?? []) {
      if (line.id == routeLine.id) {
        final route = r.Route.fromJson(line.data);
        routing.switchToRoute(context, route);
        return;
      }
    }
  }

  /// A callback that is called when the user taps a symbol.
  Future<void> onSymbolTapped(Symbol symbol) async {
    print("TEST");

    // Check if symbol is a RouteLabel.
    if (symbol.data != null &&
        symbol.data!["isRouteLabel"] != null &&
        symbol.data!["isRouteLabel"]) {
      r.Route selectedRoute = r.Route.fromJson(symbol.data!["data"]);
      routing.switchToRoute(context, selectedRoute);
    }

    // Check if symbol is a trafficLight.
    if (symbol.data != null &&
        symbol.data!["trafficLightMarker"] != null &&
        symbol.data!["trafficLightMarker"]) {
      discomforts.selectTrafficLight();
      discomforts.unselectDiscomfort();
    }
    // If the symbol corresponds to a discomfort, we select that discomfort.
    for (Symbol discomfortLocation in discomfortLocations ?? []) {
      if (symbol.id == discomfortLocation.id) {
        final discomfort = DiscomfortSegment.fromJson(symbol.data);
        discomforts.selectDiscomfort(discomfort);
      }
    }
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

    // Bind the interaction callbacks.
    controller.onFillTapped.add(onFillTapped);
    controller.onCircleTapped.add(onCircleTapped);
    controller.onLineTapped.add(onLineTapped);
    controller.onSymbolTapped.add(onSymbolTapped);

    // Dont call any line/symbol/... removal/add operations here.
    // The mapcontroller won't have the necessary line/symbol/...manager.
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(BuildContext context) async {
    if (mapboxMapController == null) return;

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapboxMapController!).loadSymbols();

    // Fit the content below the top and the bottom stuff.
    await mapboxMapController!.updateContentInsets(defaultMapInsets);

    // Allow overlaps so that important symbols and texts are not hidden.
    await mapboxMapController!.setSymbolIconAllowOverlap(true);
    await mapboxMapController!.setSymbolIconIgnorePlacement(true);
    await mapboxMapController!.setSymbolTextAllowOverlap(true);
    await mapboxMapController!.setSymbolTextIgnorePlacement(true);

    // Force adapt the map.
    await onRoutingUpdate();
    await onDiscomfortsUpdate();
    await onPositioningUpdate();
    await onLayersUpdate();
  }

  /// A callback that is executed when the map was longclicked.
  Future<void> onMapLongClick(BuildContext context, LatLng coord) async {
    final geocoding = Provider.of<Geocoding>(context, listen: false);
    String fallback =
        "Wegpunkt ${(routing.selectedWaypoints?.length ?? 0) + 1}";
    String address = await geocoding.reverseGeocode(context, coord) ?? fallback;
    await routing.addWaypoint(
        Waypoint(coord.latitude, coord.longitude, address: address));
    await routing.loadRoutes(context);
  }

  /// A callback that is executed when the map was clicked.
  Future<void> onMapClick(BuildContext context, LatLng coord) async {
    if (discomforts.selectedDiscomfort != null)
      discomforts.unselectDiscomfort();
    if (discomforts.trafficLightClicked) discomforts.unselectTrafficLight();
  }

  void onCameraTrackingDismissed() {
    mapController.setMyLocationTrackingModeNone(widget.controllerType);
  }

  @override
  void dispose() {
    () async {
      // Remove geo features from the map.
      await geoFeatureLoader?.removeFeatures();

      // Remove all layers from the map.
      await mapboxMapController?.clearFills();
      await mapboxMapController?.clearCircles();
      await mapboxMapController?.clearLines();
      await mapboxMapController?.clearSymbols();

      // Unbind the sheet movement listener.
      await sheetMovementSubscription?.cancel();

      // Unbind the interaction callbacks.
      mapboxMapController?.onFillTapped.remove(onFillTapped);
      mapboxMapController?.onCircleTapped.remove(onCircleTapped);
      mapboxMapController?.onLineTapped.remove(onLineTapped);
      mapboxMapController?.onSymbolTapped.remove(onSymbolTapped);
      mapboxMapController?.dispose();
    }();

    mapController.unsetController(widget.controllerType);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppMap(
      onMapCreated: onMapCreated,
      onCameraTrackingDismissed: onCameraTrackingDismissed,
      onStyleLoaded: () => onStyleLoaded(context),
      onMapClick: (_, coord) => onMapClick(context, coord),
      onMapLongClick: (_, coord) => onMapLongClick(context, coord),
      myLocationTrackingMode: ControllerType.main == widget.controllerType
          ? mapController.myLocationTrackingMode
          : mapController.myLocationTrackingModeSelectOnMapView,
      puckImage: Theme.of(context).brightness == Brightness.dark
          ? 'assets/images/position-static-dark.png'
          : 'assets/images/position-static-light.png',
      puckSize: 64,
    );
  }
}
