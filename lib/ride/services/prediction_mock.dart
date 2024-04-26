import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/prediction.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/status/messages/sg.dart';

class MockPredictionProvider extends PredictionProvider {
  DateTime? localStartTime;
  DateTime? trackStartTime;
  bool initialized = false;
  Map<String, List<Timer>> newPredictionTimersBySgId = {};

  MockPredictionProvider(
      {required super.onConnected, required super.notifyListeners, required super.onNewPredictionStatusDuringRide}) {
    localStartTime = DateTime.now();
    initMockData();
  }

  Map<String, List<PredictionServicePrediction>> psPredictionsBySgId = {};
  Map<String, List<PredictorPrediction>> pPredictionsBySgId = {};

  void loadPredictionsP(dynamic metadata) {
    if (pPredictionsBySgId.isNotEmpty) return;

    final predictions = metadata["predictorPredictions"];
    for (final prediction in predictions) {
      final pPrediction = PredictorPrediction.fromJson(prediction);
      if (pPredictionsBySgId.containsKey(pPrediction.thingName)) {
        pPredictionsBySgId[pPrediction.thingName]!.add(pPrediction);
      } else {
        pPredictionsBySgId[pPrediction.thingName] = [pPrediction];
      }
    }
  }

  void loadPredictionsPS(dynamic metadata) {
    if (psPredictionsBySgId.isNotEmpty) return;

    final predictions = metadata["predictionServicePredictions"];
    for (final prediction in predictions) {
      final psPrediction = PredictionServicePrediction.fromJson(prediction);
      if (psPredictionsBySgId.containsKey(psPrediction.signalGroupId)) {
        psPredictionsBySgId[psPrediction.signalGroupId]!.add(psPrediction);
      } else {
        psPredictionsBySgId[psPrediction.signalGroupId] = [psPrediction];
      }
    }
  }

  Future<void> initMockData() async {
    String filecontents = await rootBundle.loadString("assets/tracks/hamburg/users/track.json");
    dynamic json = jsonDecode(filecontents);
    final metadata = json["metadata"];
    trackStartTime = DateTime.fromMillisecondsSinceEpoch(metadata["startTime"] + (0 * 1000));
    loadPredictionsP(metadata);
    loadPredictionsPS(metadata);
    initialized = true;
  }

  PredictionServicePrediction psPredictionWithNewTime(DateTime startTime, PredictionServicePrediction psPrediction) {
    final json = psPrediction.toJson();
    json["startTime"] = startTime.toIso8601String();
    return PredictionServicePrediction.fromJson(json);
  }

  PredictorPrediction pPredictionWithNewTime(DateTime referenceTime, PredictorPrediction pPrediction) {
    final json = pPrediction.toJson();
    json["referenceTime"] = referenceTime.toIso8601String();
    return PredictorPrediction.fromJson(json);
  }

  void subscribeP(DateTime trackTime, DateTime currentTime, String sgId) {
    sgId = sgId.replaceAll("hamburg/", "");
    if (!pPredictionsBySgId.containsKey(sgId)) {
      log.i("No predictor predictions for signal group: $sgId");
      return;
    }
    final predictions = pPredictionsBySgId[sgId]!;
    PredictorPrediction? initPrediction;
    int initTimeDiff = 0;
    for (final prediction in predictions) {
      final timeDiff = prediction.referenceTime.difference(trackTime).inSeconds;
      log.i("Found P prediction with time diff: $timeDiff");
      if (timeDiff <= 0) {
        initPrediction = prediction;
        initTimeDiff = timeDiff;
        continue;
      }
      if (timeDiff > 0) {
        super.log.i("Predictor: New mock prediction in $timeDiff seconds.");
        final newPredictionStartTime = currentTime.add(Duration(seconds: timeDiff));
        final predictionUpdated = pPredictionWithNewTime(newPredictionStartTime, prediction);
        final timer = Timer(Duration(seconds: timeDiff), () {
          onMockPData(predictionUpdated);
        });
        if (newPredictionTimersBySgId.containsKey(sgId)) {
          newPredictionTimersBySgId[sgId]!.add(timer);
        } else {
          newPredictionTimersBySgId[sgId] = [timer];
        }
      }
    }
    if (initPrediction != null) {
      final newPredictionStartTime = currentTime.add(Duration(seconds: initTimeDiff));
      final initPredictionUpdated = pPredictionWithNewTime(newPredictionStartTime, initPrediction);
      onMockPData(initPredictionUpdated);
    }
  }

  void subscribePS(DateTime trackTime, DateTime currentTime, String sgId) {
    sgId = sgId.replaceAll("hamburg/", "");
    if (!psPredictionsBySgId.containsKey(sgId)) {
      log.i("No prediction service predictions for signal group: $sgId");
      return;
    }
    final predictions = psPredictionsBySgId[sgId]!;
    PredictionServicePrediction? initPrediction;
    int initTimeDiff = 0;
    for (final prediction in predictions) {
      final timeDiff = prediction.startTime.difference(trackTime).inSeconds;
      log.i("Found PS prediction with time diff: $timeDiff");
      if (timeDiff <= 0) {
        initPrediction = prediction;
        initTimeDiff = timeDiff;
        continue;
      }
      if (timeDiff > 0) {
        super.log.i("Prediction Service: New mock prediction in $timeDiff seconds.");
        final newPredictionStartTime = currentTime.add(Duration(seconds: timeDiff));
        final predictionUpdated = psPredictionWithNewTime(newPredictionStartTime, prediction);
        final timer = Timer(Duration(seconds: timeDiff), () {
          onMockPsData(predictionUpdated);
        });
        if (newPredictionTimersBySgId.containsKey(sgId)) {
          newPredictionTimersBySgId[sgId]!.add(timer);
        } else {
          newPredictionTimersBySgId[sgId] = [timer];
        }
      }
    }
    if (initPrediction != null) {
      final newPredictionStartTime = currentTime.add(Duration(seconds: initTimeDiff));
      final initPredictionUpdated = psPredictionWithNewTime(newPredictionStartTime, initPrediction);
      onMockPsData(initPredictionUpdated);
    }
  }

