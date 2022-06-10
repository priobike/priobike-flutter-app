import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:priobike/services/app.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'buttons.dart';
import 'gauge.dart';
import 'markers.dart';
import 'layers.dart';

class SpeedometerView extends StatefulWidget {
  const SpeedometerView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SpeedometerViewState();
}

class _SpeedometerViewState extends State<SpeedometerView> {
  static const minSpeed = 0.0;
  static const maxSpeed = 40.0;

  /// The route layer that is displayed, if a route is selected.
  RouteLayer? routeLayer;

  /// The traffic lights that are displayed, if there are traffic lights on the route.
  List<TrafficLightMarker>? trafficLightMarkers;

  /// The current position marker, if the user has a current position.
  CurrentPositionMarker? currentPositionMarker;

  /// The current waypoint markers, if the route is selected.
  List<Marker>? waypointMarkers;

  /// The current gauge colors, if we have the necessary data.
  List<Color> gaugeColors = [Colors.grey];

  /// The current gauge stops, if we have the necessary data.
  List<double> gaugeStops = [];

  /// The current map bounds, if we have the necessary data.
  LatLngBounds? mapBounds;

  late AppService app;

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);

    loadRouteLayer(app);
    loadTrafficLightMarkers(app);
    loadCurrentPositionMarker(app);
    loadWaypointMarkers(app);
    loadGauge(app);
    loadMapBounds(app);

    super.didChangeDependencies();
  }

  /// Load the current route layer.
  void loadRouteLayer(AppService s) {
    var routeResponse = s.currentRoute;
    if (routeResponse == null) {
      routeLayer = null;
      return;
    }
    var points = routeResponse.route.map((p) => LatLng(p.lat, p.lon)).toList();
    routeLayer = RouteLayer(points: points);
  }

  /// Load the current traffic lights.
  void loadTrafficLightMarkers(AppService s) {
    var routeResponse = s.currentRoute;
    if (routeResponse == null) {
      trafficLightMarkers = null;
      return;
    }
    trafficLightMarkers = routeResponse.signalgroups.values.map((sg) => TrafficLightMarker(
      lat: sg.position.lat,
      lon: sg.position.lon,
    )).toList();
  }

  /// Load the current position marker.
  void loadCurrentPositionMarker(AppService s) {
    var currentPosition = s.lastPosition;
    if (currentPosition == null) {
      currentPositionMarker = null;
      return;
    }
    currentPositionMarker = CurrentPositionMarker(
      lat: currentPosition.latitude,
      lon: currentPosition.longitude,
    );
  }

  /// Load the current waypoint markers.
  void loadWaypointMarkers(AppService s) {
    var routeResponse = s.currentRoute;
    if (routeResponse == null) {
      waypointMarkers = null;
      return;
    }   
    waypointMarkers = [
      StartMarker(lat: routeResponse.route.first.lat, lon: routeResponse.route.first.lon),
      DestinationMarker(lat: routeResponse.route.last.lat, lon: routeResponse.route.last.lon),
    ];
  }

  /// Load the gauge colors and steps.
  void loadGauge(AppService s) {
    // Check if we have the necessary position data
    var posTime = app.lastPosition?.timestamp;
    var posSpeed = app.lastPosition?.speed;
    var posLat = app.lastPosition?.latitude;
    var posLon = app.lastPosition?.longitude;
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
        return Color.lerp(Color.fromARGB(255, 243, 255, 18), Color.fromARGB(255, 0, 255, 106), factor)!;
      } else {
        // Map red values between the minValue and the greentimeThreshold
        var factor = (phase - minValue) / (tGreen - minValue);
        return Color.lerp(Color.fromARGB(255, 243, 60, 39), Color.fromARGB(255, 243, 255, 18), factor)!;
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

  /// Load the map bounds.
  void loadMapBounds(AppService s) {
    var routeResponse = s.currentRoute;
    if (routeResponse == null) {
      // Default bounds is Germany
      mapBounds = LatLngBounds(
        // Northeast
        LatLng(52.5, 13.0),
        // Southwest
        LatLng(47.0, 5.0),
      );
      return;
    }
    var points = routeResponse.route.map((p) => LatLng(p.lat, p.lon)).toList();
    mapBounds =  LatLngBounds.fromPoints(points);
  }

  @override
  Widget build(BuildContext context) {
    app = Provider.of<AppService>(context);

    // ignore: prefer_function_declarations_over_variables
    var gauge = (screen) => Column(
      // Bottom to top
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Container(
          child: SpeedometerRadialGauge(
            colors: gaugeColors,
            stops: gaugeStops,
            minSpeed: minSpeed,
            maxSpeed: maxSpeed,
            speedKmh: (app.lastPosition?.speed ?? 0) * 3.6,
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
          // Transform down by width/2
          transform: Matrix4.translationValues(0.0, (0.5 * screen.maxWidth) - 48, 0.0),
        ),
        const CancelButton(),
      ],
    );
    
    // ignore: prefer_function_declarations_over_variables
    var map = (screen) => FlutterMap(
      options: MapOptions(
        bounds: mapBounds,
        boundsOptions: FitBoundsOptions(padding: EdgeInsets.only(bottom: (screen.maxHeight * 0.5) - 24)),
        maxZoom: 20.0,
        minZoom: 7,
        interactiveFlags: InteractiveFlag.drag |
          InteractiveFlag.pinchZoom |
          InteractiveFlag.doubleTapZoom |
          InteractiveFlag.flingAnimation |
          InteractiveFlag.pinchMove,
      ),
      layers: [
        // The base map
        PositronMapLayer(),
        // The route above the map
        if (routeLayer != null) routeLayer!,
        // All markers above the route
        MarkerLayerOptions(
          markers: [
            if (trafficLightMarkers != null) ...trafficLightMarkers!,
            if (waypointMarkers != null) ...waypointMarkers!,
            if (currentPositionMarker != null) currentPositionMarker!,
          ],
        ),
      ],
    );

    return LayoutBuilder(builder: (ctx, screenConstraints) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            map(screenConstraints),
            gauge(screenConstraints),
          ]
        ),
      );
    });
  }
}
