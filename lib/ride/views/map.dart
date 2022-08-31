import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/common/map/layers.dart';
import 'package:priobike/common/map/markers.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/views/position.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:provider/provider.dart';

class RideMapView extends StatefulWidget {
  const RideMapView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideMapViewState();
}

class RideMapViewState extends State<RideMapView> {
  static const viewId = "ride.views.map";

  /// The associated routing service, which is injected by the provider.
  late RoutingService routingService;

  /// The associated positioning service, which is injected by the provider.
  late PositionService positionService;

  /// The associated ride service, which is injected by the provider.
  late RideService rideService;

  /// A map controller for the map.
  MapboxMapController? mapController;

  /// The route that is displayed, if a route is selected.
  Line? route;

  /// The route background that is displayed, if a route is selected.
  Line? routeBackground;

  /// The traffic lights that are displayed, if there are traffic lights on the route.
  List<Symbol>? trafficLights;

  /// The current waypoints, if the route is selected.
  List<Symbol>? waypoints;

  /// The next traffic light that is displayed, if it is known.
  Symbol? upcomingTrafficLight;

  @override
  void didChangeDependencies() {
    routingService = Provider.of<RoutingService>(context);
    if (routingService.needsLayout[viewId] != false && mapController != null) {
      onRoutingServiceUpdate(routingService);
      routingService.needsLayout[viewId] = false;
    }

    positionService = Provider.of<PositionService>(context);
    if (positionService.needsLayout[viewId] != false && mapController != null) {
      onPositionServiceUpdate(positionService);
      positionService.needsLayout[viewId] = false;
    }

    rideService = Provider.of<RideService>(context);
    if (rideService.needsLayout[viewId] != false && mapController != null) {
      onRideServiceUpdate(rideService);
      rideService.needsLayout[viewId] = false;
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

  /// Update the view with the current data.
  Future<void> onRideServiceUpdate(RideService rs) async {
    await loadNextTrafficLightLayer(rs);
  }

  /// Load the current route layer.
  Future<void> loadRouteLayer(RoutingService s) async {
    // If we have no map controller, we cannot load the route layer.
    if (mapController == null) return;
    // Remove the existing route layer.
    if (route != null) await mapController!.removeLine(route!);
    if (routeBackground != null) await mapController!.removeLine(routeBackground!);
    if (s.selectedRoute == null) return;
    // Add the new route layer.
    routeBackground = await mapController!.addLine(
      RouteBackgroundLayer(
        points: s.selectedRoute!.route.map((e) => LatLng(e.lat, e.lon)).toList(), 
        lineWidth: 20,
      ),
      s.selectedRoute!.toJson(),
    );
    route = await mapController!.addLine(
      RouteLayer(
        points: s.selectedRoute!.route.map((e) => LatLng(e.lat, e.lon)).toList(), 
        lineWidth: 14
      ),
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
    for (Sg sg in s.selectedRoute?.signalGroups.values ?? []) {
      trafficLights!.add(await mapController!.addSymbol(
        TrafficLightOffMarker(geo: LatLng(sg.position.lat, sg.position.lon), iconSize: 2.5),
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
    if (mapController == null) return;
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

  /// Load the upcoming traffic light layer.
  Future<void> loadNextTrafficLightLayer(RideService rs) async {
    if (mapController == null) return;

    // Cache the already displayed one to remove it after we have drawn on top.
    final currentTrafficLight = upcomingTrafficLight;

    final r = rs.currentRecommendation;
    if (r != null && !r.error && r.sgPos != null) {
      if (r.isGreen) {
        upcomingTrafficLight = await mapController!.addSymbol(
          TrafficLightGreenMarker(
            geo: LatLng(r.sgPos!.lat, r.sgPos!.lon), 
            iconSize: 2.5,
            countdown: r.countdown,
          ),
        );
      } else {
        upcomingTrafficLight = await mapController!.addSymbol(
          TrafficLightRedMarker(
            geo: LatLng(r.sgPos!.lat, r.sgPos!.lon), 
            iconSize: 2.5,
            countdown: r.countdown,
          ),
        );
      }
    }

    if (currentTrafficLight != null) await mapController!.removeSymbol(currentTrafficLight);
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

    // Dont call any line/symbol/... removal/add operations here.
    // The mapcontroller won't have the necessary line/symbol/...manager.
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(BuildContext context) async {
    if (mapController == null) return;

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    await mapController!.updateContentInsets(const EdgeInsets.only(bottom: 0));

    // Allow overlaps so that important symbols and texts are not hidden.
    await mapController!.setSymbolIconAllowOverlap(true);
    await mapController!.setSymbolIconIgnorePlacement(true);
    await mapController!.setSymbolTextAllowOverlap(true);
    await mapController!.setSymbolTextIgnorePlacement(true);

    onRoutingServiceUpdate(routingService);
    onPositionServiceUpdate(positionService);
    onRideServiceUpdate(rideService);
  }

  @override
  void dispose() {
    // Remove all layers from the map.
    route = null;
    routeBackground = null;
    trafficLights = null;
    waypoints = null;
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
        AppMap(
          dragEnabled: false,
          onMapCreated: onMapCreated, 
          onStyleLoaded: () => onStyleLoaded(context),
        ),
        Padding(padding: const EdgeInsets.only(bottom: 0), child: PositionIcon()),
      ]
    );
  }
}