  @override
  Future<bool> selectSG(Sg? sg, {resubscribe = false}) async {
    log.i("Selecting signal group: ${sg?.id}");

    bool unsubscribed = false;

    if (subscribedSG != null && subscribedSG != sg) {
      log.i("Unsubscribing from signal group: ${subscribedSG!.id}");
      final subscribedSGID = subscribedSG!.id.replaceAll("hamburg/", "");
      if (newPredictionTimersBySgId.containsKey(subscribedSGID)) {
        for (final timer in newPredictionTimersBySgId[subscribedSGID]!) {
          timer.cancel();
        }
        newPredictionTimersBySgId.remove(subscribedSGID);
      }

      // Reset all values that were calculated for the previous signal group.
      prediction = null;
      recommendation = null;
      usesPredictorFailover = null;
      status = null;
      unsubscribed = true;
    }

    if (sg == null) {
      // If the signal group is null, do nothing.
    } else if (sg != subscribedSG || resubscribe) {
      // If the signal group is different from the previous one, subscribe to the new signal group.
      log.i("Subscribing to signal group: ${sg.id}");
      final currentTime = DateTime.now();
      final secondsDriven = currentTime.difference(localStartTime!).inSeconds;
      final trackTime = trackStartTime!.add(Duration(seconds: secondsDriven));
      log.i(
          "Current Time: $currentTime - Local start time: $localStartTime - Track start time: $trackStartTime - Seconds driven: $secondsDriven - Track time: $trackTime");
      subscribeP(trackTime, currentTime, sg.id);
      subscribePS(trackTime, currentTime, sg.id);
    } else {
      // If the signal group is the same as the previous one, do nothing.
    }

    subscribedSG = sg;

    return unsubscribed;
  }

  @override
  Future<void> connectMQTTClient() async {
    // Do nothing.
  }

  @override
  Future<void> onPsData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    // Do nothing.
  }

  @override
  Future<void> onPData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    // Do nothing.
  }

  Future<void> onMockPsData(PredictionServicePrediction prediction) async {
    super.log.i("🛜→🚦 Received mock prediction from prediction service for sgId: ${prediction.signalGroupId}");

    predictionServicePredictions.add(prediction);

    final recommendation = await prediction.calculateRecommendation();
    // Set the prediction status of the current prediction. Needs to be set before notifyListeners() is called,
    // because based on that (if used) the hybrid mode selects the used prediction component.
    final status = SGStatusData(
      statusUpdateTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      // Same as thing name. The prefix "hamburg/" is needed to match the naming schema of the status cache.
      thingName: "hamburg/${prediction.signalGroupId}",
      predictionQuality: prediction.predictionQuality,
      predictionTime: prediction.startTime.millisecondsSinceEpoch ~/ 1000,
    );

    // Don't update the status if the prediction is not ok.
    if (status.predictionState != SGPredictionState.ok) return;

    this.prediction = prediction;
    this.recommendation = recommendation;
    this.status = status;
    usesPredictorFailover = false;

    // Needs to be called before onNewPredictionStatusDuringRide() to ensure that (if used) the hybrid mode selects the
    // used prediction component before correctly.
    notifyListeners();

    // Notify that a new prediction status was obtained.
    onNewPredictionStatusDuringRide?.call(status);
  }

  Future<void> onMockPData(PredictorPrediction prediction) async {
    super.log.i("🛜→🚦 Received mock prediction from predictor for sgId: ${prediction.thingName}");

    predictorPredictions.add(prediction);

    final recommendation = await prediction.calculateRecommendation();

    // Set the prediction status of the current prediction.
    // Needs to be set after calculateRecommendation() because there the prediction!.predictionQuality gets calculated.
    // Needs to be set before notifyListeners() is called, because based on that (if used) the hybrid mode selects the used prediction component.
    final status = SGStatusData(
      statusUpdateTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      // The prefix "hamburg/" is needed to match the naming schema of the status cache.
      thingName: "hamburg/${prediction.thingName}",
      predictionQuality: prediction.predictionQuality,
      predictionTime: prediction.referenceTime.millisecondsSinceEpoch ~/ 1000,
    );

    // Don't update the status if we have a prediction service prediction.
    if (this.prediction != null && usesPredictorFailover == false) return;
    // Don't update the status if the prediction is not ok.
    if (status.predictionState != SGPredictionState.ok) return;

    this.prediction = prediction;
    this.recommendation = recommendation;
    this.status = status;
    usesPredictorFailover = true;

    // Needs to be called before onNewPredictionStatusDuringRide() to ensure that (if used) the hybrid mode selects the
    // used prediction component before correctly.
    notifyListeners();

    // Notify that a new prediction status was obtained.
    onNewPredictionStatusDuringRide?.call(status);
  }

  @override
  Future<void> stopNavigation() async {
    await super.stopNavigation();
    for (final timers in newPredictionTimersBySgId.values) {
      for (final timer in timers) {
        timer.cancel();
      }
    }
    newPredictionTimersBySgId.clear();
  }

  @override
  Future<void> reset() async {
    predictionServicePredictions.clear();
    predictorPredictions.clear();
    recommendation = null;
    prediction = null;
    status = null;
    usesPredictorFailover = null;
  }
}
