import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/session/services/session.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/recommendation/recommendation.dart';
import 'package:provider/provider.dart';

/// A cancel button to cancel the ride.
class CancelButton extends StatelessWidget {
  /// A callback that is fired when the cancel button is touched.
  final void Function() onTap;

  /// Create a new cancel button.
  const CancelButton({required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        width: 164,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.stop),
          label: const Text("Fahrt Beenden"),
          onPressed: onTap,
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color.fromARGB(255, 236, 240, 241))
              )
            ),
            foregroundColor: MaterialStateProperty.all<Color>(
              const Color.fromARGB(255, 236, 240, 241)
            ),
            backgroundColor: MaterialStateProperty.all<Color>(
              const Color.fromARGB(255, 44, 62, 80)
            ),
          )
        ),
      ),
    );
  }
}

class RideSpeedometerView extends StatefulWidget {
  const RideSpeedometerView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideSpeedometerViewState();
}

class RideSpeedometerViewState extends State<RideSpeedometerView> {
  static const viewId = "ride.views.speedometer";

  /// The associated recommendation service, which is injected by the provider.
  late RecommendationService rs;

  /// The associated positioning service, which is injected by the provider.
  late PositionService ps;

  /// The minimum displayed speed.
  static const minSpeed = 0.0;

  /// The maximum displayed speed.
  static const maxSpeed = 40.0;

  /// The default gauge colors for the speedometer.
  static const defaultGaugeColors = [Colors.grey];

  /// The current gauge colors, if we have the necessary data.
  List<Color> gaugeColors = defaultGaugeColors;

  /// The current gauge stops, if we have the necessary data.
  List<double> gaugeStops = [];

  @override
  void didChangeDependencies() {
    rs = Provider.of<RecommendationService>(context);
    ps = Provider.of<PositionService>(context);
    if (ps.needsLayout[viewId] != false || rs.needsLayout[viewId] != false) {
      updateView(rs, ps);
      ps.needsLayout[viewId] = false;
      rs.needsLayout[viewId] = false;
    }
    super.didChangeDependencies();
  }

  /// End the ride.
  Future<void> endRide(BuildContext context) async {
    // Reset the route service.
    final routingService = Provider.of<RoutingService>(context, listen: false);
    await routingService.reset();

    // End the recommendations and reset the recommendation service.
    final recommendationService = Provider.of<RecommendationService>(context, listen: false);
    await recommendationService.reset();

    // Stop the geolocation and reset the position service.
    final positionService = Provider.of<PositionService>(context, listen: false);
    await positionService.reset();

    // Stop the session and reset the session service.
    final session = Provider.of<SessionService>(context, listen: false);
    await session.reset();
  }

  /// Update the view with the current data.
  Future<void> updateView(RecommendationService rs, PositionService ps) async {
    await loadGauge(rs, ps);
  }

  /// Load the gauge colors and steps.
  Future<void> loadGauge(RecommendationService rs, PositionService ps) async {
    // Check if we have the necessary position data
    var posTime = ps.estimatedPosition?.timestamp;
    var posSpeed = ps.estimatedPosition?.speed;
    var posLat = ps.estimatedPosition?.latitude;
    var posLon = ps.estimatedPosition?.longitude;
    var timeStr = rs.currentRecommendation?.predictionStartTime;
    var tGreen = rs.currentRecommendation?.predictionGreentimeThreshold;
    var phases = rs.currentRecommendation?.predictionValue;
    var dist = rs.currentRecommendation?.distance;

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

  @override
  Widget build(BuildContext context) {
    var gauge = Positioned(
      child: Column(
        // Bottom to top
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            child: SfRadialGauge(
              axes: [RadialAxis(
                minimum: minSpeed, maximum: maxSpeed, 
                startAngle: 165, endAngle: 15,
                interval: 5, minorTicksPerInterval: 4,
                showAxisLine: true, 
                radiusFactor: 0.95,
                labelOffset: 15,
                axisLineStyle: const AxisLineStyle(thicknessUnit: GaugeSizeUnit.factor, thickness: 0.25),
                majorTickStyle: const MajorTickStyle(length: 10, thickness: 4, color: Color.fromARGB(255, 44, 62, 80)),
                minorTickStyle: const MinorTickStyle(length: 5, thickness: 1, color: Color.fromARGB(255, 52, 73, 94)),
                axisLabelStyle: const GaugeTextStyle(color: Color.fromARGB(255, 44, 62, 80), fontWeight: FontWeight.bold, fontSize: 14),
                ranges: [GaugeRange(
                  startValue: minSpeed, endValue: maxSpeed,
                  sizeUnit: GaugeSizeUnit.factor,
                  startWidth: 0.25,
                  endWidth: 0.25,
                  gradient: SweepGradient(colors: gaugeColors, stops: gaugeStops),
                )],
                pointers: [NeedlePointer(
                  value: (ps.estimatedPosition?.speed ?? 0) * 3.6,
                  needleLength: 0.875,
                  enableAnimation: true,
                  animationType: AnimationType.ease,
                  needleStartWidth: 1,
                  needleEndWidth: 8,
                  needleColor: const Color.fromARGB(255, 44, 62, 80),
                  knobStyle: const KnobStyle(knobRadius: 0.05, sizeUnit: GaugeSizeUnit.factor, color: Color.fromARGB(255, 44, 62, 80))
                )],
              )],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 44, 62, 80).withOpacity(1),
                  spreadRadius: 32,
                  blurRadius: 0,
                  offset: const Offset(0, 24),
                ),
                BoxShadow(
                  color: const Color.fromARGB(255, 52, 73, 94).withOpacity(0.1),
                  spreadRadius: 64,
                  blurRadius: 0,
                  offset: const Offset(0, 50),
                ),
              ],
            ),
          ),
        ],
      ),
      top: ((MediaQuery.of(context).size.height * 64 /* % */ ) / 100)
    );

    return WillPopScope(
      onWillPop: () async => false,
      child: Stack(
        alignment: Alignment.center,
        children: [
          gauge,
          Positioned(
            child: SafeArea(child: CancelButton(onTap: () async {
              await endRide(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            })),
            bottom: 8
          ),
        ]
      ),
    );
  }
}
