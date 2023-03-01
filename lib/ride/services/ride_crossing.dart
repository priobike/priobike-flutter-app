import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/models/crossing.dart';
import 'package:priobike/ride/services/crossings_prediction_service.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/status/messages/sg.dart';

/// The distance model.
const vincenty = Distance(roundResult: false);

class RideCrossing with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("RideCrossing");

  /// The threshold used for showing traffic light colors and speedometer colors
  static const qualityThreshold = 0.5;

  /// An optional callback that is called when a new recommendation is received.
  void Function(Crossing?)? onSelectNextCrossing;

  /// A boolean indicating if the navigation is active.
  var navigationIsActive = false;

  /// The currently selected route.
  Route? route;

  /// The current crossing, calculated periodically.
  Crossing? calcCurrentCrossing;

  /// The crossing that the user wants to see.
  Crossing? userSelectedCrossing;

  /// The current crossing index, calculated periodically.
  int? calcCurrentCrossingIndex;

  /// The current crossing index, selected by the user.
  int? userSelectedCrossingIndex;

  /// The calculated distance to the next crossing.
  double? calcDistanceToNextCrossing;

  /// The calculated distance to the next turn.
  double? calcDistanceToNextTurn;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The session id, set randomly by `startNavigation`.
  String? sessionId;

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  void Function(SGStatusData)? onNewPredictionStatusDuringRide;

  /// The wrapper-service for the used prediction mode.
  CrossingPredictionService? crossingPredictionService;

  /// Subscribe to the signal group.
  void selectCrossing(Crossing? crossing) {
    if (!navigationIsActive) return;
    bool? unsubscribed = crossingPredictionService?.selectCrossing(crossing);

    if (unsubscribed ?? false) calcDistanceToNextCrossing = null;

    onSelectNextCrossing?.call(calcCurrentCrossing);
  }

  /// Callback that gets called when the prediction component client established a connection.
  void onPredictionComponentClientConnected() {
    crossingPredictionService!.selectCrossing(userSelectedCrossing ?? calcCurrentCrossing);
  }

  /// Select the next signal group.
  /// Forward is step = 1, backward is step = -1.
  void jumpToCrossing({required int step}) {
    if (route == null) return;
    if (route!.signalGroups.isEmpty) return;
    if (userSelectedCrossingIndex == null && calcCurrentCrossingIndex == null) {
      // If there is no next signal group, select the first one if moving forward.
      // If moving backward, select the last one.
      userSelectedCrossingIndex = step > 0 ? 0 : route!.signalGroups.length - 1;
    } else if (userSelectedCrossingIndex == null) {
      // User did not manually select a signal group yet.
      userSelectedCrossingIndex = (calcCurrentCrossingIndex! + step) % route!.signalGroups.length;
    } else {
      // User manually selected a signal group.
      userSelectedCrossingIndex = (userSelectedCrossingIndex! + step) % route!.signalGroups.length;
    }
    userSelectedCrossing = route!.rideCrossings![userSelectedCrossingIndex!];
    selectCrossing(userSelectedCrossing);
    notifyListeners();
  }

  /// Unselect the current signal group.
  void unselectCrossing() {
    if (userSelectedCrossing == null) return;
    if (userSelectedCrossingIndex == null) return;
    userSelectedCrossing = null;
    userSelectedCrossingIndex = null;
    onSelectNextCrossing?.call(calcCurrentCrossing);
    selectCrossing(calcCurrentCrossing);
    notifyListeners();
  }

  /// Select a new route.
  Future<void> selectRoute(Route route) async {
    if (route.rideCrossings == null) {
      log.w("Route has no crossings, cannot start navigation.");
      return;
    }
    this.route = route;
    notifyListeners();
  }

  /// Start the navigation and connect the MQTT client.
  Future<void> startNavigation(Function(SGStatusData)? onNewPredictionStatusDuringRide) async {
    // Do nothing if the navigation has already been started.
    if (navigationIsActive) return;

    crossingPredictionService = CrossingPredictionService(
        onConnected: onPredictionComponentClientConnected,
        notifyListeners: notifyListeners,
        onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide);
    crossingPredictionService!.connectMQTTClient();

    // Mark that navigation is now active.
    sessionId = UniqueKey().toString();
    navigationIsActive = true;
    // Notify listeners of a new sg status update.
    this.onNewPredictionStatusDuringRide = onNewPredictionStatusDuringRide;
  }

  /// Update the position.
  Future<void> updatePosition() async {
    if (!navigationIsActive) return;

    final snap = getIt<Positioning>().snap;
    if (snap == null || route == null) return;

    // Calculate the distance to the next turn.
    // Traverse the segments and find the next turn, i.e. where the bearing changes > <x>°.
    const bearingThreshold = 15;
    var calcDistanceToNextTurn = 0.0;
    for (int i = snap.metadata.shortestDistanceIndex; i < route!.route.length - 1; i++) {
      final n1 = route!.route[i], n2 = route!.route[i + 1];
      final p1 = LatLng(n1.lat, n1.lon), p2 = LatLng(n2.lat, n2.lon);
      final b = vincenty.bearing(p1, p2); // [-180°, 180°]
      calcDistanceToNextTurn += vincenty.distance(p1, p2);
      if ((b - snap.bearing).abs() > bearingThreshold) break;
    }
    this.calcDistanceToNextTurn = calcDistanceToNextTurn;

    // Find the next crossing.
    Crossing? nextCrossing;
    int? nextCrossingIndex;
    double routeDistanceOfNextCrossing = double.infinity;
    outerLoop:
    for (int i = 0; i < route!.rideCrossings!.length; i++) {
      for (int j = 0; j < route!.rideCrossings![i].signalGroups.length; j++) {
        if (route!.rideCrossings![i].signalGroupsDistancesOnRoute[j] > snap.distanceOnRoute) {
          nextCrossing = route!.rideCrossings![i];
          nextCrossingIndex = i;
          routeDistanceOfNextCrossing = route!.rideCrossings![i].signalGroupsDistancesOnRoute[i];
          break outerLoop;
        }
      }
    }

    // Find the next crossing that is not connected on the route.
    double routeDistanceOfDisconnectedCrossing = double.infinity;
    for (int i = 0; i < route!.crossings.length; i++) {
      if (route!.crossingsDistancesOnRoute[i] > snap.distanceOnRoute) {
        if (route!.crossings[i].connected) continue;
        // The crossing is not connected, so we can use it.
        routeDistanceOfDisconnectedCrossing = route!.crossingsDistancesOnRoute[i];
        break;
      }
    }
    // If the next disconnected crossing is closer, don't select the next crossing just yet.
    if (routeDistanceOfDisconnectedCrossing < routeDistanceOfNextCrossing) {
      nextCrossing = null;
      nextCrossingIndex = null;
    }

    if (calcCurrentCrossing != nextCrossing) {
      calcCurrentCrossing = nextCrossing;
      calcCurrentCrossingIndex = nextCrossingIndex;
      // If the user didn't override the current crossing, select it.
      if (userSelectedCrossing == null) selectCrossing(nextCrossing);
    }
    // Calculate the distance to the next crossing.
    if (calcCurrentCrossingIndex != null) {
      calcDistanceToNextCrossing = routeDistanceOfNextCrossing - snap.distanceOnRoute;
    } else {
      calcDistanceToNextCrossing = null;
    }

    notifyListeners();
  }

  /// Stop the navigation.
  Future<void> stopNavigation() async {
    if (crossingPredictionService != null) crossingPredictionService!.stopNavigation();
    navigationIsActive = false;
    onNewPredictionStatusDuringRide = null; // Don't call the callback anymore.
    notifyListeners();
  }

  /// Reset the service.
  Future<void> reset() async {
    route = null;
    navigationIsActive = false;
    await crossingPredictionService?.reset();
    crossingPredictionService = null;
    calcCurrentCrossing = null;
    calcCurrentCrossingIndex = null;
    calcDistanceToNextCrossing = null;
    needsLayout = {};
    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
