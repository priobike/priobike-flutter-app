import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning_multi_lane.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride_multi_lane.dart';
import 'package:priobike/routing/models/sg_multi_lane.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/services/settings.dart';

class LanesView extends StatefulWidget {
  const LanesView({Key? key}) : super(key: key);

  @override
  LanesViewState createState() => LanesViewState();
}

class LanesViewState extends State<LanesView> with TickerProviderStateMixin {
  static const viewId = "ride.views.speedometer";

  /// The minimum speed in km/h.
  final minSpeed = 0.0;

  /// The maximum speed in km/h.
  late double maxSpeed;

  /// The associated ride service, which is injected by the provider.
  late RideMultiLane ride;

  /// The associated positioning service, which is injected by the provider.
  late PositioningMultiLane positioning;

  /// The default gauge color for the speedometer.
  static const defaultGaugeColor = Color.fromARGB(0, 0, 0, 0);

  /// The current gauge colors, if we have the necessary data.
  List<Color> gaugeColors = [defaultGaugeColor];

  /// The current gauge stops, if we have the necessary data.
  List<double> gaugeStops = [];

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    updateSpeedometer();
    setState(() {});
  }

  /// Update the speedometer.
  void updateSpeedometer() {
    // Fetch the maximum speed from the settings service.
    maxSpeed = getIt<Settings>().speedMode.maxSpeed;

    if (ride.needsLayout[viewId] != false && positioning.needsLayout[viewId] != false) {
      positioning.needsLayout[viewId] = false;
    }
  }

  @override
  void initState() {
    hideNavigationBarAndroid();
    super.initState();

    positioning = getIt<PositioningMultiLane>();
    positioning.addListener(update);
    ride = getIt<RideMultiLane>();
    ride.addListener(update);

    updateSpeedometer();
  }

  @override
  void dispose() {
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

  Color getColor(Phase calcCurrentSignalPhase) {
    final bool isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    switch (calcCurrentSignalPhase) {
      case Phase.green:
        if (isDark) {
          return Colors.green;
        } else {
          return Colors.green;
        }
      case Phase.amber:
        if (isDark) {
          return Colors.amber;
        } else {
          return Colors.amber;
        }
      case Phase.redAmber:
        if (isDark) {
          return Colors.redAccent;
        } else {
          return Colors.redAccent;
        }
      case Phase.red:
        if (isDark) {
          return Colors.red;
        } else {
          return Colors.red;
        }
      default:
        if (isDark) {
          return Colors.grey;
        } else {
          return Colors.grey;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayHeight = MediaQuery.of(context).size.height;
    final heightToPuck = displayHeight / 2;
    final heightToPuckBoundingBox = heightToPuck - (displayHeight * 0.05);

    final originalSpeedometerHeight = MediaQuery.of(context).size.width;
    final originalSpeedometerWidth = MediaQuery.of(context).size.width;

    // final currentCrossing = ride.crossingPredictionService?.subscribedCrossing;
    final currentSgs = ride.currentSignalGroups;
    final currentSgsOrdered = List<SgMultiLane>.from(currentSgs);
    currentSgsOrdered.sort((a, b) => a.direction.compareTo(b.direction));

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
        if (currentSgsOrdered.isNotEmpty)
          SafeArea(
            bottom: true,
            child: SizedBox(
              height: heightToPuckBoundingBox,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  height: originalSpeedometerHeight,
                  width: originalSpeedometerWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: List.from(
                      currentSgsOrdered.map(
                        (SgMultiLane sg) {
                          // Calculate the countdown.
                          final countdown = ride
                              .predictionServiceMultiLane?.recommendations[sg.id]?.calcCurrentPhaseChangeTime
                              ?.difference(DateTime.now())
                              .inSeconds;
                          // If the countdown is 0 (or negative), we hide the countdown. In this way the user
                          // is not confused if the countdown is at 0 for a few seconds.
                          final countdownLabel = (countdown ?? 0) > 0 ? "$countdown" : "";

                          final phase =
                              ride.predictionServiceMultiLane?.recommendations[sg.id]?.calcCurrentSignalPhase ??
                                  Phase.dark;
                          return Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRect(
                                  clipBehavior: Clip.none,
                                  child: Transform.translate(
                                    offset: const Offset(0, -300),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Container(
                                        height: 1000,
                                        color: getColor(phase),
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Icon(
                                      sg.direction.icon,
                                      color: Colors.white,
                                      size: 64,
                                    ),
                                    /*BoldSubHeader(
                                      text: countdownLabel,
                                      context: context,
                                      color: Colors.white,
                                    ),*/
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Transform.translate(
          offset: const Offset(0, -150),
          child: Container(
            color: Colors.blue,
            height: 6,
          ),
        ),
      ],
    );
  }
}
