import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:priobike/services/app.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

Color rgb(int r, int g, int b) => Color.fromARGB(255, r, g, b);

class SpeedometerView extends StatefulWidget {
  const SpeedometerView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SpeedometerViewState();
}

class _SpeedometerViewState extends State<SpeedometerView> {
  static const minSpeed = 0.0;
  static const maxSpeed = 40.0;

  var points = <LatLng>[];
  var trafficLights = <Marker>[];

  late AppService app;

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);

    if (app.currentRoute != null && !app.loadingRoute) {
      points = [];
      trafficLights = [];

      for (var point in app.currentRoute!.route) {
        points.add(LatLng(point.lat, point.lon));
      }

      for (var sg in app.currentRoute!.signalgroups.values) {
        trafficLights.add(
          Marker(
            point: LatLng(sg.position.lat, sg.position.lon),
            builder: (ctx) => Container(
              child: Icon(
                Icons.traffic,
                color: rgb(236, 240, 241),
                size: 30,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: rgb(44, 62, 80).withOpacity(1.0),
                    spreadRadius: 2,
                    blurRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    app = Provider.of<AppService>(context);

    // Unwrap the necessary data
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
      // TODO: Show only map and route
      return const Center(child: Text('Waiting for prediction data...'));
    }

    // Make more sanity checks
    if (posSpeed < 0) {
      posSpeed = 0;
    }

    // Chop off [UTC] from the end of the string
    if (timeStr.endsWith('[UTC]')) timeStr = timeStr.substring(0, timeStr.length - 5);
    var time = DateTime.tryParse(timeStr);
    if (time == null) {
      return const Center(child: Text('Ungültige Startzeit der Vorhersage'));
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
    var stops = Iterable<double>.generate(colors.length, (second) {
      if (second == 0) {
        return double.infinity;
      }
      // Map the second to the needed speed
      var speedKmh = (dist / second) * 3.6;
      // Scale the speed between minSpeed and maxSpeed
      return (speedKmh - minSpeed) / (maxSpeed - minSpeed);
    }).toList();
    
    if (stops.isNotEmpty) {
      stops.add(stops.last);
      stops.add(0.0);
    }
    if (colors.isNotEmpty) {
      colors.add(rgb(189, 195, 199));
      colors.add(rgb(189, 195, 199));
    }

    var range = GaugeRange(
      startValue: minSpeed,
      endValue: maxSpeed,
      sizeUnit: GaugeSizeUnit.factor,
      startWidth: 0.25,
      endWidth: 0.25,
      gradient: SweepGradient(
        colors: colors.reversed.toList(),
        stops: stops.reversed.toList(),
      )
    );

    var pointer = NeedlePointer(
      value: posSpeed * 3.6,
      needleLength: 0.875,
      enableAnimation: true,
      animationType: AnimationType.ease,
      needleStartWidth: 1,
      needleEndWidth: 8,
      needleColor: rgb(44, 62, 80),
      knobStyle: KnobStyle(knobRadius: 0.05, sizeUnit: GaugeSizeUnit.factor, color: rgb(44, 62, 80))
    );

    var gauge = SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: minSpeed, 
          maximum: maxSpeed, 
          startAngle: 165,
          endAngle: 15,
          interval: 5,
          minorTicksPerInterval: 4,
          showAxisLine: true,
          radiusFactor: 0.95,
          labelOffset: 15,
          axisLineStyle: const AxisLineStyle(thicknessUnit: GaugeSizeUnit.factor, thickness: 0.25),
          majorTickStyle: MajorTickStyle(length: 10, thickness: 4, color: rgb(44, 62, 80)),
          minorTickStyle: MinorTickStyle(length: 5, thickness: 1, color: rgb(52, 73, 94)),
          axisLabelStyle: GaugeTextStyle(color: rgb(44, 62, 80), fontWeight: FontWeight.bold, fontSize: 14),
          ranges: [range],
          pointers: [pointer],
        ),
      ]
    );

    var cancelButton = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        width: 164,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.stop),
          label: const Text('Fahrt Beenden'),
          onPressed: () {
            Navigator.pushReplacementNamed(context, Routes.summary);
          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: rgb(236, 240, 241))
              )
            ),
            foregroundColor: MaterialStateProperty.all<Color>(rgb(236, 240, 241)),
            backgroundColor: MaterialStateProperty.all<Color>(rgb(44, 62, 80)),
          )
        ),
      ),
    );

    var mapMarkers = MarkerLayerOptions(
      markers: [
        ...trafficLights,
        app.lastPosition != null
          ? Marker(
              point: LatLng(app.lastPosition!.latitude, app.lastPosition!.longitude),
              builder: (ctx) => Container(
                child: Icon(
                  Icons.location_pin,
                  color: rgb(236, 240, 241),
                  size: 30,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: rgb(231, 76, 60).withOpacity(1.0),
                      spreadRadius: 2,
                      blurRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            )
          : Marker(
              point: LatLng(0, 0),
              builder: (ctx) => Container()),
        Marker(
          point: points.first,
          builder: (ctx) => Icon(
            Icons.location_pin,
            color: rgb(44, 62, 80),
            size: 30,
          ),
        ),
        Marker(
          point: points.last,
          builder: (ctx) => Icon(
            Icons.flag,
            color: rgb(44, 62, 80),
            size: 30,
          ),
        ),
      ],
    );

    // ignore: prefer_function_declarations_over_variables
    var map = (constraints) => FlutterMap(
      options: MapOptions(
        bounds: LatLngBounds.fromPoints(points),
        boundsOptions: FitBoundsOptions(padding: EdgeInsets.only(bottom: (constraints.maxHeight * 0.5) - 24)),
        maxZoom: 20.0,
        minZoom: 7,
        interactiveFlags: InteractiveFlag.drag |
          InteractiveFlag.pinchZoom |
          InteractiveFlag.doubleTapZoom |
          InteractiveFlag.flingAnimation |
          InteractiveFlag.pinchMove,
      ),
      layers: [
        TileLayerOptions(
          // NOTE: In the future, we will use mapbox tiles
          urlTemplate: "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        PolylineLayerOptions(
          polylines: [
            Polyline(
              points: points,
              strokeWidth: 8.0,
              color: rgb(52, 152, 219),
            ),
          ],
        ),
        mapMarkers,
      ],
    );

    return LayoutBuilder(builder: (ctx, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tacho'),
        ),
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            map(constraints),
            Column(
              // Bottom to top
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  child: gauge,
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: rgb(44, 62, 80).withOpacity(1),
                        spreadRadius: 4,
                        blurRadius: 0,
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: rgb(52, 73, 94).withOpacity(0.1),
                        spreadRadius: 32,
                        blurRadius: 0,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  // Transform down by width/2
                  transform: Matrix4.translationValues(0.0, (0.5 * constraints.maxWidth) - 48, 0.0),
                ),
                cancelButton,
              ],
            ),
          ]
        ),
      );
    });
  }
}
