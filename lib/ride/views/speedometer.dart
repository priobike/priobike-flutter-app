import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/ride/views/button.dart';
import 'package:priobike/ride/views/trafficlight.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:provider/provider.dart';

class RideSpeedometerView extends StatefulWidget {
  const RideSpeedometerView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideSpeedometerViewState();
}

class RideSpeedometerViewState extends State<RideSpeedometerView> {
  static const viewId = "ride.views.speedometer";

  /// The associated ride service, which is injected by the provider.
  late RideService rs;

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
    rs = Provider.of<RideService>(context);
    ps = Provider.of<PositionService>(context);
    if (ps.needsLayout[viewId] != false || rs.needsLayout[viewId] != false) {
      updateView(rs, ps);
      ps.needsLayout[viewId] = false;
      rs.needsLayout[viewId] = false;
    }
    super.didChangeDependencies();
  }

  /// Update the view with the current data.
  Future<void> updateView(RideService rs, PositionService ps) async {
    await loadGauge(rs, ps);
  }

  /// Load the gauge colors and steps.
  Future<void> loadGauge(RideService rs, PositionService ps) async {
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
    if (maxValue == minValue) {
      gaugeColors = [Colors.grey];
      gaugeStops = [];
      return;
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
    var gauge = SfRadialGauge(
      enableLoadingAnimation: true,
      axes: [
        RadialAxis(
          minimum: minSpeed, maximum: maxSpeed, 
          startAngle: 165, endAngle: 15,
          showTicks: false,
          showLabels: false,
          showAxisLine: false, 
          radiusFactor: 1,
          labelOffset: 15,
          axisLineStyle: const AxisLineStyle(
            thicknessUnit: GaugeSizeUnit.factor, 
            thickness: 0.25, 
            color: Color.fromARGB(255, 44, 62, 80), 
            cornerStyle: CornerStyle.bothFlat,
          ),
          ranges: [
            GaugeRange(
              startValue: minSpeed, endValue: maxSpeed,
              startWidth: 43,
              endWidth: 43,
              color: Colors.black,
            ),
          ],
        ),
        RadialAxis(
          minimum: minSpeed, maximum: maxSpeed, 
          startAngle: 166, endAngle: 14,
          interval: 10, minorTicksPerInterval: 4,
          showAxisLine: true, 
          radiusFactor: 0.985,
          labelOffset: 16,
          axisLineStyle: const AxisLineStyle(
            thicknessUnit: GaugeSizeUnit.factor, 
            thickness: 0.25, 
            color: Color.fromARGB(255, 0, 0, 0), 
            cornerStyle: CornerStyle.bothFlat,
          ),
          majorTickStyle: const MajorTickStyle(
            length: 7.5, 
            thickness: 1.5, 
            color: Color.fromARGB(255, 0, 0, 0)
          ),
          minorTickStyle: const MinorTickStyle(
            length: 5, 
            thickness: 1.5, 
            color: Color.fromARGB(255, 0, 0, 0)
          ),
          axisLabelStyle: const GaugeTextStyle(
            color: Color.fromARGB(255, 0, 0, 0), 
            fontWeight: FontWeight.bold, 
            fontSize: 18
          ),
          ranges: [
            GaugeRange(
              startValue: minSpeed, endValue: maxSpeed,
              startWidth: 38,
              endWidth: 38,
              gradient: SweepGradient(colors: gaugeColors, stops: gaugeStops),
            ),
          ],
          pointers: [
            MarkerPointer(
              value: (ps.estimatedPosition?.speed ?? 0) * 3.6,
              markerType: MarkerType.rectangle,
              markerHeight: 22,
              markerOffset: 0,
              elevation: 4,
              markerWidth: 56,
              enableAnimation: true,
              animationType: AnimationType.ease,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            MarkerPointer(
              value: (ps.estimatedPosition?.speed ?? 0) * 3.6,
              markerType: MarkerType.rectangle,
              markerHeight: 16,
              markerOffset: 0,
              elevation: 4,
              markerWidth: 50,
              enableAnimation: true,
              borderWidth: 4,
              borderColor: Theme.of(context).colorScheme.background,
              animationType: AnimationType.ease,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ],
    );

    return WillPopScope(
      onWillPop: () async => false,
      child: Transform.translate(
        offset: Offset(0, (MediaQuery.of(context).size.height / 2) - 64 - 8 - MediaQuery.of(context).padding.bottom), 
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                child: gauge, 
                height: (MediaQuery.of(context).size.width - 16),
                  decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  shape: BoxShape.circle,
                ),
              ),
              const RideTrafficLightView(),
            ]
          ),
        )
      ),
    );
  }
}
