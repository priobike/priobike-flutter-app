import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/ride/views/map.dart';
import 'package:priobike/ride/views/trafficlight.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:provider/provider.dart';

class RideSpeedometerView extends StatefulWidget {
  const RideSpeedometerView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideSpeedometerViewState();
}

class RideSpeedometerViewState extends State<RideSpeedometerView> {
  static const viewId = "ride.views.speedometer";

  /// The minimum speed in km/h.
  final minSpeed = 0.0;

  /// The maximum speed in km/h.
  late double maxSpeed;

  /// The associated ride service, which is injected by the provider.
  late Ride rs;

  /// The associated positioning service, which is injected by the provider.
  late Positioning ps;

  /// The default gauge color for the speedometer.
  static const defaultGaugeColor = Color.fromARGB(255, 47, 47, 47);

  /// The current gauge colors, if we have the necessary data.
  List<Color> gaugeColors = [defaultGaugeColor];

  /// The current gauge stops, if we have the necessary data.
  List<double> gaugeStops = [];

  @override
  void didChangeDependencies() {
    // Fetch the maximum speed from the settings service.
    maxSpeed = Provider.of<Settings>(context, listen: false).speedMode.maxSpeed;

    rs = Provider.of<Ride>(context);
    ps = Provider.of<Positioning>(context);
    if (rs.needsLayout[viewId] != false) {
      rs.needsLayout[viewId] = false;
      loadGauge(rs, ps);
    }
    super.didChangeDependencies();
  }

  /// Load the gauge colors and steps.
  Future<void> loadGauge(Ride rs, Positioning ps) async {
    // Check if we have the necessary position data
    var posTime = ps.lastPosition?.timestamp;
    var posSpeed = ps.lastPosition?.speed;
    var posLat = ps.lastPosition?.latitude;
    var posLon = ps.lastPosition?.longitude;
    var timeStr = rs.currentRecommendation?.predictionStartTime;
    var tGreen = rs.currentRecommendation?.predictionGreentimeThreshold;
    var phases = rs.currentRecommendation?.predictionValue;
    var dist = rs.currentRecommendation?.distance;
    var sgId = rs.currentRecommendation?.sgId;
    var error = rs.currentRecommendation?.error;
    var currentQuality = rs.currentRecommendation?.quality;

    // Check if we have all necessary data to display the speedometer
    if (posTime == null || posSpeed == null || posLat == null || posLon == null || 
        timeStr == null || tGreen == null || phases == null || dist == null || 
        sgId == null || error == true || currentQuality == null) {
      gaugeColors = [defaultGaugeColor];
      gaugeStops = [];
      return;
    }

    if (currentQuality < RideMapViewState.qualityThreshold) {
      gaugeColors = [defaultGaugeColor];
      gaugeStops = [];
      return;
    }

    // Make more sanity checks
    if (posSpeed < 0) posSpeed = 0.0;

    // Chop off [UTC] from the end of the string
    if (timeStr.endsWith('[UTC]')) timeStr = timeStr.substring(0, timeStr.length - 5);
    var time = DateTime.tryParse(timeStr);
    if (time == null) {
      gaugeColors = [defaultGaugeColor];
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
      gaugeColors = [defaultGaugeColor];
      gaugeStops = [];
      return;
    }

    // Map each second from now to the corresponding predicted signal color
    var colors = phasesFromNow.map((phase) {
      if (phase >= tGreen) {
        // Map green values between the greentimeThreshold and the maxValue
        var factor = (phase - tGreen) / (maxValue - tGreen);
        return Color.lerp(defaultGaugeColor, const Color.fromARGB(255, 0, 255, 106), factor)!;
      } else {
        // Map red values between the minValue and the greentimeThreshold
        var factor = (phase - minValue) / (tGreen - minValue);
        return Color.lerp(const Color.fromARGB(255, 243, 60, 39), defaultGaugeColor, factor)!;
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
      colors.add(defaultGaugeColor);
      colors.add(defaultGaugeColor);
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

  /// A callback that is executed when the user taps on the speedometer.
  Future<void> onTapSpeedometer(double speed) async {
    // Set the selected speed in the positioning service.
    // This is a debug feature and only supported for some types of positioning.
    ps.setDebugSpeed(speed / 3.6);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    var gauge = SfRadialGauge(
      enableLoadingAnimation: true,
      axes: [
        RadialAxis(
          minimum: minSpeed, maximum: maxSpeed, 
          onAxisTapped: onTapSpeedometer,
          startAngle: 0, endAngle: 360,
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
              startWidth: 53,
              endWidth: 53,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ],
        ),
        RadialAxis(
          minimum: minSpeed, maximum: maxSpeed, 
          onAxisTapped: onTapSpeedometer,
          startAngle: 160, endAngle: 20,
          interval: 10, minorTicksPerInterval: 4,
          showAxisLine: true, 
          radiusFactor: 0.985,
          labelOffset: 14,
          axisLineStyle: AxisLineStyle(
            thicknessUnit: GaugeSizeUnit.factor, 
            thickness: 0.25, 
            color: isDark ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0),
            cornerStyle: CornerStyle.bothFlat,
          ),
          majorTickStyle: MajorTickStyle(
            length: 20, 
            thickness: 1.5, 
            color: isDark ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0)
          ),
          minorTickStyle: MinorTickStyle(
            length: 16, 
            thickness: 1.5, 
            color: isDark ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0)
          ),
          axisLabelStyle: GaugeTextStyle(
            color: isDark ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold, 
            fontSize: 18
          ),
          ranges: [
            GaugeRange(
              startValue: minSpeed, endValue: maxSpeed,
              startWidth: 48,
              endWidth: 48,
              gradient: SweepGradient(colors: gaugeColors, stops: gaugeStops),
            ),
          ],
          pointers: [
            MarkerPointer(
              value: (ps.lastPosition?.speed ?? 0) * 3.6,
              markerType: MarkerType.rectangle,
              markerHeight: 24,
              markerOffset: 4,
              elevation: 4,
              markerWidth: 64,
              enableAnimation: true,
              animationType: AnimationType.ease,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            MarkerPointer(
              value: (ps.lastPosition?.speed ?? 0) * 3.6,
              markerType: MarkerType.rectangle,
              markerHeight: 18,
              markerOffset: 4,
              elevation: 4,
              markerWidth: 58,
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
          padding: const EdgeInsets.all(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                child: gauge, 
                height: (MediaQuery.of(context).size.width - 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(MediaQuery.of(context).size.width / 2),
                    topRight: Radius.circular(MediaQuery.of(context).size.width / 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
              Container(
                child: gauge, 
                height: (MediaQuery.of(context).size.width - 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width / 2)),
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
