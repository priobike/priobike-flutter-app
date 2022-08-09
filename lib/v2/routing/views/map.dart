
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/v2/common/map/data.dart';
import 'package:priobike/v2/common/map/layers.dart';
import 'package:priobike/v2/common/map/markers.dart';
import 'package:priobike/v2/common/map/view.dart';
import 'package:priobike/v2/routing/services/routing.dart';
import 'package:provider/provider.dart';

class RoutingMapView extends StatefulWidget {
  const RoutingMapView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> {
  /// The associated routing service, which is injected by the provider.
  late RoutingService s;

  /// A map controller for the map.
  MapboxMapController? mapController;

  /// The alt routes that are displayed, if they were fetched.
  List<MapElement<List<LatLng>, Line>>? altRoutes;

  /// The  route that is displayed, if a route is selected.
  MapElement<List<LatLng>, Line>? route;

  /// The discomfort sections that are displayed, if they were fetched.
  List<MapElement<List<LatLng>, Line>>? discomfortSections;

  /// The discomfort locations that are displayed, if they were fetched.
  List<MapElement<LatLng, Symbol>>? discomfortLocations;

  /// The traffic lights that are displayed, if there are traffic lights on the route.
  List<MapElement<LatLng, Symbol>>? trafficLights;

  /// The current waypoints, if the route is selected.
  List<MapElement<LatLng, Symbol>>? waypoints;

  @override
  void didChangeDependencies() {
    s = Provider.of<RoutingService>(context);

    loadAltRouteLayers(s);
    loadRouteLayer(s);
    loadDiscomforts(s);
    loadTrafficLightMarkers(s);
    loadWaypointMarkers(s);
    adaptMapController(s);

    super.didChangeDependencies();
  }

  /// Load the current route layer.
  Future<void> loadRouteLayer(RoutingService s) async {
    // If we have no map controller, we cannot load the route layer.
    if (mapController == null) return;
    if (route != null) return; // TODO: Remove if changeable

    // Unwrap the points from the route response.
    var newRoutePoints = s.selectedRoute?.coordinates;
    if (newRoutePoints == null) return;
    route = MapElement(newRoutePoints, await mapController!.addLine(RouteLayer(points: newRoutePoints)));
  }

  /// Load the discomforts.
  Future<void> loadDiscomforts(RoutingService s) async {
    // If we have no map controller, we cannot load the layers.
    if (mapController == null) return;
    if (discomfortLocations != null) return; // TODO: Remove if changeable
    if (discomfortSections != null) return; // TODO: Remove if changeable

    List<List<LatLng>>? newDiscomforts = s.selectedRoute?.discomforts?.map((e) => e.coordinates).toList();
    if (newDiscomforts == null) return;

    discomfortSections = [];
    discomfortLocations = [];
    for (var discomfort in newDiscomforts) {
      if (discomfort.isEmpty) continue;
      if (discomfort.length == 1) {
        final location =  discomfort[0];
        var marker = await mapController!.addSymbol(DiscomfortLocationMarker(geo: location));
        discomfortLocations!.add(MapElement(location, marker));
      } else {
        var line = await mapController!.addLine(DiscomfortSectionLayer(points: discomfort));
        discomfortSections!.add(MapElement(discomfort, line));
      }
    }
  }

  /// Load the current traffic lights.
  Future<void> loadTrafficLightMarkers(RoutingService s) async {
    // If we have no map controller, we cannot load the traffic lights.
    if (mapController == null) return;
    if (trafficLights != null) return; // TODO: Remove if changeable

    // Unwrap the points from the traffic lights response.
    var newTrafficLightPoints = s.selectedRoute?.trafficLights;
    if (newTrafficLightPoints == null) return;
    trafficLights = []; 
    // Create a new traffic light marker for each traffic light.
    for (var point in newTrafficLightPoints) {
      var marker = await mapController!.addSymbol(TrafficLightMarker(geo: point));
      trafficLights!.add(MapElement(point, marker));
    }
  }

  /// Load the current waypoint markers.
  Future<void> loadWaypointMarkers(RoutingService s) async {
    // If we have no map controller, we cannot load the waypoint layer.
    if (mapController == null) return;
    if (waypoints != null) return; // TODO: Remove if changeable

    // Unwrap the waypoints from the routing response.
    List<LatLng>? newWaypoints = s.fetchedWaypoints?.map((e) => LatLng(e.lat, e.lon)).toList();
    if (newWaypoints == null) return;

    // If the waypoints are the same as the current waypoints, we don't need to update them.
    if (waypoints?.map((e) => e.data).toList() == newWaypoints) return;
    waypoints = [];
    // Create a new waypoint marker for each waypoint.
    for (var entry in newWaypoints.asMap().entries) {
      if (entry.key == 0) {
        var startMarker = await mapController!.addSymbol(StartMarker(geo: entry.value));
        waypoints!.add(MapElement(entry.value, startMarker));
      } else if (entry.key == newWaypoints.length - 1) {
        var endMarker = await mapController!.addSymbol(DestinationMarker(geo: entry.value));
        waypoints!.add(MapElement(entry.value, endMarker));
      } else {
        var inbetweenMarker = await mapController!.addSymbol(SymbolOptions(geometry: entry.value));
        waypoints!.add(MapElement(entry.value, inbetweenMarker));
      }
    }
  }

  /// Load the alt route layers.
  Future<void> loadAltRouteLayers(RoutingService s) async {
    // If we have no map controller, we cannot load the layers.
    if (mapController == null) return;
    if (altRoutes != null) return; // TODO: Remove if changeable

    List<List<LatLng>>? newAltRoutes = s.altRoutes?.map((e) => e.coordinates).toList();
    if (newAltRoutes == null) return;

    altRoutes = [];
    for (var altRoute in newAltRoutes) {
      altRoutes!.add(MapElement(altRoute, await mapController!.addLine(AltRouteLayer(points: altRoute))));
    }
  }

  /// Adapt the map controller.
  Future<void> adaptMapController(RoutingService s) async {
    if (s.selectedRoute != null) {
      await mapController?.moveCamera(CameraUpdate.newLatLngBounds(s.selectedRoute!.paddedBounds));
    }
  }

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(MapboxMapController controller) async {
    mapController = controller;
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(MediaQueryData frame) async {
    if (mapController == null) return;
    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // Fit the content below the top and the bottom stuff.
    await mapController!.updateContentInsets(EdgeInsets.only(
      top: 164, bottom: frame.size.height * 0.3,
      left: 8, right: 8,
    ));

    // Force adapt the map controller.
    adaptMapController(s);
  }

  @override
  Widget build(BuildContext context) {
    s = Provider.of<RoutingService>(context);
    final frame = MediaQuery.of(context);
    return AppMap(onMapCreated: onMapCreated, onStyleLoaded: () => onStyleLoaded(frame));
  }
}
