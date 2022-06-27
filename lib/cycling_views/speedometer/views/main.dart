import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/services/app.dart';
import 'package:provider/provider.dart';

import 'buttons.dart';
import 'gauge.dart';
import 'position.dart';

import '../viewmodels/common.dart';
import '../viewmodels/markers.dart';
import '../viewmodels/layers.dart';

class SpeedometerView extends StatefulWidget {
  const SpeedometerView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SpeedometerViewState();
}

class _SpeedometerViewState extends State<SpeedometerView> {
  /// The minimum displayed speed.
  static const minSpeed = 0.0;

  /// The maximum displayed speed.
  static const maxSpeed = 40.0;

  /// The default gauge colors for the speedometer.
  static const defaultGaugeColors = [Colors.grey];

  /// A map controller for the map.
  MapboxMapController? mapController;

  /// A lock for concurrent updates to the map.
  var mapIsUpdating = false;

  /// The  route that is displayed, if a route is selected.
  MapElement<List<LatLng>, Line>? route;

  /// The traffic lights that are displayed, if there are traffic lights on the route.
  List<MapElement<LatLng, Symbol>>? trafficLights;

  /// The current waypoints, if the route is selected.
  List<MapElement<LatLng, Symbol>>? waypoints;

  /// The current gauge colors, if we have the necessary data.
  List<Color> gaugeColors = defaultGaugeColors;

  /// The current gauge stops, if we have the necessary data.
  List<double> gaugeStops = [];

