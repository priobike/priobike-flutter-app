import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride_crossing.dart';
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
  late RideCrossing rideCrossing;

  /// The associated positioning service, which is injected by the provider.
  late Positioning positioning;

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

    if (rideCrossing.needsLayout[viewId] != false && positioning.needsLayout[viewId] != false) {
      positioning.needsLayout[viewId] = false;
    }
  }

  @override
  void initState() {
    hideNavigationBarAndroid();
    super.initState();

    positioning = getIt<Positioning>();
    positioning.addListener(update);
    rideCrossing = getIt<RideCrossing>();
    rideCrossing.addListener(update);

    updateSpeedometer();
  }

  @override
  void dispose() {
    positioning.removeListener(update);
    rideCrossing.removeListener(update);
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

  @override
  Widget build(BuildContext context) {
    final displayHeight = MediaQuery.of(context).size.height;
    final heightToPuck = displayHeight / 2;
    final heightToPuckBoundingBox = heightToPuck - (displayHeight * 0.05);

    final originalSpeedometerHeight = MediaQuery.of(context).size.width;
    final originalSpeedometerWidth = MediaQuery.of(context).size.width;

    final currentCrossing = rideCrossing.crossingPredictionService?.subscribedCrossing;
    print("Current crossing: $currentCrossing");

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        /*Container(
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
        ),*/
        if (currentCrossing != null)
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
                      children: List.from(currentCrossing.recommendations.entries
                          .map((value) => Text(value.value.calcCurrentSignalPhase.name))),
                    )),
              ),
            ),
          ),
      ],
    );
  }
}
