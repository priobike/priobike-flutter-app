import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning_multi_lane.dart';
import 'package:priobike/ride/services/prediction_service_multi_lane.dart';
import 'package:priobike/routing/models/route_multi_lane.dart';
import 'package:priobike/routing/models/sg_multi_lane.dart';
import 'package:priobike/status/messages/sg.dart';

/// The distance model.
const vincenty = Distance(roundResult: false);

class RideMultiLane with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("RideMultiLane");

  /// The threshold used for showing traffic light colors and speedometer colors
  static const qualityThreshold = 0.5;

  /// A boolean indicating if the navigation is active.
  var navigationIsActive = false;

  /// The currently selected route.
  RouteMultiLane? route;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The session id, set randomly by `startNavigation`.
  String? sessionId;

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  void Function(SGStatusData)? onNewPredictionStatusDuringRide;

  /// The wrapper-service for the used prediction mode.
  PredictionServiceMultiLane? predictionServiceMultiLane;

  /// Current signal groups.
  Set<SgMultiLane> currentSignalGroups = {};

  /// The distances to the current signal groups (in meter).
  Map<String, double> distancesToCurrentSignalGroups = {};

  /// The distance on the route before a signal group from which it is considered for the predictions and
  /// recommendations.
  static const preDistance = 500.0;

  /// Callback that gets called when the prediction component client established a connection.
  void onPredictionComponentClientConnected() {
    for (final signalGroup in currentSignalGroups) {
      predictionServiceMultiLane!.addSg(signalGroup);
    }
  }

  /// Select a new route.
  Future<void> selectRoute(RouteMultiLane route) async {
    this.route = route;
    notifyListeners();
  }

  /// Start the navigation and connect the MQTT client.
  Future<void> startNavigation(Function(SGStatusData)? onNewPredictionStatusDuringRide) async {
    // Do nothing if the navigation has already been started.
    if (navigationIsActive) return;

    predictionServiceMultiLane = PredictionServiceMultiLane(
        onConnected: onPredictionComponentClientConnected,
        notifyListeners: notifyListeners,
        onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide);
    predictionServiceMultiLane!.connectMQTTClient();

    // Mark that navigation is now active.
    sessionId = UniqueKey().toString();
    navigationIsActive = true;
    // Notify listeners of a new sg status update.
    this.onNewPredictionStatusDuringRide = onNewPredictionStatusDuringRide;
  }

  /// Update the position.
  Future<void> updatePosition() async {
    if (!navigationIsActive) return;

    final snap = getIt<PositioningMultiLane>().snap;
    if (snap == null || route == null) return;

    for (final sg in route!.signalGroups) {
      final absSgDistance = route!.path.distance * sg.distanceOnRoute;
      // Signal group is behind the user (leave it until
      // shortly behind the user such that it is still shown to the user
      // when being close to the SG).
      if (absSgDistance < snap.distanceOnRoute - 20) {
        final removed = currentSignalGroups.remove(sg);
        distancesToCurrentSignalGroups.remove(sg.id);
        if (removed) {
          predictionServiceMultiLane!.removeSg(sg);
        }
        continue;
      }

      // Signal group is too far in front of the user.
      if (absSgDistance - preDistance > snap.distanceOnRoute) {
        final removed = currentSignalGroups.remove(sg);
        distancesToCurrentSignalGroups.remove(sg.id);
        if (removed) {
          predictionServiceMultiLane!.removeSg(sg);
        }
        continue;
      }
      log.i("Signal group ${sg.id} is in range.");
      distancesToCurrentSignalGroups[sg.id] = absSgDistance - snap.distanceOnRoute;
      final added = currentSignalGroups.add(sg);
      if (added) {
        predictionServiceMultiLane!.addSg(sg);
      }
    }

    notifyListeners();
  }

  /// Stop the navigation.
  Future<void> stopNavigation() async {
    if (predictionServiceMultiLane != null) predictionServiceMultiLane!.stopNavigation();
    navigationIsActive = false;
    onNewPredictionStatusDuringRide = null; // Don't call the callback anymore.
    notifyListeners();
  }

  /// Reset the service.
  Future<void> reset() async {
    route = null;
    navigationIsActive = false;
    await predictionServiceMultiLane?.reset();
    predictionServiceMultiLane = null;
    needsLayout = {};
    currentSignalGroups = {};
    distancesToCurrentSignalGroups = {};
    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
