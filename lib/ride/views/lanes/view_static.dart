import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning_multi_lane.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride_multi_lane.dart';
import 'package:priobike/ride/views/lanes/lane_container.dart';
import 'package:priobike/routing/models/sg_multi_lane.dart';

class LanesStaticView extends StatefulWidget {
  const LanesStaticView({Key? key}) : super(key: key);

  @override
  LanesStaticViewState createState() => LanesStaticViewState();
}

class LanesStaticViewState extends State<LanesStaticView> with TickerProviderStateMixin {
  static const viewId = "ride.views.speedometer";

  /// The minimum speed in km/h.
  final minSpeed = 0.0;

  /// The maximum speed in km/h.
  late double maxSpeed;

  /// The associated ride service, which is injected by the provider.
  late RideMultiLane ride;

  /// The associated positioning service, which is injected by the provider.
  late PositioningMultiLane positioning;

  /// The distance before a signal group from which it is considered for predictions and recommendations.
  static const preDistance = RideMultiLane.preDistance;

  /// Called when a listener callback of a ChangeNotifier is fired. Don't rebuild when the gradient gets updated.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    hideNavigationBarAndroid();
    super.initState();

    positioning = getIt<PositioningMultiLane>();
    positioning.addListener(update);
    ride = getIt<RideMultiLane>();
    ride.addListener(update);
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

  double getBottomOffset(double standardBarHeight, String sgId) {
    final distanceToSignalGroup = ride.distancesToCurrentSignalGroups[sgId];
    if (distanceToSignalGroup == null) return 1000;
    final bottomOffset = (distanceToSignalGroup * (standardBarHeight / preDistance)) - (0.47 * standardBarHeight);
    return bottomOffset;
  }

  @override
  Widget build(BuildContext context) {
    final standardBarHeight = MediaQuery.of(context).size.height;
    final standardBarWidth = (MediaQuery.of(context).size.width / 3) - 10;

    final stopLineHeight = standardBarHeight * 0.01;

    final currentSgs = ride.currentSignalGroups;
    final currentSgsOrdered = List<SgMultiLane>.from(currentSgs);
    currentSgsOrdered.sort((a, b) => a.direction.compareTo(b.direction));

    // For standardBarHeight of 640, -45 works well
    // For standardBarHeight of 896, -39 works well
    // Based on this, we have to choose the right value based on the standardBarHeight
    final standardBarHeightDiff = 640 - standardBarHeight;
    final degreeDiff = standardBarHeightDiff / (256 / 6);
    final tiltDegree = -45 - degreeDiff;

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
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              AnimatedPositioned(
                                key: ValueKey(sg.id),
                                duration: const Duration(seconds: 1),
                                curve: Curves.linear,
                                width: getBarWidth(standardBarWidth, currentSgsOrdered.length),
                                height: standardBarHeight,
                                bottom: getBottomOffset(standardBarHeight, sg.id),
                                child: Stack(
                                  children: [
                                    Transform.translate(
                                      offset: Offset(0, stopLineHeight),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              const Color.fromARGB(255, 219, 219, 219),
                                              Theme.of(context).colorScheme.primary,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: LaneContainerWidget(sgId: sg.id),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: getBarWidth(standardBarWidth, currentSgsOrdered.length),
                                      height: stopLineHeight,
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
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 32),
                                child: Icon(
                                  sg.direction.icon,
                                  color: Colors.white,
                                  size: 112,
                                  shadows: const <Shadow>[Shadow(color: Colors.black, blurRadius: 10.0)],
                                ),
                              ),
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
            child: Transform(
              alignment: FractionalOffset.bottomCenter,
              transform: perspective.scaled(1.0, 1.0, 1.0)
                ..rotateX(tiltDegree * pi / 180)
                ..rotateY(0.0)
                ..rotateZ(0.0),
              child: Row(
                children: [
                  Transform.rotate(
                    angle: 40,
                    child: Container(
                      height: 0.03125 * standardBarHeight,
                      width: 0.03125 * standardBarHeight,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        color: Theme.of(context).colorScheme.primary,
                        width: MediaQuery.of(context).size.width - 0.03125 * standardBarHeight,
                        height: 0.0078125 * standardBarHeight,
                      ),
                      Image.asset('assets/images/position-dark.png', height: 0.15625 * standardBarHeight),
                    ],
                  ),
                  Transform.rotate(
                    angle: 40,
                    child: Container(
                      height: 0.03125 * standardBarHeight,
                      width: 0.03125 * standardBarHeight,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
