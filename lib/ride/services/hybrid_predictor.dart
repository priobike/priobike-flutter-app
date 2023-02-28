import 'dart:async';

import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/interfaces/prediction.dart';
import 'package:priobike/ride/interfaces/prediction_component.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/ride/services/prediction_service.dart';
import 'package:priobike/ride/services/predictor.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/status/messages/sg.dart';

class HybridPredictor implements PredictionComponent {
  /// The current prediction.
  @override
  Prediction? get prediction =>
      currentMode == PredictionMode.usePredictionService ? predictionService?.prediction : predictor?.prediction;

  /// The current recommendation, calculated periodically.
  @override
  Recommendation? get recommendation => currentMode == PredictionMode.usePredictionService
      ? predictionService?.recommendation
      : predictor?.recommendation;

  /// A callback that gets executed when the parent provider should call the notifyListeners function.
  @override
  late final Function notifyListeners;

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  @override
  late final Function(SGStatusData)? onNewPredictionStatusDuringRide;

  HybridPredictor({
    required this.notifyListeners,
    required this.onNewPredictionStatusDuringRide,
  });

  /// Logger for this class.
  final log = Logger("Predictor");

  /// The predictions received during the ride, from the predictor.
  List<PredictorPrediction> get predictorPredictions => predictor?.predictorPredictions ?? [];

  /// The predictions received during the ride, from the prediction service.
  List<PredictionServicePrediction> get predictionServicePredictions =>
      predictionService?.predictionServicePredictions ?? [];

  /// The predictor component.
  Predictor? predictor;

  /// The prediction service component.
  PredictionService? predictionService;

  /// The currently used client used for the hybrid mode (predictionService or predictor) based on the current
  /// predictions of both.
  PredictionMode currentMode = PredictionMode.usePredictionService;

  /// The current SG (either selected by the user or by the current position on the route)
  Sg? currentSG;

  /// Subscribe to the signal group.
  @override
  bool selectSG(Sg? sg) {
    currentSG = sg;

    bool unsubscribed = false;

    if (predictionService != null) unsubscribed = predictionService!.selectSG(sg);
    if (predictor != null) unsubscribed = predictor!.selectSG(sg);

    return unsubscribed;
  }

  /// Establish a connection with the MQTT clients.
  @override
  Future<void> connectMQTTClient() async {
    // Hybrid mode -> connect both clients.
    predictionService = PredictionService(
      onConnected: onConnectedPredictionService,
      notifyListeners: update,
      onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRideWrapperPredictionService,
    );
    predictionService!.connectMQTTClient();
    predictor = Predictor(
      onConnected: onConnectedPredictor,
      notifyListeners: update,
      onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRideWrapperPredictor,
    );
    predictor!.connectMQTTClient();
  }

  /// A method that is called by the predictor or prediction service if the prediction changes.
  void update() {
    updateHybridMode();
    notifyListeners();
  }

  /// A wrapper for the onNewPredictionStatusDuringRide callback that only calls the original callback
  /// if we currently selected the prediction service in the hybrid mode or if, depending on the status, we switch the
  /// hybrid mode selection.
  void onNewPredictionStatusDuringRideWrapperPredictionService(SGStatusData data) {
    if (currentMode == PredictionMode.usePredictionService) {
      onNewPredictionStatusDuringRide?.call(data);
    }
  }

  /// A wrapper for the onNewPredictionStatusDuringRide callback that only calls the original callback
  /// if we currently selected the predictor in the hybrid mode or if, depending on the status, we switch the
  /// hybrid mode selection.
  void onNewPredictionStatusDuringRideWrapperPredictor(SGStatusData data) {
    if (currentMode == PredictionMode.usePredictor) {
      onNewPredictionStatusDuringRide?.call(data);
    }
  }

  /// Callback that gets called when the predictor client established a connection.
  void onConnectedPredictor() {
    predictor?.selectSG(currentSG);
  }

  /// Callback that gets called when the prediction service client established a connection.
  void onConnectedPredictionService() {
    predictionService?.selectSG(currentSG);
  }

  /// Update the hybrid mode based on some factors (decide what predictions to use (predictionService-predictions or
  /// predictor-predictions)).
  void updateHybridMode() {
    // If one has no "ok" prediction but the other has, use the other one.
    if (predictionService?.currentSGStatusData?.predictionState != SGPredictionState.ok &&
        predictor?.currentSGStatusData?.predictionState == SGPredictionState.ok) {
      if (currentMode != PredictionMode.usePredictor) {
        currentMode = PredictionMode.usePredictor;
        log.i("""Update hybrid prediction mode: Now using predictions from: ${currentMode.name}
          Reason: Prediction Service currently has no "ok" prediction, but the predictor has.""");
      }
      return;
    }
    if (predictionService?.currentSGStatusData?.predictionState == SGPredictionState.ok &&
        predictor?.currentSGStatusData?.predictionState != SGPredictionState.ok) {
      if (currentMode != PredictionMode.usePredictionService) {
        currentMode = PredictionMode.usePredictionService;
        log.i("""Update hybrid prediction mode: Now using predictions from: ${currentMode.name}
          Reason: Predictor currently has no "ok" prediction, but the prediction service has.""");
      }
      return;
    }
    // If based on the previous checks everything is fine with both prediction clients use the prediction service as
    // default.
    if (currentMode != PredictionMode.usePredictionService) {
      currentMode = PredictionMode.usePredictionService;
      log.i("""Update hybrid prediction mode: Now using predictions from: ${currentMode.name}
          Reason: Fallback to default.""");
    }
  }

  /// Stop the navigation.
  @override
  Future<void> stopNavigation() async {
    if (predictionService != null) predictionService!.stopNavigation();
    if (predictor != null) predictor!.stopNavigation();
  }

  /// Reset the service.
  @override
  Future<void> reset() async {
    await predictionService?.reset();
    predictionService = null;
    await predictor?.reset();
    predictor = null;
  }
}
