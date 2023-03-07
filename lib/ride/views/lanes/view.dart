import 'dart:io';
import 'dart:math';

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

  /// The distance before a signal group from which it is considered for predictions and recommendations.
  static const preDistance = RideMultiLane.preDistance;

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

  double getBarWidth(double standardBarWidth, int numberOfLanes) {
    if (numberOfLanes <= 3) return standardBarWidth;
    return standardBarWidth / numberOfLanes;
  }

  double getBottomOffset(double standardBarHeight, double sgDistanceOnRoute) {
    // Convert from relative to absolute distance.
    final absSgDistance = ride.route!.path.distance * sgDistanceOnRoute;

    final userDistanceOnRoute = positioning.snap?.distanceOnRoute;
    if (userDistanceOnRoute == null) return 1000;
    final distanceToSignalGroup = absSgDistance - userDistanceOnRoute;
    final bottomOffset = distanceToSignalGroup * (standardBarHeight / preDistance);
    return bottomOffset;
  }

  @override
  Widget build(BuildContext context) {
    final standardBarHeight = MediaQuery.of(context).size.height * 1;
    final standardBarWidth = (MediaQuery.of(context).size.width / 3) - 10;

    final currentSgs = ride.currentSignalGroups;
    final currentSgsOrdered = List<SgMultiLane>.from(currentSgs);
    currentSgsOrdered.sort((a, b) => a.direction.compareTo(b.direction));

    const tiltDegree = -45;

    Matrix4 perspective = Matrix4(
      1.0, 0.0, 0.0, 0.0, //
      0.0, 1.0, 0.0, 0.0, //
      0.0, 0.0, 1.0, 0.002, //
      0.0, 0.0, 0.0, 1.0,
    );

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (currentSgsOrdered.isNotEmpty)
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 1.0,
                colors: [
                  Colors.black,
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0),
                ],
                stops: const [0.0, 0.5, 1],
              ),
            ),
          ),
        if (currentSgsOrdered.isNotEmpty)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.from(
                currentSgsOrdered.map(
                  (sg) {
                    final phase =
                        ride.predictionServiceMultiLane?.recommendations[sg.id]?.calcCurrentSignalPhase ?? Phase.dark;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: getColor(phase),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: sg.laneType.icon(Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        if (currentSgsOrdered.isNotEmpty)
          Transform(
            alignment: FractionalOffset.bottomCenter,
            transform: perspective.scaled(1.0, 1.0, 1.0)
              ..rotateX(tiltDegree * pi / 180)
              ..rotateY(0.0)
              ..rotateZ(0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.from(
                currentSgsOrdered.map(
                  (sg) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: SizedBox(
                        width: getBarWidth(standardBarWidth, currentSgsOrdered.length),
                        height: standardBarHeight,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color.fromARGB(255, 219, 219, 219),
                                      Theme.of(context).primaryColor,
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: getBarWidth(standardBarWidth - 2, currentSgsOrdered.length),
                                height: standardBarHeight,
                                child: Container(
                                  color: const Color.fromARGB(255, 50, 50, 50),
                                ),
                              ),
                              AnimatedPositioned(
                                key: ValueKey(sg.id),
                                duration: const Duration(seconds: 1),
                                curve: Curves.linear,
                                width: getBarWidth(standardBarWidth - 2, currentSgsOrdered.length),
                                height: standardBarHeight,
                                bottom: getBottomOffset(standardBarHeight, sg.distanceOnRoute),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 32),
                                child: Icon(
                                  sg.direction.icon,
                                  color: Colors.white,
                                  size: 112,
                                  shadows: const <Shadow>[Shadow(color: Colors.grey, blurRadius: 5.0)],
                                ),
                              ),
                              Container(
                                width: getBarWidth(standardBarWidth, currentSgsOrdered.length),
                                height: standardBarHeight * 0.03,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 219, 219, 219),
                                  border: Border.all(
                                    color: const Color.fromARGB(255, 225, 225, 225),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromARGB(150, 170, 170, 170),
                                      spreadRadius: 2,
                                      blurRadius: 3,
                                      offset: Offset(0, 1), // changes position of shadow
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        if (currentSgsOrdered.isNotEmpty)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            child: Row(
              children: [
                Transform.rotate(
                  angle: 40,
                  child: Container(
                    height: 20,
                    width: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      color: Theme.of(context).primaryColor,
                      width: MediaQuery.of(context).size.width - 20,
                      height: 5,
                    ),
                    Image.asset('assets/images/position-dark.png', height: 100),
                  ],
                ),
                Transform.rotate(
                  angle: 40,
                  child: Container(
                    height: 20,
                    width: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
