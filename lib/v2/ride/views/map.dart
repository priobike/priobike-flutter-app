import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/v2/common/debug.dart';
import 'package:priobike/v2/common/map/view.dart';
import 'package:priobike/v2/common/map/layers.dart';
import 'package:priobike/v2/common/map/markers.dart';
import 'package:priobike/v2/ride/services/mock.dart';
import 'package:priobike/v2/ride/services/positioning.dart';
import 'package:priobike/v2/ride/views/position.dart';
import 'package:priobike/v2/routing/services/mock.dart';
import 'package:priobike/v2/routing/services/routing.dart';
import 'package:priobike/v2/routing/models/waypoint.dart';
import 'package:provider/provider.dart';

void main() => debug(MultiProvider(
  providers: [
    ChangeNotifierProvider<RoutingService>(
      create: (context) => MockRoutingService(),
    ),
    ChangeNotifierProvider<PositionService>(
      create: (context) => StaticMockPositionService(
        position: const LatLng(53.564292, 9.902202), 
        heading: 140,
      ),
    ),
  ],
  child: const RideMapView(),
));

class RideMapView extends StatefulWidget {
  const RideMapView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideMapViewState();
}

class RideMapViewState extends State<RideMapView> {
  /// The associated routing service, which is injected by the provider.
  late RoutingService rs;

  /// The associated positioning service, which is injected by the provider.
  late PositionService ps;

  /// A map controller for the map.
  MapboxMapController? mapController;

  /// The route that is displayed, if a route is selected.
  Line? route;

  /// The traffic lights that are displayed, if there are traffic lights on the route.
  List<Symbol>? trafficLights;

  /// The current waypoints, if the route is selected.
  List<Symbol>? waypoints;

  @override
  void didChangeDependencies() {
    rs = Provider.of<RoutingService>(context);
    if (rs.needsLayout && mapController != null) {
      onRoutingServiceUpdate(rs);
      rs.needsLayout = false;
    }

    ps = Provider.of<PositionService>(context);
    if (!ps.isGeolocating) { ps.startGeolocation(); }
    if (ps.needsLayout && mapController != null) {
      onPositionServiceUpdate(ps);
      ps.needsLayout = false;
    }

    super.didChangeDependencies();
  }

  /// Update the view with the current data.
  Future<void> onRoutingServiceUpdate(RoutingService rs) async {
    await loadRouteLayer(rs);
    await loadTrafficLightMarkers(rs);
    await loadWaypointMarkers(rs);
  }

  /// Update the view with the current data.
  Future<void> onPositionServiceUpdate(PositionService ps) async {
    await adaptMapController(ps);
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
      RouteLayer(points: s.selectedRoute!.coordinates, lineWidth: 14),
      s.selectedRoute!.toJson(),
    );
  }

  /// Load the current traffic lights.
  Future<void> loadTrafficLightMarkers(RoutingService s) async {
    // If we have no map controller, we cannot load the traffic lights.
    if (mapController == null) return;
    // Remove all existing layers.
    await mapController!.removeSymbols(trafficLights ?? []);
    // Create a new traffic light marker for each traffic light.
    trafficLights = [];
    for (LatLng point in s.selectedRoute?.trafficLights ?? []) {
      trafficLights!.add(await mapController!.addSymbol(
        TrafficLightMarker(geo: point, iconSize: 1.5),
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
  Future<void> adaptMapController(PositionService s) async {
    if (mapController == null ) return;
    // await mapController!.updateMyLocationTrackingMode(MyLocationTrackingMode.TrackingGPS);
    await mapController!.moveCamera(CameraUpdate.tiltTo(60));
    await mapController!.moveCamera(CameraUpdate.newLatLngZoom(
      s.estimatedPosition != null
        ? LatLng(s.estimatedPosition!.latitude, s.estimatedPosition!.longitude)
        : const LatLng(0, 0),
      19,
    ));
    await mapController!.animateCamera(CameraUpdate.bearingTo(
      s.estimatedPosition != null ? s.estimatedPosition!.heading : 0
    ));
  }

  /// A callback that is called when the user taps a fill.
  Future<void> onFillTapped(Fill fill) async { /* Do nothing */ }

  /// A callback that is called when the user taps a circle.
  Future<void> onCircleTapped(Circle circle) async { /* Do nothing */ }

  /// A callback that is called when the user taps a line.
  Future<void> onLineTapped(Line line) async { /* Do nothing */}

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

    await mapController!.updateContentInsets(const EdgeInsets.all(0));

    // Force adapt the map controller.
    adaptMapController(ps);
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
    return Stack(
      alignment: Alignment.center,
      children: [
        AppMap(onMapCreated: onMapCreated, onStyleLoaded: () => onStyleLoaded(context)),
        PositionIcon(),
      ]
    );
  }
}
