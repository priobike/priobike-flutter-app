import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/interfaces/prediction_component.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';

class Predictor implements PredictionComponent {
  /// The current prediction.
  @override
  PredictorPrediction? prediction;

  /// The current recommendation, calculated periodically.
  @override
  Recommendation? recommendation;

  /// A callback that gets executed when the parent provider should call the notifyListeners function.
  @override
  late final Function notifyListeners;

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  @override
  late final Function(SGStatusData)? onNewPredictionStatusDuringRide;

  /// A callback that gets executed when the client is connected.
  late final Function onConnected;

  /// The current prediction mode.
  @override
  PredictionMode currentMode = PredictionMode.usePredictor;

  Predictor({
    required this.onConnected,
    required this.notifyListeners,
    required this.onNewPredictionStatusDuringRide,
  });

  /// Logger for this class.
  final log = Logger("Predictor");

  /// The predictions received during the ride, from the predictor.
  final List<PredictorPrediction> predictorPredictions = [];

  /// The timer that is used to periodically calculate the prediction.
  Timer? calcTimer;

  /// The prediction client.
  MqttServerClient? client;

  /// The currently subscribed signal group.
  Sg? subscribedSG;

  /// The status data of the current prediction.
  SGStatusData? currentSGStatusData;

  /// Subscribe to the signal group.
  @override
  bool selectSG(Sg? sg) {
    if (client == null) return false;

    bool unsubscribed = false;

    if (subscribedSG != null && subscribedSG != sg) {
      log.i("Unsubscribing from signal group ${subscribedSG?.id}");
      client?.unsubscribe(subscribedSG!.id);

      // Reset all values that were calculated for the previous signal group.
      prediction = null;
      recommendation = null;
      currentSGStatusData = null;
      unsubscribed = true;
    }

    if (sg != null && sg != subscribedSG) {
      log.i("Subscribing to signal group ${sg.id}");
      client?.subscribe(sg.id, MqttQos.atLeastOnce);
    }

    subscribedSG = sg;

    return unsubscribed;
  }

  /// Establish a connection with the MQTT client.
  @override
  Future<void> connectMQTTClient() async {
    // Get the backend that is currently selected.
    final settings = getIt<Settings>();
    final clientId = 'priobike-app-${UniqueKey().toString()}';
    try {
      client = MqttServerClient(
        settings.backend.predictorMQTTPath,
        clientId,
      );
      client!.logging(on: false);
      client!.keepAlivePeriod = 30;
      client!.secure = false;
      client!.port = settings.backend.predictorMQTTPort;
      client!.autoReconnect = true;
      client!.resubscribeOnAutoReconnect = true;
      client!.onDisconnected = () => log.i("Prediction MQTT client disconnected");
      client!.onConnected = () => log.i("Prediction MQTT client connected");
      client!.onSubscribed = (topic) => log.i("Prediction MQTT client subscribed to $topic");
      client!.onUnsubscribed = (topic) => log.i("Prediction MQTT client unsubscribed from $topic");
      client!.onAutoReconnect = () => log.i("Prediction MQTT client auto reconnect");
      client!.onAutoReconnected = () => log.i("Prediction MQTT client auto reconnected");
      client!.setProtocolV311(); // Default Mosquitto protocol
      client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(client!.clientIdentifier)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      log.i("Connecting to Prediction MQTT broker.");
      await client!
          .connect(
            settings.backend.predictorMQTTUsername,
            settings.backend.predictorMQTTPassword,
          )
          .timeout(const Duration(seconds: 5));
      client!.updates?.listen(onData);
      onConnected();
      // Start the timer that updates the prediction once per second.
      calcTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        calculateRecommendation();
      });
    } catch (e) {
      client = null;
      final hint = "Failed to connect the prediction MQTT client: $e";
      log.e(hint);
      final ride = getIt<Ride>();
      if (ride.navigationIsActive) {
        await Future.delayed(const Duration(seconds: 10));
        connectMQTTClient();
      }
    }
  }

  /// A callback that is executed when data arrives.
  Future<void> onData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      log.i("Received prediction from predictor: $json");
      prediction = PredictorPrediction.fromJson(json);
      calculateRecommendation();
      if (prediction != null) predictorPredictions.add(prediction!);
    }
  }

  Future<void> calculateRecommendation() async {
    // This will be executed if we fail somewhere.
    onFailure(String? reason) {
      if (reason != null) log.w("Failed to calculate predictor info: $reason");
      notifyListeners();
    }

    if (prediction == null) return onFailure(null); // Fail silently.

    recommendation = await prediction!.calculateRecommendation();

    // Set the prediction status of the current prediction.
    // Needs to be set after calculateRecommendation() because there the prediction!.predictionQuality gets calculated.
    // Needs to be set before notifyListeners() is called, because based on that (if used) the hybrid mode selects the used prediction component.
    currentSGStatusData = SGStatusData(
      statusUpdateTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      thingName:
          "hamburg/${prediction!.thingName}", // The prefix "hamburg/" is needed to match the naming schema of the status cache.
      predictionQuality: prediction!.predictionQuality,
      predictionTime: prediction!.referenceTime.millisecondsSinceEpoch ~/ 1000,
    );

    // Needs to be called before onNewPredictionStatusDuringRide() to ensure that (if used) the hybrid mode selects the
    // used prediction component before correctly.
    notifyListeners();

    // Notify that a new prediction status was obtained.
    onNewPredictionStatusDuringRide?.call(currentSGStatusData!);
  }

  /// Stop the navigation.
  @override
  Future<void> stopNavigation() async {
    calcTimer?.cancel();
    calcTimer = null;
    client?.disconnect();
    client = null;
  }

  /// Reset the service.
  @override
  Future<void> reset() async {
    client?.disconnect();
    client = null;
    predictorPredictions.clear();
    prediction = null;
    recommendation = null;
    currentSGStatusData = null;
  }
}