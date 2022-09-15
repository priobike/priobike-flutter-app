import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/layers.dart';
import 'package:priobike/common/map/markers.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routingNew/services/mapcontroller.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
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
  late RoutingService rs;

  /// The associated discomfort service, which is injected by the provider.
  late DiscomfortService ds;

  /// The associated settings service, which is injected by the provider.
  late SettingsService ss;

  /// The associated map controller service, which is injected by the provider.
  late MapControllerService ms;

  /// A map controller for the map.
  MapboxMapController? mapController;

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

  /// The current waypoints, if the route is selected.
  List<Symbol>? waypoints;

  /// Labels for the route and alt routes.
  List<Symbol>? labels;

  /// The stream that receives notifications when the bottom sheet is dragged.
  StreamSubscription<DraggableScrollableNotification>? sheetMovementSubscription;

  /// The default map insets.
  final defaultMapInsets = const EdgeInsets.only(
    top: 108, bottom: 80,
    left: 8, right: 8,
  );

  @override 
  void initState() {
    super.initState();
    sheetMovementSubscription = widget.sheetMovement?.listen(onScrollBottomSheet);
  }

  @override
  void didChangeDependencies() {
    rs = Provider.of<RoutingService>(context);
    ds = Provider.of<DiscomfortService>(context);
    ss = Provider.of<SettingsService>(context);
    ms = Provider.of<MapControllerService>(context);
    adaptMap();
    super.didChangeDependencies();
  }

  /// A callback that gets fired when the bottom sheet of the parent view is dragged.
  Future<void> onScrollBottomSheet(DraggableScrollableNotification n) async {
    final frame = MediaQuery.of(context);
    final maxBottomInset = frame.size.height - frame.padding.top - 300;
    final newBottomInset = min(maxBottomInset, n.extent * frame.size.height);
    mapController?.updateContentInsets(EdgeInsets.fromLTRB(
      defaultMapInsets.left, defaultMapInsets.top, defaultMapInsets.left, newBottomInset
    ), false);
  }

  Future<void> adaptMap() async {
    await loadAllRouteLayers();
    await loadSelectedRouteLayer();
    await loadDiscomforts();
    await loadTrafficLightMarkers();
    await loadWaypointMarkers();
    await moveMap();
  }

  /// Load the route layers.
  Future<void> loadAllRouteLayers() async {
    // If we have no map controller, we cannot load the layers.
    if (mapController == null) return;
    // Remove all existing layers.
    if (allRoutes != null) mapController!.removeLines(allRoutes!);
    // Add the new layers, if they exist.
    allRoutes = [];
    for (r.Route altRoute in rs.allRoutes ?? []) {
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
  }

  /// Load the current route layer.
  Future<void> loadSelectedRouteLayer() async {
    // If we have no map controller, we cannot load the route layer.
    if (mapController == null) return;
    // Remove the existing route layer.
    if (route != null) await mapController!.removeLine(route!);
    if (rs.selectedRoute == null) return;
    // Add the new route layer.
    route = await mapController!.addLine(
      RouteLayer(points: rs.selectedRoute!.route.map((e) => LatLng(e.lat, e.lon)).toList()),
      rs.selectedRoute!.toJson(),
    );
  }

  /// Load the discomforts.
  Future<void> loadDiscomforts() async {
    // If we have no map controller, we cannot load the layers.
    if (mapController == null) return;
    // Remove all existing layers.
    if (discomfortLocations != null) mapController!.removeSymbols(discomfortLocations!);
    if (discomfortSections != null) mapController!.removeLines(discomfortSections!);
    // Add the new layers.
    discomfortLocations = [];
    discomfortSections = [];
    final iconSize = MediaQuery.of(context).devicePixelRatio / 4;
    for (MapEntry<int, Discomfort> e in ds.foundDiscomforts?.asMap().entries ?? []) {
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
  }

  /// Load the current traffic lights.
  Future<void> loadTrafficLightMarkers() async {
    // If we have no map controller, we cannot load the traffic lights.
    if (mapController == null) return;
    // Remove all existing layers.
    if (trafficLights != null) mapController!.removeSymbols(trafficLights!);
    // Create a new traffic light marker for each traffic light.
    trafficLights = [];
    final willShowLabels = ss.sgLabelsMode == SGLabelsMode.enabled;
    for (Sg sg in rs.selectedRoute?.signalGroups.values ?? []) {
      trafficLights!.add(await mapController!.addSymbol(
        TrafficLightOffMarker(
          geo: LatLng(sg.position.lat, sg.position.lon),
          label: willShowLabels ? sg.label : null,
        ),
      ));
    }
  }

  /// Load the current waypoint markers.
  Future<void> loadWaypointMarkers() async {
    // If we have no map controller, we cannot load the waypoint layer.
    if (mapController == null) return;
    // Remove the existing waypoint markers.
    if (waypoints != null) await mapController!.removeSymbols(waypoints!);
    waypoints = [];
    // Create a new waypoint marker for each waypoint.
    for (MapEntry<int, Waypoint> entry in rs.selectedWaypoints?.asMap().entries ?? []) {
      if (entry.key == 0) {
        waypoints!.add(await mapController!.addSymbol(
          StartMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      } else if (entry.key == rs.selectedWaypoints!.length - 1) {
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
  }

  /// Adapt the map controller.
  Future<void> moveMap() async {
    if (mapController == null) return;
    if (rs.selectedRoute != null && !mapController!.isCameraMoving) {
      // The delay is necessary, otherwise sometimes the camera won't move.
      await Future.delayed(const Duration(milliseconds: 500));
      await mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(rs.selectedRoute!.paddedBounds)
      );
    }
  }

  /// A callback that is called when the user taps a fill.
  Future<void> onFillTapped(Fill fill) async { /* Do nothing */ }

  /// A callback that is called when the user taps a circle.
  Future<void> onCircleTapped(Circle circle) async { /* Do nothing */ }

  /// A callback that is called when the user taps a line.
  Future<void> onLineTapped(Line line) async {
    // If the line corresponds to a discomfort line, we select the discomfort.
    for (Line discomfortLine in discomfortSections ?? []) {
      if (line.id == discomfortLine.id) {
        final discomfort = Discomfort.fromJson(line.data);
        ds.selectDiscomfort(discomfort);
        return;
      }
    }
    // If the line corresponds to an alternative route, we select that one.
    for (Line routeLine in allRoutes ?? []) {
      if (line.id == routeLine.id) {
        final route = r.Route.fromJson(line.data);
        rs.switchToRoute(context, route);
        return;
      }
    }
  }

  /// A callback that is called when the user taps a symbol.
  Future<void> onSymbolTapped(Symbol symbol) async { 
    // If the symbol corresponds to a discomfort, we select that discomfort.
    for (Symbol discomfortLocation in discomfortLocations ?? []) {
      if (symbol.id == discomfortLocation.id) {
        final discomfort = Discomfort.fromJson(symbol.data);
        ds.selectDiscomfort(discomfort);
      }
    }
  }

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(MapboxMapController controller) async {
    mapController = controller;

    ms.setController(controller);

    // Bind the interaction callbacks.
    controller.onFillTapped.add(onFillTapped);
    controller.onCircleTapped.add(onCircleTapped);
    controller.onLineTapped.add(onLineTapped);
    controller.onSymbolTapped.add(onSymbolTapped);

    // Dont call any line/symbol/... removal/add operations here.
    // The mapcontroller won't have the necessary line/symbol/...manager.
  }

  void onCameraTrackingDismissed() {
    ms.setMyLocationTrackingModeNone();
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
    await adaptMap();
  }

  /// A callback that is executed when the map was longclicked.
  Future<void> onMapLongClick(BuildContext context, LatLng coord) async {
    final geocoding = Provider.of<GeocodingService>(context, listen: false);
    String fallback = "Wegpunkt ${(rs.selectedWaypoints?.length ?? 0) + 1}";
    String address = await geocoding.reverseGeocode(context, coord) ?? fallback;
    await rs.addWaypoint(Waypoint(coord.latitude, coord.longitude, address: address));
    await rs.loadRoutes(context);
  }

  @override
  void dispose() {
    // Unbind the sheet movement listener.
    sheetMovementSubscription?.cancel();

    // Unbind the interaction callbacks.
    mapController?.onFillTapped.remove(onFillTapped);
    mapController?.onCircleTapped.remove(onCircleTapped);
    mapController?.onLineTapped.remove(onLineTapped);
    mapController?.onSymbolTapped.remove(onSymbolTapped);

    ms.unsetController();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppMap(
      onMapCreated: onMapCreated, 
      onStyleLoaded: () => onStyleLoaded(context),
      onMapLongClick: (_, coord) => onMapLongClick(context, coord),
      onCameraTrackingDismissed: onCameraTrackingDismissed,
    );
  }
}
