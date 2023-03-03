import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning_multi_lane.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride_multi_lane.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/services/settings.dart';

class LanesDemoView extends StatefulWidget {
  const LanesDemoView({Key? key}) : super(key: key);

  @override
  LanesDemoViewState createState() => LanesDemoViewState();
}

class LanesDemoViewState extends State<LanesDemoView> with TickerProviderStateMixin {
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

  double y = 0;

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

    run();
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

  Future<void> run() async {
    while (true) {
      y += 10;
      await Future.delayed(const Duration(seconds: 1));
      if (y > 1000) {
        y = 0;
      }
      log.i("aawefawefawefawefawef");
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalSpeedometerHeight = MediaQuery.of(context).size.width;
    final originalSpeedometerWidth = MediaQuery.of(context).size.width;

    final demoList = ["bla", "blub", "blabla"];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: List.from(
        demoList.map(
          (value) {
            return Expanded(
              child: Stack(
                children: [
                  AnimatedPositioned(
                    top: 0,
                    duration: const Duration(seconds: 1),
                    curve: Curves.linear,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        height: 1000,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
