import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/prediction_service_multi_lane.dart';
import 'package:priobike/routing/models/route_multi_lane.dart';
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

  /// Callback that gets called when the prediction component client established a connection.
  void onPredictionComponentClientConnected() {
    // crossingPredictionService!.selectCrossing(userSelectedCrossing ?? calcCurrentCrossing);
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

    final snap = getIt<Positioning>().snap;
    if (snap == null || route == null) return;

    // Update the current crossing.

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
    notifyListeners();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