  /// The associated app service, which is injected by the provider.
  late AppService app;

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);
    updateView(app);
    super.didChangeDependencies();
  }

  /// Update the view with the current data.
  Future<void> updateView(AppService s) async {
    loadRouteLayer(app);
    loadTrafficLightMarkers(app);
    loadWaypointMarkers(app);
    loadGauge(app);
    adaptMapController(app);
  }

  /// Load the current route layer.
  Future<void> loadRouteLayer(AppService s) async {
    // If we have no map controller, we cannot load the route layer.
    if (mapController == null) return;
    if (route != null) return;

    // Unwrap the points from the route response.
    var newRoutePoints = s.currentRoute?.route.map((p) => LatLng(p.lat, p.lon)).toList();
    if (newRoutePoints == null) return;
    route = MapElement(newRoutePoints, await mapController!.addLine(RouteLayer(points: newRoutePoints)));
  }

  /// Load the current traffic lights.
  Future<void> loadTrafficLightMarkers(AppService s) async {
    // If we have no map controller, we cannot load the traffic lights.
    if (mapController == null) return;
    if (trafficLights != null) return;

    // Unwrap the points from the traffic lights response.
    var newTrafficLightPoints = s.currentRoute?.signalgroups.values
      .map((sg) => LatLng(sg.position.lat, sg.position.lon)).toList();
    if (newTrafficLightPoints == null) return;
    trafficLights = []; 
    // Create a new traffic light marker for each traffic light.
    for (var point in newTrafficLightPoints) {
      var marker = await mapController!.addSymbol(TrafficLightMarker(geo: point));
      trafficLights!.add(MapElement(point, marker));
    }
  }

  /// Load the current waypoint markers.
  Future<void> loadWaypointMarkers(AppService s) async {
    // If we have no map controller, we cannot load the waypoint layer.
    if (mapController == null) return;
    if (waypoints != null) return;

    // Unwrap the waypoints from the routing response.
    List<LatLng>? newWaypoints;
    var route = s.currentRoute?.route;
    if (route != null) newWaypoints = [LatLng(route.first.lat, route.first.lon), LatLng(route.last.lat, route.last.lon)];
    if (newWaypoints == null) return;

    // If the waypoints are the same as the current waypoints, we don't need to update them.
    if (waypoints?.map((e) => e.data).toList() == newWaypoints) return;
    waypoints = [];
    // Create a new waypoint marker for each waypoint.
    for (var entry in newWaypoints.asMap().entries) {
      if (entry.key == 0) {
        var startMarker = await mapController!.addSymbol(StartMarker(
          geo: entry.value,
        ));
        waypoints!.add(MapElement(entry.value, startMarker));
      } else if (entry.key == newWaypoints.length - 1) {
        var endMarker = await mapController!.addSymbol(DestinationMarker(
          geo: entry.value,
        ));
        waypoints!.add(MapElement(entry.value, endMarker));
      } else {
        var inbetweenMarker = await mapController!.addSymbol(SymbolOptions(
          geometry: entry.value,
        ));
        waypoints!.add(MapElement(entry.value, inbetweenMarker));
      }
    }
  }

  /// Load the gauge colors and steps.
  Future<void> loadGauge(AppService s) async {
    // Check if we have the necessary position data
    var posTime = app.estimatedPosition?.timestamp;
    var posSpeed = app.estimatedPosition?.speed;
    var posLat = app.estimatedPosition?.latitude;
    var posLon = app.estimatedPosition?.longitude;
    var timeStr = app.currentRecommendation?.predictionStartTime;
    var tGreen = app.currentRecommendation?.predictionGreentimeThreshold;
    var phases = app.currentRecommendation?.predictionValue;
    var dist = app.currentRecommendation?.distance;

    // Check if we have all necessary data to display the speedometer
    if (posTime == null || posSpeed == null || posLat == null || posLon == null || 
        timeStr == null || tGreen == null || phases == null || dist == null) {
      gaugeColors = [Colors.grey];
      gaugeStops = [];
      return;
    }

    // Make more sanity checks
    if (posSpeed < 0) posSpeed = 0.0;

    // Chop off [UTC] from the end of the string
    if (timeStr.endsWith('[UTC]')) timeStr = timeStr.substring(0, timeStr.length - 5);
    var time = DateTime.tryParse(timeStr);
    if (time == null) {
      gaugeColors = [Colors.grey];
      gaugeStops = [];
      return;
    }

    // Calculate the elapsed seconds since the prediction and adjust the prediction accordingly
    var diff = DateTime.now().difference(time).inSeconds;
    if (diff > phases.length) {
      diff = phases.length;
    }
    var phasesFromNow = phases.sublist(diff);

    // Compute the max and min value for color interpolation
    int maxValue = 100;
    int minValue = 0;
    if (phasesFromNow.isNotEmpty) {
      maxValue = phasesFromNow.reduce(max);
      minValue = phasesFromNow.reduce(min);
    }

    // Map each second from now to the corresponding predicted signal color
    var colors = phasesFromNow.map((phase) {
      if (phase >= tGreen) {
        // Map green values between the greentimeThreshold and the maxValue
        var factor = (phase - tGreen) / (maxValue - tGreen);
        return Color.lerp(const Color.fromARGB(255, 243, 255, 18), const Color.fromARGB(255, 0, 255, 106), factor)!;
      } else {
        // Map red values between the minValue and the greentimeThreshold
        var factor = (phase - minValue) / (tGreen - minValue);
        return Color.lerp(const Color.fromARGB(255, 243, 60, 39), const Color.fromARGB(255, 243, 255, 18), factor)!;
      }
    }).toList();

    // Since we want the color steps not by second, but by speed, we map the stops accordingly
    var stops = Iterable<double>.generate(colors.length, (second) {
      if (second == 0) {
        return double.infinity;
      }
      // Map the second to the needed speed
      var speedKmh = (dist / second) * 3.6;
      // Scale the speed between minSpeed and maxSpeed
      return (speedKmh - minSpeed) / (maxSpeed - minSpeed);
    }).toList();

    // Add stops and colos to indicate unavailable prediction ranges
    if (stops.isNotEmpty) {
      stops.add(stops.last);
      stops.add(0.0);
    }
    if (colors.isNotEmpty) {
      colors.add(const Color.fromARGB(255, 189, 195, 199));
      colors.add(const Color.fromARGB(255, 189, 195, 199));
    }

    // Duplicate each color and stop to create "hard edges" instead of a gradient between steps
    // Such that green 0.1, red 0.3 -> green 0.1, green 0.3, red 0.3
    List<Color> hardEdgeColors = [];
    List<double> hardEdgeStops = [];
    for (var i = 0; i < colors.length; i++) {
      hardEdgeColors.add(colors[i]);
      hardEdgeStops.add(stops[i]);
      if (i + 1 < colors.length) {
        hardEdgeColors.add(colors[i]);
        hardEdgeStops.add(stops[i + 1]);
      }
    }

    // The resulting stops and colors will be from high speed -> low speed
    // Thus, we reverse both colors and stops to get the correct order
    gaugeColors = hardEdgeColors.reversed.toList();
    gaugeStops = hardEdgeStops.reversed.toList();
  }

  /// Adapt the map controller.
  Future<void> adaptMapController(AppService s) async {
    await mapController?.moveCamera(CameraUpdate.tiltTo(60));
    await mapController?.moveCamera(CameraUpdate.newLatLngZoom(
      app.estimatedPosition != null
        ? LatLng(app.estimatedPosition!.latitude, app.estimatedPosition!.longitude)
        : const LatLng(0, 0),
      19,
    ));
    await mapController?.animateCamera(CameraUpdate.bearingTo(
      app.estimatedPosition != null
        ? app.estimatedPosition!.heading
        : 0
    ));
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
  }

  @override
  Widget build(BuildContext context) {
    app = Provider.of<AppService>(context);

    var gauge = Positioned(
      child: Column(
        // Bottom to top
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            child: SpeedometerRadialGauge(
              colors: gaugeColors,
              stops: gaugeStops,
              minSpeed: minSpeed,
              maxSpeed: maxSpeed,
              speedKmh: (app.estimatedPosition?.speed ?? 0) * 3.6,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 44, 62, 80).withOpacity(1),
                  spreadRadius: 4,
                  blurRadius: 0,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: const Color.fromARGB(255, 52, 73, 94).withOpacity(0.1),
                  spreadRadius: 32,
                  blurRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
        ],
      ),
      top: (MediaQuery.of(context).size.height / 2 + 72)
    );

    var map = MapboxMap(
      accessToken: "pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA",
      onMapCreated: onMapCreated,
      onStyleLoadedCallback: onStyleLoaded,
      attributionButtonPosition: AttributionButtonPosition.TopLeft,
      logoViewMargins: Point(38, (MediaQuery.of(context).size.height) - 109),
      initialCameraPosition: const CameraPosition(
        target: LatLng(53.551086, 9.993682), // Hamburg
        tilt: 0,
        zoom: 16
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        map,
        PositionIcon(),
        gauge,
        const Positioned(
          child: CancelButton(),
          bottom: 4
        ),
      ]
    );
  }
}
