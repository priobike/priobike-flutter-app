import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/ride/views/center_buttons.dart';
import 'package:priobike/ride/views/speedometer/alert.dart';
import 'package:priobike/ride/views/speedometer/background.dart';
import 'package:priobike/ride/views/speedometer/cover.dart';
import 'package:priobike/ride/views/speedometer/labels.dart';
import 'package:priobike/ride/views/speedometer/prediction_arc.dart';
import 'package:priobike/ride/views/speedometer/speed_arc.dart';
import 'package:priobike/ride/views/speedometer/shadow.dart';
import 'package:priobike/ride/views/speedometer/ticks.dart';
import 'package:priobike/ride/views/trafficlight.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/services/settings.dart';

class RideSpeedometerView extends StatefulWidget {
  /// Height to puck bounding box.
  final double puckHeight;

  const RideSpeedometerView({super.key, required this.puckHeight});

  @override
  RideSpeedometerViewState createState() => RideSpeedometerViewState();
}

class RideSpeedometerViewState extends State<RideSpeedometerView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const viewId = "ride.views.speedometer";

  /// The minimum speed in km/h.
  final minSpeed = 0.0;

  /// The maximum speed in km/h.
  late double maxSpeed;

  /// The associated ride service, which is injected by the provider.
  late Ride ride;

  /// The associated positioning service, which is injected by the provider.
  late Positioning positioning;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The default gauge color for the speedometer.
  static const defaultGaugeColor = Color.fromARGB(0, 0, 0, 0);

  /// The current gauge colors, if we have the necessary data.
  List<Color> gaugeColors = [defaultGaugeColor];

  /// The current gauge stops, if we have the necessary data.
  List<double> gaugeStops = [];

  /// The animation controller for the speed animation.
  late AnimationController speedAnimationController;

  /// The speed animation.
  late Animation<double> speedAnimation;

  /// The value of the speed animation.
  double speedAnimationPct = 0;

  /// Update the speedometer.
  void updateSpeedometer() {
    // Fetch the maximum speed from the settings service.
    maxSpeed = getIt<Settings>().speedMode.maxSpeed;

    // Animate the speed to the new value.
    final kmh = (positioning.lastPosition?.speed ?? 0.0 / maxSpeed) * 3.6;

    // Scale between minSpeed and maxSpeed.
    final pct = (kmh - minSpeed) / (maxSpeed - minSpeed);
    // Animate to the new value.
    speedAnimationController.animateTo(pct, duration: const Duration(milliseconds: 1000), curve: Curves.easeInOut);
    // Load the gauge colors and steps, from the predictor.
    if (!routing.hadErrorDuringFetch) {
      loadGauge(ride);
    }

    setState(() {});
  }

  /// Update the layout of the speedometer.
  void updateLayout() {
    setState(() {});
  }

  @override
  void initState() {
    hideNavigationBarAndroid();
    super.initState();
    // Initialize the speed animation.
    speedAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      animationBehavior: AnimationBehavior.preserve,
    );
    speedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(speedAnimationController);
    speedAnimation.addListener(() {
      setState(() {
        speedAnimationPct = speedAnimation.value;
      });
    });

    positioning = getIt<Positioning>();
    positioning.addListener(updateSpeedometer);
    routing = getIt<Routing>();
    routing.addListener(updateLayout);
    ride = getIt<Ride>();
    ride.addListener(updateLayout);

    updateSpeedometer();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> didChangeMetrics() async {
    if (Platform.isAndroid) {
      await Future.delayed(const Duration(milliseconds: 10));
      SystemChrome.restoreSystemUIOverlays();
    }
  }

  @override
  void dispose() {
    speedAnimationController.dispose();
    positioning.removeListener(updateSpeedometer);
    routing.removeListener(updateLayout);
    ride.removeListener(updateLayout);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Hide the bottom navigation bar on Android. Will be reenabled in the home screen.
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
    if (ride.predictionComponent?.recommendation == null || ride.calcDistanceToNextSG == null) {
      gaugeColors = [defaultGaugeColor, defaultGaugeColor];
      gaugeStops = [0.0, 1.0];
      return;
    }

    // Don't display the gauge if the user has overridden the signal group.
    // This is to prevent users from adapting to something else then the upcoming signal.
    // Additionally, the distance is currently only calculated based on the upcoming signal group.
    // Therefore the gauge would show incorrect values if the user has overridden the signal group.
    if (ride.userSelectedSG != null) {
      gaugeColors = [defaultGaugeColor, defaultGaugeColor];
      gaugeStops = [0.0, 1.0];
      return;
    }

    final phases = ride.predictionComponent!.recommendation!.calcPhasesFromNow;
    final qualities = ride.predictionComponent!.recommendation!.calcQualitiesFromNow;

    var colors = <Color>[];
    for (var i = 0; i < phases.length; i++) {
      final phase = phases[i];
      final quality = max(0, qualities[i]);
      final opacity = quality;
      colors.add(Color.lerp(defaultGaugeColor, phase.color, opacity.toDouble()) ?? defaultGaugeColor);
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
    final speedkmh = minSpeed + (speedAnimationPct * (maxSpeed - minSpeed));

    final remainingDistance =
        (((ride.route?.path.distance ?? 0.0) - (positioning.snap?.distanceOnRoute ?? 0.0)) / 1000).abs();
    final remainingMinutes = remainingDistance / (18 / 60);
    final timeOfArrival = DateTime.now().add(Duration(minutes: remainingMinutes.toInt()));

    final showAlert = routing.hadErrorDuringFetch;

    final orientation = MediaQuery.of(context).orientation;
    final isLandscapeMode = orientation == Orientation.landscape;
    final double originalSpeedometerHeight;
    final double originalSpeedometerWidth;
    final double sizedBoxHeight;
    final double? sizedBoxWidth;

    if (orientation == Orientation.portrait) {
      // Portrait mode
      originalSpeedometerHeight = MediaQuery.of(context).size.width;
      originalSpeedometerWidth = MediaQuery.of(context).size.width;
      sizedBoxHeight = widget.puckHeight;
      sizedBoxWidth = null;
    } else {
      // Landscape mode
      originalSpeedometerHeight = MediaQuery.of(context).size.height;
      originalSpeedometerWidth = MediaQuery.of(context).size.height;
      sizedBoxHeight = originalSpeedometerHeight;
      sizedBoxWidth = originalSpeedometerWidth;
    }
    final size = Size(originalSpeedometerWidth, originalSpeedometerHeight);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        isLandscapeMode
            ? Container()
            : SpeedometerLinearShadow(
                originalSpeedometerHeight: originalSpeedometerHeight,
                originalSpeedometerWidth: originalSpeedometerWidth),
        SafeArea(
          bottom: true,
          child: SizedBox(
            height: sizedBoxHeight,
            width: sizedBoxWidth,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                height: originalSpeedometerHeight,
                width: originalSpeedometerWidth,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    if (isLandscapeMode)
                      Transform.translate(
                        offset: const Offset(0, 42),
                        child: Center(
                          child: SpeedometerRadialShadow(size: size),
                        ),
                      ),
                    if (showAlert)
                      Transform.translate(
                        offset: const Offset(0, 42),
                        child: Center(
                          child: SpeedometerAlert(size: size),
                        ),
                      ),
                    Transform.translate(
                      offset: const Offset(0, 42),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // When the user taps on the speedometer, we want to set the speed to the tapped speed.
                        onTapUp: (details) {
                          // Get the center of the speedometer
                          final double xRel;
                          final double yRel;
                          if (isLandscapeMode) {
                            xRel = details.localPosition.dx / MediaQuery.of(context).size.height;
                            yRel = details.localPosition.dy / MediaQuery.of(context).size.height;
                          } else {
                            xRel = details.localPosition.dx / MediaQuery.of(context).size.width;
                            yRel = details.localPosition.dy / MediaQuery.of(context).size.width;
                          }
                          // Transform the angle of the tapped position into an intuitive angle system:
                          // 0 deg is south, 90 deg is west, 180 deg is north, 270 deg is east.
                          final angleDeg = atan2(yRel - 0.5, xRel - 0.5) * 180 / pi - 90;
                          final headingDeg = angleDeg > 0 ? angleDeg : 360 + angleDeg;
                          // Interpolate the heading to a speed.
                          const minDeg = 45.0, maxDeg = 315.0;
                          var speed = (headingDeg - minDeg) / (maxDeg - minDeg) * (maxSpeed - minSpeed) + minSpeed;
                          speed = max(minSpeed, min(maxSpeed, speed));
                          onTapSpeedometer(speed);
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (!isLandscapeMode) CustomPaint(painter: SpeedometerCoverPainter()),
                            CustomPaint(
                              size: size,
                              painter: SpeedometerBackgroundPainter(
                                isDark: Theme.of(context).colorScheme.brightness == Brightness.dark,
                              ),
                            ),
                            CustomPaint(
                              painter: SpeedometerTicksPainter(
                                minSpeed: minSpeed,
                                maxSpeed: maxSpeed,
                              ),
                            ),
                            if (!showAlert)
                              CustomPaint(
                                painter: SpeedometerPredictionArcPainter(
                                  minSpeed: minSpeed,
                                  maxSpeed: maxSpeed,
                                  colors: gaugeColors,
                                  stops: gaugeStops,
                                  isDark: Theme.of(context).colorScheme.brightness == Brightness.dark,
                                ),
                              ),
                            CustomPaint(
                              painter: SpeedometerLabelsPainter(
                                minSpeed: minSpeed,
                                maxSpeed: maxSpeed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!showAlert)
                      Transform.translate(
                        offset: const Offset(0, 42),
                        child: Center(
                          child: RideTrafficLightView(
                            size: size,
                          ),
                        ),
                      ),
                    if (!showAlert)
                      Transform.translate(
                        offset: const Offset(0, 42),
                        child: RideCenterButtonsView(
                          size: size,
                        ),
                      ),
                    IgnorePointer(
                      child: Transform.translate(
                        offset: const Offset(0, 42),
                        child: CustomPaint(
                          size: size,
                          painter: SpeedometerSpeedArcPainter(
                            minSpeed: minSpeed,
                            maxSpeed: maxSpeed,
                            isDark: Theme.of(context).colorScheme.brightness == Brightness.dark,
                            // Scale the animation pct between minSpeed and maxSpeed
                            speed: speedkmh,
                          ),
                        ),
                      ),
                    ),
                    if (ride.userSelectedSG == null) ...[
                      if (!showAlert)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 62),
                          child: BoldContent(
                            text:
                                "${remainingDistance.toStringAsFixed(1)} km • ${DateFormat('HH:mm').format(timeOfArrival)}",
                            context: context,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 26),
                        child: Text(
                          '${speedkmh.toStringAsFixed(0)} km/h',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text(
                        'PrioBike App - Work in Progress.',
                        style: Theme.of(context).textTheme.displaySmall!.merge(
                              TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 8,
                              ),
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: ride.predictionComponent?.currentMode == PredictionMode.usePredictor
                            // Display a small dot to indicate that the fallback is active.
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                width: 4,
                                height: 4,
                              )
                            : const SizedBox(width: 4, height: 4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
