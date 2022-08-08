

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/v2/common/colors.dart';
import 'package:priobike/v2/common/debug.dart';
import 'package:priobike/v2/common/layout/buttons.dart';
import 'package:priobike/v2/common/layout/spacing.dart';
import 'package:priobike/v2/common/layout/text.dart';
import 'package:priobike/v2/common/map/data.dart';
import 'package:priobike/v2/common/map/layers.dart';
import 'package:priobike/v2/common/map/markers.dart';
import 'package:priobike/v2/common/map/view.dart';
import 'package:priobike/v2/routing/services/mock.dart';
import 'package:priobike/v2/routing/services/routing.dart';
import 'package:provider/provider.dart';

/// Debug these views.
void main() => debug(MultiProvider(
  providers: [
    ChangeNotifierProvider<RoutingService>(
      create: (context) => MockRoutingService(),
    ),
  ],
  child: const RoutingView(),
));

class RoutingView extends StatefulWidget {
  const RoutingView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RoutingViewState();
}

class _RoutingViewState extends State<RoutingView> {
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
    updateView(s);
    super.didChangeDependencies();

    // Load the routes, once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      s.loadRoutes();
    });
  }

  /// Update the view with the current data.
  Future<void> updateView(RoutingService s) async {
    loadAltRouteLayers(s);
    loadRouteLayer(s);
    loadDiscomforts(s);
    loadTrafficLightMarkers(s);
    loadWaypointMarkers(s);
    adaptMapController(s);
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
  Future<void> onStyleLoaded() async {
    if (mapController == null) return;
    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // Force adapt the map controller.
    adaptMapController(s);
  }

  @override
  Widget build(BuildContext context) {
    s = Provider.of<RoutingService>(context);
    final frame = MediaQuery.of(context);

    return Stack(children: [
      Container(
        height: frame.size.height * 0.8, 
        child: AppMap(onMapCreated: onMapCreated, onStyleLoaded: onStyleLoaded)
      ),
      renderBackButton(context),
      DraggableScrollableSheet(
        initialChildSize: 0.3,
        maxChildSize: 0.6,
        builder: (BuildContext context, ScrollController controller) {
          return renderBottomSheet(context, controller);
        },
      ),
    ]);
  }

  Widget renderBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64), 
      child: AppBackButton(icon: Icons.chevron_left_rounded, onPressed: () {}),
    );
  }

  Widget renderBottomSheet(BuildContext context, ScrollController controller) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(32.0)),
      ),
      child: ListView(controller: controller, padding: const EdgeInsets.all(8), children: [
        Column(children: [
          Container(
            alignment: AlignmentDirectional.center, 
            width: 32, height: 6,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
            ),
          )
        ]),
        const SmallVSpace(),
        renderBottomSheetWaypoints(context),
        const SmallVSpace(),
        BigButton(label: "Starten", onPressed: () {
          // TODO: Open ride view
        }),
      ]),
    );
  }

  Widget renderBottomSheetWaypoints(BuildContext context) {
    if (s.fetchedWaypoints == null) return Container();
    final frame = MediaQuery.of(context);
    return Stack(children: [
      Row( children: [
        const SizedBox(width: 12),
        Column(children: [
          const SizedBox(height: 8),
          Stack(alignment: AlignmentDirectional.center, children: [
            Container(color: const Color.fromARGB(255, 241, 241, 241), width: 16, height: s.fetchedWaypoints!.length * 32),
            Container(color: Colors.blueAccent, width: 8, height: s.fetchedWaypoints!.length * 32),
          ]),
        ]),
      ]),
      Column(children: s.fetchedWaypoints!.asMap().entries.map<Widget>((entry) {
        return Padding(
          padding: EdgeInsets.all(4), 
          child: Row(children: [
            if (entry.key == 0) const Image(
              image: AssetImage("assets/images/start.drawio.png"),
              width: 32,
              height: 32,
              color: null,
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
            ) else if (entry.key == (s.fetchedWaypoints!.length - 1)) const Image(
              image: AssetImage("assets/images/destination.drawio.png"),
              width: 32,
              height: 32,
              color: null,
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
            ) else const Image(
              image: AssetImage("assets/images/waypoint.drawio.png"),
              width: 32,
              height: 32,
              color: null,
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
            ),
            const SmallHSpace(),
            Container(
              height: 32, 
              width: frame.size.width - 64,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 241, 241, 241),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                const SmallHSpace(),
                BoldContent(text: entry.value.address),
              ]),
            ),
          ]),
        );
      }).toList()),
    ]);
  }
}
