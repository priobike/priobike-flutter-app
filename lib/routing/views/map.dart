import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/layers.dart';
import 'package:priobike/common/map/markers.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:provider/provider.dart';

class RoutingMapView extends StatefulWidget {
  const RoutingMapView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> {
  static const viewId = "routing.views.map";

  /// The associated routing service, which is injected by the provider.
  late RoutingService s;

  /// A map controller for the map.
  MapboxMapController? mapController;

  /// The alt routes that are displayed, if they were fetched.
  List<Line>? altRoutes;

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

  @override
  void didChangeDependencies() {
    s = Provider.of<RoutingService>(context);
    if (s.needsLayout[viewId] != false && mapController != null) {
      adaptMap(s);
      s.needsLayout[viewId] = false;
    }
    super.didChangeDependencies();
  }

  Future<void> adaptMap(RoutingService s) async {
    await loadAltRouteLayers(s);
    await loadRouteLayer(s);
    await loadDiscomforts(s);
    await loadTrafficLightMarkers(s);
    await loadWaypointMarkers(s);
    await adaptMapController(s);
  }

  /// Load the alt route layers.
  Future<void> loadAltRouteLayers(RoutingService s) async {
    // If we have no map controller, we cannot load the layers.
    if (mapController == null) return;
    // Remove all existing layers.
    await mapController!.removeLines(altRoutes ?? []);
    // Add the new layers, if they exist.
    altRoutes = [];
    for (r.Route altRoute in s.altRoutes ?? []) {
      altRoutes!.add(await mapController!.addLine(
        AltRouteLayer(points: altRoute.nodes.map((e) => LatLng(e.lat, e.lon)).toList()),
        altRoute.toJson(),
      ));
      altRoutes!.add(await mapController!.addLine(
        AltRouteClickLayer(points: altRoute.nodes.map((e) => LatLng(e.lat, e.lon)).toList()),
        altRoute.toJson(),
      ));
    }
  }

  /// Load the current route layer.
  Future<void> loadRouteLayer(RoutingService s) async {
    // If we have no map controller, we cannot load the route layer.
    if (mapController == null) return;
    // Remove the existing route layer.
    if (route != null) await mapController!.removeLine(route!);
    if (s.selectedRoute == null) return;
    // Add the new route layer.
    route = await mapController!.addLine(
      RouteLayer(points: s.selectedRoute!.nodes.map((e) => LatLng(e.lat, e.lon)).toList()),
      s.selectedRoute!.toJson(),
    );
  }

  /// Load the discomforts.
  Future<void> loadDiscomforts(RoutingService s) async {
    // If we have no map controller, we cannot load the layers.
    if (mapController == null) return;
    // Remove all existing layers.
    await mapController!.removeSymbols(discomfortLocations ?? []);
    await mapController!.removeLines(discomfortSections ?? []);
    // Add the new layers.
    discomfortLocations = [];
    discomfortSections = [];
    for (MapEntry<int, Discomfort> e in s.selectedRoute?.discomforts?.asMap().entries ?? []) {
      if (e.value.coordinates.isEmpty) continue;
      if (e.value.coordinates.length == 1) {
        // A single location.
        final location = e.value.coordinates.first;
        discomfortLocations!.add(await mapController!.addSymbol(
          DiscomfortLocationMarker(geo: location, number: e.key + 1),
          e.value.toJson(),
        ));
      } else {
        // A section of the route.
        discomfortLocations!.add(await mapController!.addSymbol(
          DiscomfortLocationMarker(geo: e.value.coordinates.first, number: e.key + 1),
          e.value.toJson(),
        ));
        discomfortLocations!.add(await mapController!.addSymbol(
          DiscomfortLocationMarker(geo: e.value.coordinates.last, number: e.key + 1),
          e.value.toJson(),
        ));
        discomfortSections!.add(await mapController!.addLine(
          DiscomfortSectionLayer(points: e.value.coordinates),
          e.value.toJson(),
        ));        
      }
    }
  }

  /// Load the current traffic lights.
  Future<void> loadTrafficLightMarkers(RoutingService s) async {
    // If we have no map controller, we cannot load the traffic lights.
    if (mapController == null) return;
    // Remove all existing layers.
    await mapController!.removeSymbols(trafficLights ?? []);
    // Create a new traffic light marker for each traffic light.
    trafficLights = [];
    for (Sg sg in s.selectedRoute?.sgs ?? []) {
      trafficLights!.add(await mapController!.addSymbol(
        TrafficLightMarker(geo: LatLng(sg.position.lat, sg.position.lon)),
      ));
    }
  }

  /// Load the current waypoint markers.
  Future<void> loadWaypointMarkers(RoutingService s) async {
    // If we have no map controller, we cannot load the waypoint layer.
    if (mapController == null) return;
    // Remove the existing waypoint markers.
    await mapController!.removeSymbols(waypoints ?? []);
    waypoints = [];
    // Create a new waypoint marker for each waypoint.
    for (MapEntry<int, Waypoint> entry in s.selectedWaypoints?.asMap().entries ?? []) {
      if (entry.key == 0) {
        waypoints!.add(await mapController!.addSymbol(
          StartMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      } else if (entry.key == s.selectedWaypoints!.length - 1) {
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
  Future<void> adaptMapController(RoutingService s) async {
    if (s.selectedRoute != null) {
      await mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(s.selectedRoute!.paddedBounds)
      );
    }
  }

  /// A callback that is called when the user taps a fill.
  Future<void> onFillTapped(Fill fill) async { /* Do nothing */ }

  /// A callback that is called when the user taps a circle.
  Future<void> onCircleTapped(Circle circle) async { /* Do nothing */ }

  /// A callback that is called when the user taps a line.
  Future<void> onLineTapped(Line line) async {
    // If the line corresponds to an alternative route, we select that one.
    for (Line altRoute in altRoutes ?? []) {
      if (line.id == altRoute.id) {
        var route = r.Route.fromJson(line.data);
        s.switchToAltRoute(route);
      }
    }
  }

  /// A callback that is called when the user taps a symbol.
  Future<void> onSymbolTapped(Symbol symbol) async { /* Do nothing */ }

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(MapboxMapController controller) async {
    mapController = controller;

    // Bind the interaction callbacks.
    controller.onFillTapped.add(onFillTapped);
    controller.onCircleTapped.add(onCircleTapped);
    controller.onLineTapped.add(onLineTapped);
    controller.onSymbolTapped.add(onSymbolTapped);
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(BuildContext context) async {
    if (mapController == null) return;

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // Fit the content below the top and the bottom stuff.
    final frame = MediaQuery.of(context);
    await mapController!.updateContentInsets(EdgeInsets.only(
      top: 108, bottom: frame.size.height * 0.3 /* Sheet size */,
      left: 8, right: 8,
    ));

    // Force adapt the map controller.
    adaptMapController(s);
  }

  @override
  void dispose() {
    // Unbind the interaction callbacks.
    mapController?.onFillTapped.remove(onFillTapped);
    mapController?.onCircleTapped.remove(onCircleTapped);
    mapController?.onLineTapped.remove(onLineTapped);
    mapController?.onSymbolTapped.remove(onSymbolTapped);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppMap(onMapCreated: onMapCreated, onStyleLoaded: () => onStyleLoaded(context));
  }
}
