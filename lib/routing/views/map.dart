import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/geo.dart';
import 'package:priobike/common/map/layers.dart';
import 'package:priobike/common/map/markers.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';

class RoutingMapView extends StatefulWidget {
  /// The stream that receives notifications when the bottom sheet is dragged.
  final Stream<DraggableScrollableNotification>? sheetMovement;

  const RoutingMapView({required this.sheetMovement, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> {
  static const viewId = "routing.views.map";

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated discomfort service, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated location service, which is injected by the provider.
  late Positioning positioning;

  /// The associated layers service, which is injected by the provider.
  late Layers layers;

  /// A map controller for the map.
  MapboxMapController? mapController;

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

  /// The traffic lights that are displayed, if there are traffic lights on the route.
  List<Symbol>? trafficLights;

  /// The offline crossings that are displayed, if there are offline crossings on the route.
  List<Symbol>? offlineCrossings;

  /// The current waypoints, if the route is selected.
  List<Symbol>? waypoints;

  /// The stream that receives notifications when the bottom sheet is dragged.
  StreamSubscription<DraggableScrollableNotification>? sheetMovementSubscription;

  /// The default map insets.
  final defaultMapInsets = const EdgeInsets.only(
    top: 108,
    bottom: 80,
    left: 8,
    right: 8,
  );

  @override
  void initState() {
    super.initState();
    sheetMovementSubscription = widget.sheetMovement?.listen(onScrollBottomSheet);

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      await layers.loadPreferences();
    });
  }

  /// A callback that gets fired when the bottom sheet of the parent view is dragged.
  Future<void> onScrollBottomSheet(DraggableScrollableNotification n) async {
    final frame = MediaQuery.of(context);
    final maxBottomInset = frame.size.height - frame.padding.top - 300;
    final newBottomInset = min(maxBottomInset, n.extent * frame.size.height);
    mapController?.updateContentInsets(
        EdgeInsets.fromLTRB(defaultMapInsets.left, defaultMapInsets.top, defaultMapInsets.left, newBottomInset), false);
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

    super.didChangeDependencies();
  }

  Future<void> onRoutingUpdate() async {
    await loadAllRouteLayers();
    await loadSelectedRouteLayer();
    await loadTrafficLightMarkers();
    await loadOfflineCrossingMarkers();
    await loadWaypointMarkers();
    await moveMap();
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
    if (mapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldRoutes = allRoutes;
    // Add the new layers, if they exist.
    allRoutes = [];
    for (r.Route altRoute in routing.allRoutes ?? []) {
      allRoutes!.add(await mapController!.addLine(
        RouteBackgroundLayer(points: altRoute.route.map((e) => LatLng(e.lat, e.lon)).toList()),
        altRoute.toJson(),
      ));
      // Make it easier to click the alt route layer.
      allRoutes!.add(await mapController!.addLine(
        RouteBackgroundClickLayer(points: altRoute.route.map((e) => LatLng(e.lat, e.lon)).toList()),
        altRoute.toJson(),
      ));
    }
    // Remove the old layerouting.
    await mapController?.removeLines(oldRoutes ?? []);
  }

  /// Load the current route layer.
  Future<void> loadSelectedRouteLayer() async {
    // If we have no map controller, we cannot load the route layer.
    if (mapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldRoute = route;
    if (routing.selectedRoute == null) return;
    // Add the new route layer.
    route = await mapController!.addLine(
      RouteLayer(points: routing.selectedRoute!.route.map((e) => LatLng(e.lat, e.lon)).toList()),
      routing.selectedRoute!.toJson(),
    );
    if (oldRoute != null) await mapController?.removeLine(oldRoute);
  }

  /// Load the discomforts.
  Future<void> loadDiscomforts() async {
    // If we have no map controller, we cannot load the layerouting.
    if (mapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldDiscomfortLocations = discomfortLocations;
    final oldDiscomfortSections = discomfortSections;
    // Add the new layerouting.
    discomfortLocations = [];
    discomfortSections = [];
    final iconSize = MediaQuery.of(context).devicePixelRatio / 4;
    for (MapEntry<int, DiscomfortSegment> e in discomforts.foundDiscomforts?.asMap().entries ?? []) {
      if (e.value.coordinates.isEmpty) continue;
      if (e.value.coordinates.length == 1) {
        // A single location.
        final location = e.value.coordinates.first;
        discomfortLocations!.add(await mapController!.addSymbol(
          DiscomfortLocationMarker(geo: location, number: e.key + 1, iconSize: iconSize),
          e.value.toJson(),
        ));
      } else {
        // A section of the route.
        discomfortLocations!.add(await mapController!.addSymbol(
          DiscomfortLocationMarker(geo: e.value.coordinates.first, number: e.key + 1, iconSize: iconSize),
          e.value.toJson(),
        ));
        discomfortSections!.add(await mapController!.addLine(
          DiscomfortSectionLayer(points: e.value.coordinates),
          e.value.toJson(),
        ));
        // Make it easier to click the discomfort section layer.
        discomfortSections!.add(await mapController!.addLine(
          DiscomfortSectionClickLayer(points: e.value.coordinates),
          e.value.toJson(),
        ));
      }
    }
    // Remove the old layerouting.
    await mapController?.removeSymbols(oldDiscomfortLocations ?? []);
    await mapController?.removeLines(oldDiscomfortSections ?? []);
  }

  /// Load the current traffic lights.
  Future<void> loadTrafficLightMarkers() async {
    // If we have no map controller, we cannot load the traffic lights.
    if (mapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldTrafficLights = trafficLights;
    // Create a new traffic light marker for each traffic light.
    trafficLights = [];
    final settings = Provider.of<Settings>(context, listen: false);
    final willShowLabels = settings.sgLabelsMode == SGLabelsMode.enabled;
    // Check the prediction status of the traffic light.
    final statusProvider = Provider.of<PredictionSGStatus>(context, listen: false);
    final iconSize = MediaQuery.of(context).devicePixelRatio / 3;
    for (Sg sg in routing.selectedRoute?.signalGroups ?? []) {
      final status = statusProvider.cache[sg.id];
      if (status == null) {
        trafficLights!.add(await mapController!.addSymbol(
          OfflineMarker(
            iconSize: iconSize,
            geo: LatLng(sg.position.lat, sg.position.lon),
            label: willShowLabels ? sg.label : null,
          ),
        ));
      } else if (status.predictionState == SGPredictionState.offline) {
        trafficLights!.add(await mapController!.addSymbol(
          OfflineMarker(
            iconSize: iconSize,
            geo: LatLng(sg.position.lat, sg.position.lon),
            label: willShowLabels ? sg.label : null,
          ),
        ));
      } else if (status.predictionState == SGPredictionState.bad) {
        trafficLights!.add(await mapController!.addSymbol(
          BadSignalMarker(
            iconSize: iconSize,
            geo: LatLng(sg.position.lat, sg.position.lon),
            label: willShowLabels ? sg.label : null,
          ),
        ));
      } else {
        trafficLights!.add(await mapController!.addSymbol(
          OnlineMarker(
            iconSize: iconSize,
            geo: LatLng(sg.position.lat, sg.position.lon),
            label: willShowLabels ? sg.label : null,
          ),
        ));
      }
    }
    // Remove the old traffic lights.
    await mapController?.removeSymbols(oldTrafficLights ?? []);
  }

  /// Load the current crossings.
  Future<void> loadOfflineCrossingMarkers() async {
    // If we have no map controller, we cannot load the crossings.
    if (mapController == null) return;
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
      offlineCrossings!.add(await mapController!.addSymbol(
        DisconnectedMarker(
          iconSize: iconSize,
          geo: LatLng(crossing.position.lat, crossing.position.lon),
          label: willShowLabels ? crossing.name : null,
        ),
      ));
    }
    // Remove the old crossings.
    await mapController?.removeSymbols(oldCrossings ?? []);
  }

  /// Load the current waypoint markerouting.
  Future<void> loadWaypointMarkers() async {
    // If we have no map controller, we cannot load the waypoint layer.
    if (mapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldWaypoints = waypoints;
    waypoints = [];
    // Create a new waypoint marker for each waypoint.
    for (MapEntry<int, Waypoint> entry in routing.selectedWaypoints?.asMap().entries ?? []) {
      if (entry.key == 0) {
        waypoints!.add(await mapController!.addSymbol(
          StartMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      } else if (entry.key == routing.selectedWaypoints!.length - 1) {
        waypoints!.add(await mapController!.addSymbol(
          DestinationMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      } else {
        waypoints!.add(await mapController!.addSymbol(
          WaypointMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      }
    }
    // Remove the old waypoints.
    await mapController?.removeSymbols(oldWaypoints ?? []);
  }

  /// Adapt the map controller.
  Future<void> moveMap() async {
    if (mapController == null) return;
    if (routing.selectedRoute != null && !mapController!.isCameraMoving) {
      // The delay is necessary, otherwise sometimes the camera won't move.
      await Future.delayed(const Duration(milliseconds: 500));
      await mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(routing.selectedRoute!.paddedBounds),
        duration: const Duration(milliseconds: 1000),
      );
    }
  }

  /// Show the user location on the map.
  Future<void> showUserLocation() async {
    if (mapController == null) return;
    if (positioning.lastPosition == null) return;

    await mapController?.updateUserLocation(
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
    if (mapController == null) return;

    // Load the map features.
    geoFeatureLoader = GeoFeatureLoader(mapController!);
    await geoFeatureLoader!.removeFeatures();
    await geoFeatureLoader!.loadFeatures(context);
  }

  /// A callback that is called when the user taps a fill.
  Future<void> onFillTapped(Fill fill) async {/* Do nothing */}

  /// A callback that is called when the user taps a circle.
  Future<void> onCircleTapped(Circle circle) async {/* Do nothing */}

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
    mapController = controller;

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
    if (mapController == null) return;

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // Fit the content below the top and the bottom stuff.
    await mapController!.updateContentInsets(defaultMapInsets);

    // Allow overlaps so that important symbols and texts are not hidden.
    await mapController!.setSymbolIconAllowOverlap(true);
    await mapController!.setSymbolIconIgnorePlacement(true);
    await mapController!.setSymbolTextAllowOverlap(true);
    await mapController!.setSymbolTextIgnorePlacement(true);

    // Force adapt the map.
    await onRoutingUpdate();
    await onDiscomfortsUpdate();
    await onPositioningUpdate();
    await onLayersUpdate();
  }

  /// A callback that is executed when the map was longclicked.
  Future<void> onMapLongClick(BuildContext context, LatLng coord) async {
    final geocoding = Provider.of<Geocoding>(context, listen: false);
    String fallback = "Wegpunkt ${(routing.selectedWaypoints?.length ?? 0) + 1}";
    String address = await geocoding.reverseGeocode(context, coord) ?? fallback;
    await routing.addWaypoint(Waypoint(coord.latitude, coord.longitude, address: address));
    await routing.loadRoutes(context);
  }

  @override
  void dispose() {
    () async {
      // Remove geo features from the map.
      await geoFeatureLoader?.removeFeatures();

      // Remove all layers from the map.
      await mapController?.clearFills();
      await mapController?.clearCircles();
      await mapController?.clearLines();
      await mapController?.clearSymbols();

      // Unbind the sheet movement listener.
      await sheetMovementSubscription?.cancel();

      // Unbind the interaction callbacks.
      mapController?.onFillTapped.remove(onFillTapped);
      mapController?.onCircleTapped.remove(onCircleTapped);
      mapController?.onLineTapped.remove(onLineTapped);
      mapController?.onSymbolTapped.remove(onSymbolTapped);
      mapController?.dispose();
    }();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppMap(
      puckImage: Theme.of(context).brightness == Brightness.dark
          ? 'assets/images/position-static-dark.png'
          : 'assets/images/position-static-light.png',
      puckSize: 64,
      onMapCreated: onMapCreated,
      onStyleLoaded: () => onStyleLoaded(context),
      onMapLongClick: (_, coord) => onMapLongClick(context, coord),
    );
  }
}
