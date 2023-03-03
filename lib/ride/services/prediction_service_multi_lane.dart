import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/ride/services/ride_multi_lane.dart';
import 'package:priobike/routing/models/sg_multi_lane.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class PredictionServiceMultiLane {
  /// A callback that gets executed when the parent provider should call the notifyListeners function.
  late final Function notifyListeners;

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  late final Function(SGStatusData)? onNewPredictionStatusDuringRide;

  /// A callback that gets executed when the client is connected.
  late final Function onConnected;

  PredictionServiceMultiLane({
    required this.onConnected,
    required this.notifyListeners,
    required this.onNewPredictionStatusDuringRide,
  });

  /// Logger for this class.
  final log = Logger("Prediction-Service-Multi-Lane");

  /// The predictions received during the ride, from the prediction service.
  final List<PredictionServicePrediction> predictionServicePredictionsHistory = [];

  /// The timer that is used to periodically calculate the prediction.
  Timer? calcTimer;

  /// The prediction client.
  MqttServerClient? client;

  /// The currently subscribed signal groups.
  Set<SgMultiLane> subscribedSgs = {};

  /// The current predictions.
  Map<String, PredictionServicePrediction> predictions = {};

  /// The current recommendations, calculated periodically.
  Map<String, Recommendation> recommendations = {};

  /// Add another signal group.
  void addSg(SgMultiLane sg) {
    if (subscribedSgs.contains(sg)) return;
    if (client == null) return;
    client?.subscribe(sg.id, MqttQos.atLeastOnce);
    subscribedSgs.add(sg);
    log.i("Subscribing to signal group ${sg.id}");
  }

  /// Remove a signal group.
  void removeSg(SgMultiLane sg) {
    if (!subscribedSgs.contains(sg)) return;
    if (client == null) return;
    client?.unsubscribe(sg.id);
    subscribedSgs.remove(sg);
    if (predictions.containsKey(sg.id)) predictions.remove(sg.id);
    if (recommendations.containsKey(sg.id)) recommendations.remove(sg.id);
    log.i("Unsubscribing from signal group ${sg.id}");
  }

  /// Establish a connection with the MQTT client.
  Future<void> connectMQTTClient() async {
    // Get the backend that is currently selected.
    final settings = getIt<Settings>();
    final clientId = 'priobike-app-${UniqueKey().toString()}';
    try {
      client = MqttServerClient(
        settings.backend.predictionServiceMQTTPath,
        clientId,
      );
      client!.logging(on: false);
      client!.keepAlivePeriod = 30;
      client!.secure = false;
      client!.port = settings.backend.predictionServiceMQTTPort;
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
            settings.backend.predictionServiceMQTTUsername,
            settings.backend.predictionServiceMQTTPassword,
          )
          .timeout(const Duration(seconds: 5));
      client!.updates?.listen(onData);
      onConnected();
      // Start the timer that updates the prediction once per second.
      calcTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        update();
      });
    } catch (e, stackTrace) {
      client = null;
      final hint = "Failed to connect the prediction MQTT client: $e";
      log.e(hint);
      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: stackTrace, hint: hint);
      }
      final ride = getIt<RideMultiLane>();
      if (ride.navigationIsActive) {
        await Future.delayed(const Duration(seconds: 10));
        connectMQTTClient();
      }
    }
  }

  /// A callback that is executed when data arrives.
  Future<void> onData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    log.i("saerfserfewrferfer");
    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      log.i("Received prediction from prediction service: $json");
      final prediction = PredictionServicePrediction.fromJson(json);
      final recommendation = await prediction.calculateRecommendation();
      if (recommendation != null) {
        recommendations["hamburg/${prediction.signalGroupId}"] = recommendation;
      }
      predictionServicePredictionsHistory.add(prediction);
      predictions["hamburg/${prediction.signalGroupId}"] = prediction;

      SGStatusData sgStatusData = SGStatusData(
        statusUpdateTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        thingName:
            "hamburg/${prediction.signalGroupId}", // Same as thing name. The prefix "hamburg/" is needed to match the naming schema of the status cache.
        predictionQuality: prediction.predictionQuality,
        predictionTime: prediction.startTime.millisecondsSinceEpoch ~/ 1000,
      );

      notifyListeners();

      onNewPredictionStatusDuringRide?.call(sgStatusData);
    }
  }

  Future<void> update() async {
    // This will be executed if we fail somewhere.
    onFailure(reason) {
      log.w("Failed to calculate predictor info: $reason");
      notifyListeners();
    }

    if (predictions.isEmpty) return onFailure("No predictions available");

    for (var entry in predictions.entries) {
      final recommendation = await entry.value.calculateRecommendation();
      if (recommendation != null) {
        recommendations[entry.key] = recommendation;
      }
    }

    notifyListeners();
  }

  /// Stop the navigation.
  Future<void> stopNavigation() async {
    calcTimer?.cancel();
    calcTimer = null;
    client?.disconnect();
    client = null;
  }

  /// Reset the service.
  Future<void> reset() async {
    client?.disconnect();
    client = null;
    predictionServicePredictionsHistory.clear();
    subscribedSgs.clear();
    predictions.clear();
    recommendations.clear();
  }
}
