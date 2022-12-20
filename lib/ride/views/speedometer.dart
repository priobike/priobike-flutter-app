import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride/interface.dart';
import 'package:priobike/ride/views/trafficlight.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:priobike/positioning/services/positioning.dart';
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
  late Ride ride;

  /// The associated positioning service, which is injected by the provider.
  late Positioning positioning;

  /// The default gauge color for the speedometer.
  static const defaultGaugeColor = Color.fromARGB(255, 47, 47, 47);

  /// The current gauge colors, if we have the necessary data.
  List<Color> gaugeColors = [defaultGaugeColor];

  /// The current gauge stops, if we have the necessary data.
  List<double> gaugeStops = [];

  @override
  void initState() {
    hideNavigationBarAndroid();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // Fetch the maximum speed from the settings service.
    maxSpeed = Provider.of<Settings>(context, listen: false).speedMode.maxSpeed;

    positioning = Provider.of<Positioning>(context);
    ride = Provider.of<Ride>(context);
    if (ride.needsLayout[viewId] != false && positioning.needsLayout[viewId] != false) {
      ride.needsLayout[viewId] = false;
      positioning.needsLayout[viewId] = false;
      loadGauge(ride);
    }

    super.didChangeDependencies();
  }

  /// hide the buttom navigation bar on Android. Will be reenabled in the home screen.
  void hideNavigationBarAndroid() {
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],
      );
    }
  }

  /// Load the gauge colors and steps, from the predictor.
  Future<void> loadGauge(Ride ride) async {
    if (ride.calcPhasesFromNow == null || ride.calcQualitiesFromNow == null || ride.calcDistanceToNextSG == null) {
      gaugeColors = [defaultGaugeColor];
      gaugeStops = [];
      return;
    }

    final phases = ride.calcPhasesFromNow!;
    final qualities = ride.calcQualitiesFromNow!;

    var colors = <Color>[];
    for (var i = 0; i < phases.length; i++) {
      final phase = phases[i];
      final quality = qualities[i];
      final opacity = quality;
      colors.add(phase.color.withOpacity(opacity));
    }

    // Since we want the color steps not by second, but by speed, we map the stops accordingly
    var stops = Iterable<double>.generate(
      colors.length,
      (second) {
        if (second == 0) {
          return double.infinity;
        }
        // Map the second to the needed speed
        var speedKmh = (ride.calcDistanceToNextSG! / second) * 3.6;
        // Scale the speed between minSpeed and maxSpeed
        return (speedKmh - minSpeed) / (maxSpeed - minSpeed);
      },
    ).toList();

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
    positioning.setDebugSpeed(speed / 3.6);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    var gauge = SfRadialGauge(
      enableLoadingAnimation: false,
      axes: [
        RadialAxis(
          minimum: minSpeed,
          maximum: maxSpeed,
          onAxisTapped: onTapSpeedometer,
          startAngle: 160,
          endAngle: 20,
          interval: 10,
          minorTicksPerInterval: 4,
          showAxisLine: true,
          radiusFactor: 1,
          labelOffset: 14,
          axisLineStyle: AxisLineStyle(
            thicknessUnit: GaugeSizeUnit.factor,
            thickness: 0.25,
            color: isDark ? const Color.fromARGB(131, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0),
            cornerStyle: CornerStyle.bothFlat,
          ),
          majorTickStyle: MajorTickStyle(
            length: 20,
            thickness: 1.5,
            color: isDark ? const Color.fromARGB(131, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0),
          ),
          minorTickStyle: MinorTickStyle(
            length: 16,
            thickness: 1.5,
            color: isDark ? const Color.fromARGB(131, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0),
          ),
          axisLabelStyle: GaugeTextStyle(
            color: isDark ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontFamily: "HamburgSans",
            fontSize: 18,
          ),
          ranges: [
            GaugeRange(
              startValue: minSpeed,
              endValue: maxSpeed,
              startWidth: 48,
              endWidth: 48,
              gradient: SweepGradient(colors: gaugeColors, stops: gaugeStops),
            ),
          ],
          pointers: [
            MarkerPointer(
              value: (positioning.lastPosition?.speed ?? 0) * 3.6,
              markerType: MarkerType.rectangle,
              markerHeight: 24,
              elevation: 0,
              markerWidth: 64,
              enableAnimation: true,
              animationType: AnimationType.ease,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            MarkerPointer(
              value: (positioning.lastPosition?.speed ?? 0) * 3.6,
              markerType: MarkerType.rectangle,
              markerHeight: 18,
              elevation: 0,
              markerWidth: 58,
              enableAnimation: true,
              borderWidth: 2,
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
        offset: Offset(0, (MediaQuery.of(context).size.height / 2) - 64 - MediaQuery.of(context).padding.bottom),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: (MediaQuery.of(context).size.width),
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
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
            Container(
              height: (MediaQuery.of(context).size.width),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width / 2)),
              ),
            ),
            Container(
              height: (MediaQuery.of(context).size.width - 32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width / 2)),
              ),
            ),
            Container(
              height: (MediaQuery.of(context).size.width),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: const Color.fromARGB(255, 0, 0, 0), width: 52),
                borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width / 2)),
              ),
            ),
            Container(
              height: (MediaQuery.of(context).size.width - 4),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: defaultGaugeColor, width: 48),
                borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width / 2)),
              ),
            ),
            Container(
              height: (MediaQuery.of(context).size.width - 4),
              margin: const EdgeInsets.all(2),
              child: gauge,
            ),
            const RideTrafficLightView(),
          ],
        ),
      ),
    );
  }
}
