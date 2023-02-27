import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/ride/views/speedometer/background.dart';
import 'package:priobike/ride/views/speedometer/cover.dart';
import 'package:priobike/ride/views/speedometer/labels.dart';
import 'package:priobike/ride/views/speedometer/prediction_arc.dart';
import 'package:priobike/ride/views/speedometer/speed_arc.dart';
import 'package:priobike/ride/views/speedometer/ticks.dart';
import 'package:priobike/ride/views/trafficlight.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/services/settings.dart';

class RideSpeedometerView extends StatefulWidget {
  const RideSpeedometerView({Key? key}) : super(key: key);

  @override
  RideSpeedometerViewState createState() => RideSpeedometerViewState();
}

class RideSpeedometerViewState extends State<RideSpeedometerView> with TickerProviderStateMixin {
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

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  /// Update the speedometer.
  void updateSpeedometer() {
    // Fetch the maximum speed from the settings service.
    maxSpeed = getIt<Settings>().speedMode.maxSpeed;

    if (ride.needsLayout[viewId] != false && positioning.needsLayout[viewId] != false) {
      positioning.needsLayout[viewId] = false;
      // Animate the speed to the new value.
      final kmh = (positioning.lastPosition?.speed ?? 0.0 / maxSpeed) * 3.6;
      // Scale between minSpeed and maxSpeed.
      final pct = (kmh - minSpeed) / (maxSpeed - minSpeed);
      // Animate to the new value.
      speedAnimationController.animateTo(pct, duration: const Duration(milliseconds: 1000), curve: Curves.easeInOut);
      // Load the gauge colors and steps, from the predictor.
      loadGauge(ride);
    }
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

    update = () {
      updateSpeedometer();
      setState(() {});
    };

    positioning = getIt<Positioning>();
    positioning.addListener(update);
    ride = getIt<Ride>();
    ride.addListener(update);

    updateSpeedometer();
  }

  @override
  void dispose() {
    speedAnimationController.dispose();
    positioning.removeListener(update);
    ride.removeListener(update);
    super.dispose();
  }

  /// Hide the buttom navigation bar on Android. Will be reenabled in the home screen.
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
    final displayHeight = MediaQuery.of(context).size.height;
    final heightToPuck = displayHeight / 2;
    final heightToPuckBoundingBox = heightToPuck - (displayHeight * 0.05);

    final originalSpeedometerHeight = MediaQuery.of(context).size.width;
    final originalSpeedometerWidth = MediaQuery.of(context).size.width;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: originalSpeedometerHeight,
          width: originalSpeedometerWidth,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).colorScheme.brightness == Brightness.dark
                  ? [
                      Colors.black.withOpacity(0),
                      Colors.black.withOpacity(0.5),
                      Colors.black,
                    ]
                  : [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.1),
                      Colors.black,
                    ],
              stops: Theme.of(context).colorScheme.brightness == Brightness.dark
                  ? const [0.1, 0.3, 0.5] // Dark theme
                  : const [0.0, 0.1, 0.8], // Light theme
            ),
          ),
        ),
        SafeArea(
          bottom: true,
          child: SizedBox(
            height: heightToPuckBoundingBox,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                height: originalSpeedometerHeight,
                width: originalSpeedometerWidth,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, 42),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // When the user taps on the speedometer, we want to set the speed to the tapped speed.
                        onTapUp: (details) {
                          // Get the center of the speedometer
                          final xRel = details.localPosition.dx / MediaQuery.of(context).size.width;
                          final yRel = details.localPosition.dy / MediaQuery.of(context).size.width;
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
                            CustomPaint(
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
                              painter: SpeedometerSpeedArcPainter(
                                minSpeed: minSpeed,
                                maxSpeed: maxSpeed,
                                isDark: Theme.of(context).colorScheme.brightness == Brightness.dark,
                                // Scale the animation pct between minSpeed and maxSpeed
                                speed: speedkmh,
                              ),
                            ),
                            CustomPaint(painter: SpeedometerCoverPainter()),
                            CustomPaint(
                              painter: SpeedometerLabelsPainter(
                                minSpeed: minSpeed,
                                maxSpeed: maxSpeed,
                              ),
                            ),
                            const Center(child: RideTrafficLightView())
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 26),
                      child: BoldSubHeader(
                        text: '${speedkmh.toStringAsFixed(0)} km/h',
                        context: context,
                        color: Colors.white,
                      ),
                    ),
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
