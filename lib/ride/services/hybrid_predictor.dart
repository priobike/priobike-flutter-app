import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/ride/services/prediction_service.dart';
import 'package:priobike/ride/services/predictor.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/status/messages/sg.dart';

class HybridPredictor implements PredictionComponent {
  /// Logger for this class.
  final log = Logger("Predictor");

  /// A boolean indicating if the navigation is active.
  var navigationIsActive = false;

  /// The timer that is used to periodically calculate the prediction.
  Timer? calcTimer;

  /// The predictor component.
  Predictor? predictor;

  /// The prediction service component.
  PredictionService? predictionService;

  /// The currently used client used for the hybrid mode (predictionService or predictor) based on the current
  /// predictions of both.
  PredictionMode hybridModePredictionMode = PredictionMode.usePredictionService;

  /// The current SG (either selected by the user or by the current position on the route)
  Sg? currentSG;

  /// The current prediction.
  @override
  dynamic prediction;

  /// The current recommendation, calculated periodically.
  @override
  Recommendation? recommendation;

  /// The currently subscribed signal group.
  @override
  Sg? subscribedSG;

  /// The predictions received during the ride, from the predictor.
  @override
  final List<PredictorPrediction> predictorPredictions = [];

  /// The predictions received during the ride, from the prediction service.
  @override
  final List<PredictionServicePrediction> predictionServicePredictions = [];

  /// A callback that gets executed when the client is connected.
  @override
  late final Function onConnected;

  /// A callback that gets executed when the parent provider should call the notifyListeners function.
  @override
  late final Function notifyListeners;

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  @override
  void Function(SGStatusData)? onNewPredictionStatusDuringRide;

  HybridPredictor(
      {required this.onConnected, required this.notifyListeners, required this.onNewPredictionStatusDuringRide});

  /// Subscribe to the signal group.
  @override
  void selectSG(Sg? sg) {
    currentSG = sg;
    if (!navigationIsActive) return;

    if (predictionService != null) predictionService!.selectSG(sg);
    if (predictor != null) predictor!.selectSG(sg);
  }

  /// Establish a connection with the MQTT client.
  @override
  Future<void> connectMQTTClient(BuildContext context) async {
    // Hybrid mode -> connect both clients.
    predictionService = PredictionService(
      onConnected: onConnected,
      notifyListeners: update,
      onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide,
    );
    predictionService!.connectMQTTClient(context);
    predictionService!.navigationIsActive = true;
    predictor = Predictor(
      onConnected: onConnected,
      notifyListeners: update,
      onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide,
    );
    predictor!.connectMQTTClient(context);
    predictor!.navigationIsActive = true;
  }

  /// A wrapper for the notifyListeners() method used to update the hybrid mode.
  void update() {
    updateHybridMode();
    notifyListeners();
  }

  /// Set the properties with respect to the chosen mode.
  setMode(PredictionMode predictionMode) {
    if (predictionMode == PredictionMode.usePredictionService) {
      prediction = predictionService?.prediction;
      recommendation = predictionService?.recommendation;
      subscribedSG = predictionService?.subscribedSG;
    } else if (predictionMode == PredictionMode.usePredictor) {
      prediction = predictor?.prediction;
      recommendation = predictor?.recommendation;
      subscribedSG = predictor?.subscribedSG;
    }
  }

  /// Update the hybrid mode based on some factors (decide what predictions to use (predictionService-predictions or
  /// predictor-predictions)).
  void updateHybridMode() {
    // Basic availability checks.
    if (predictionService == null || predictor == null) return;
    if (predictionService?.client == null || predictor?.client == null) return;
    // If one is currently not connected use the other one.
    if (predictionService?.client == null || predictionService!.subscribedSG == null) {
      if (hybridModePredictionMode != PredictionMode.usePredictor) {
        hybridModePredictionMode = PredictionMode.usePredictor;
        setMode(hybridModePredictionMode);
        log.i("""Update hybrid prediction mode: Now using predictions from: ${hybridModePredictionMode.name}
          Reason: Prediction service is not ${predictionService?.client == null ? "connected." : "subscribed."}""");
      }
      return;
    }
    if (predictor?.client == null || predictor!.subscribedSG == null) {
      if (hybridModePredictionMode != PredictionMode.usePredictionService) {
        hybridModePredictionMode = PredictionMode.usePredictionService;
        setMode(hybridModePredictionMode);
        log.i("""Update hybrid prediction mode: Now using predictions from: ${hybridModePredictionMode.name}
          Reason: Predictor is not ${predictor?.client == null ? "connected." : "subscribed."}""");
      }
      return;
    }
    // If one is currently subscribed to the wrong signal group use the other one.
    if (predictionService!.subscribedSG != predictor!.subscribedSG) {
      if (currentSG == null) return;
      if (predictionService!.subscribedSG!.id != currentSG!.id && predictor!.subscribedSG!.id == currentSG!.id) {
        if (hybridModePredictionMode != PredictionMode.usePredictor) {
          hybridModePredictionMode = PredictionMode.usePredictor;
          setMode(hybridModePredictionMode);
          log.i("""Update hybrid prediction mode: Now using predictions from: ${hybridModePredictionMode.name}
          Reason: Prediction service currently subscribes to the wrong SG.""");
        }
        return;
      }
      if (predictionService!.subscribedSG!.id == currentSG!.id && predictor!.subscribedSG!.id != currentSG!.id) {
        if (hybridModePredictionMode != PredictionMode.usePredictionService) {
          hybridModePredictionMode = PredictionMode.usePredictionService;
          setMode(hybridModePredictionMode);
          log.i("""Update hybrid prediction mode: Now using predictions from: ${hybridModePredictionMode.name}
          Reason: Predictor currently subscribes to the wrong SG.""");
        }
        return;
      }
    }
    // If based on the previous checks everything is fine with both prediction clients use the prediction service as
    // default.
    if (hybridModePredictionMode != PredictionMode.usePredictionService) {
      setMode(hybridModePredictionMode);
      log.i("""Update hybrid prediction mode: Now using predictions from: ${hybridModePredictionMode.name}
          Reason: Fallback to default.""");
      hybridModePredictionMode = PredictionMode.usePredictionService;
    }
  }

  /// Stop the navigation.
  @override
  Future<void> stopNavigation() async {
    calcTimer?.cancel();
    calcTimer = null;
    if (predictionService != null) predictionService!.stopNavigation();
    if (predictor != null) predictor!.stopNavigation();
    navigationIsActive = false;
  }

  /// Reset the service.
  @override
  Future<void> reset() async {
    navigationIsActive = false;
    if (predictionService != null) predictionService!.reset();
    if (predictor != null) predictor!.reset();
    prediction = null;
    recommendation = null;
  }
}
