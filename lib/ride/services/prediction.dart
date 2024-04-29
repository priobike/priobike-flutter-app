import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/interfaces/prediction.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';

class PredictionProvider {
  /// The current best prediction.
  Prediction? prediction;

  /// The current best recommendation, calculated periodically.
  Recommendation? recommendation;

  /// The current best status.
  SGStatusData? status;

  /// Whether the current recommendation uses the predictor failover.
  bool? usesPredictorFailover;

  /// A callback that gets executed when the parent provider should call the notifyListeners function.
  late final Function notifyListeners;

  /// A callback that gets executed when the client is connected.
  late final Function onConnected;

  PredictionProvider({
    required this.onConnected,
    required this.notifyListeners,
  });

  /// Logger for this class.
  final log = Logger("Prediction-Service");

  /// The predictions received during the ride, from the prediction service.
  final List<PredictionServicePrediction> predictionServicePredictions = [];

  /// The predictions received during the ride, from the predictor.
  final List<PredictorPrediction> predictorPredictions = [];

  /// The prediction service client.
  MqttServerClient? psClient;

  /// The predictor client.
  MqttServerClient? pClient;

  /// The currently subscribed signal group.
  Sg? subscribedSG;

  /// A timer used to resubscribe to the prediction MQTT brokers.
  /// This is used to save energy by disconnecting from the broker
  /// when no new predictions are expected.
  Timer? resubscribeTimer;

  /// A timer used to disconnect from the prediction MQTT brokers.
  /// This is used to save energy by disconnecting from the broker
  /// when no new predictions are expected.
  Timer? disconnectTimer;

  /// Subscribe to the signal group.
  Future<bool> selectSG(Sg? sg, {resubscribe = false}) async {
    // Don't leave the resubscribe timer running while we
    // are selecting a new signal group.
    resubscribeTimer?.cancel();
    resubscribeTimer = null;
    // Don't disconnect while we are selecting a new signal group.
    disconnectTimer?.cancel();
    disconnectTimer = null;

    var psClientConn = psClient?.connectionStatus?.state == MqttConnectionState.connected;
    var pClientConn = pClient?.connectionStatus?.state == MqttConnectionState.connected;
    if (sg != null && (!psClientConn || !pClientConn)) {
      // Driving toward a signal group, connect the clients.
      final settings = getIt<Settings>();
      await psClient!
          .connect(settings.backend.predictionServiceMQTTUsername, settings.backend.predictionServiceMQTTPassword)
          .timeout(const Duration(seconds: 5));
      psClient!.updates!.listen(onPsData); // Needs to happen after connect!
      await pClient!
          .connect(settings.backend.predictorMQTTUsername, settings.backend.predictorMQTTPassword)
          .timeout(const Duration(seconds: 5));
      pClient!.updates!.listen(onPData); // Needs to happen after connect!
    }

    bool unsubscribed = false;

    psClientConn = psClient!.connectionStatus?.state == MqttConnectionState.connected;
    pClientConn = pClient!.connectionStatus?.state == MqttConnectionState.connected;
    if (subscribedSG != null && subscribedSG != sg) {
      // If we transition from one to another signal group, unsubscribe from the previous one.
      if (psClientConn) psClient?.unsubscribe(subscribedSG!.id);
      if (pClientConn) pClient?.unsubscribe(subscribedSG!.id);

      // Reset all values that were calculated for the previous signal group.
      prediction = null;
      recommendation = null;
      usesPredictorFailover = null;
      status = null;
      unsubscribed = true;
    }

    psClientConn = psClient!.connectionStatus?.state == MqttConnectionState.connected;
    pClientConn = pClient!.connectionStatus?.state == MqttConnectionState.connected;
    if (sg == null) {
      // If the signal group is null, disconnect the clients.
      if (psClientConn || pClientConn) log.i("🛜🔋 No sg: disconnecting from Prediction brokers to save energy.");
      if (psClientConn) psClient?.disconnect();
      if (pClientConn) pClient?.disconnect();
    } else if (sg != subscribedSG || resubscribe) {
      // If the signal group is different from the previous one, subscribe to the new signal group.
      psClient?.subscribe(sg.id, MqttQos.atLeastOnce);
      pClient?.subscribe(sg.id, MqttQos.atLeastOnce);
      // Launch a timer that will disconnect if no new prediction is arriving.
      disconnectTimer = Timer(const Duration(seconds: 5), () {
        if (prediction != null) return; // If a prediction arrived, don't disconnect.
        log.i("🛜🔋 No good prediction arrived: disconnecting from Prediction brokers to save energy.");
        psClient?.disconnect();
        pClient?.disconnect();
      });
    } else {
      // If the signal group is the same as the previous one, do nothing.
    }

    subscribedSG = sg;

    return unsubscribed;
  }

  /// Recalculate the recommendation based on the current prediction.
  Future<void> recalculateRecommendation() async {
    if (prediction == null) {
      recommendation = null;
    } else {
      recommendation = await prediction!.calculateRecommendation();
    }
  }

  /// Establish a connection with the MQTT client.
  Future<void> connectMQTTClient() async {
    // Get the backend that is currently selected.
    try {
      final settings = getIt<Settings>();
      psClient = initClient(
        "PredictionService",
        settings.backend.predictionServiceMQTTPath,
        settings.backend.predictionServiceMQTTPort,
      );
      pClient = initClient(
        "Predictor",
        settings.backend.predictorMQTTPath,
        settings.backend.predictorMQTTPort,
      );
      onConnected();
    } catch (e) {
      psClient = null;
      pClient = null;
      final hint = "⚠️ Failed to connect the prediction MQTT client: $e";
      log.e(hint);
      final ride = getIt<Ride>();
      if (ride.navigationIsActive) {
        await Future.delayed(const Duration(seconds: 10));
        connectMQTTClient();
      }
    }
  }

  /// Init the prediction MQTT client.
  MqttServerClient initClient(String logName, String path, int port) {
    final clientId = 'priobike-app-${UniqueKey().toString()}'; // Random client ID.
    final client = MqttServerClient(path, clientId);
    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.secure = false;
    client.port = port;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    client.onDisconnected = () => log.i("🛜❌ $logName MQTT client disconnected");
    client.onConnected = () => log.i("🛜✅ $logName MQTT client connected");
    client.onSubscribed = (topic) => log.i("🫡✅ $logName MQTT client subscribed to $topic");
    client.onUnsubscribed = (topic) => log.i("🫡❌ $logName MQTT client unsubscribed from $topic");
    client.onAutoReconnect = () => log.i("🛜🔁 $logName MQTT client auto reconnect");
    client.onAutoReconnected = () => log.i("🛜🔁✅ $logName MQTT client auto reconnected");
    client.setProtocolV311(); // Default Mosquitto protocol
    client.connectionMessage =
        MqttConnectMessage().withClientIdentifier(client.clientIdentifier).startClean().withWillQos(MqttQos.atMostOnce);
    return client;
  }

  /// A callback that is executed when prediction service data arrives.
  Future<void> onPsData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      log.i("🛜→🚦 Received prediction from prediction service: $json");

      final prediction = PredictionServicePrediction.fromJson(json);
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
      // Don't unsubscribe just yet. We might get a new prediction soon.
      disconnectTimer?.cancel();
      disconnectTimer = null;
      // Calculate the time at which a new prediction will be published.
      final nextPredictionTime = prediction.startTime.add(const Duration(seconds: 60));
      // Unsubscribe while we don't expect a new prediction.
      if (nextPredictionTime.isAfter(DateTime.now())) {
        // Disconnect both clients
        log.i("🛜🔋 Disconnecting from both Prediction brokers to save energy.");
        psClient?.disconnect();
        pClient?.disconnect();
        // Schedule a reconnection.
        log.i("🛜🔁 Scheduling reconnection to the prediction MQTT broker at $nextPredictionTime");
        resubscribeTimer = Timer(nextPredictionTime.difference(DateTime.now()), () async {
          log.i("🛜🔁 Reconnecting to the prediction MQTT broker");
          await selectSG(subscribedSG, resubscribe: true);
        });
      }

      this.prediction = prediction;
      this.recommendation = recommendation;
      this.status = status;
      usesPredictorFailover = false;

      // Needs to be called before onNewPredictionStatusDuringRide() to ensure that (if used) the hybrid mode selects the
      // used prediction component before correctly.
      notifyListeners();
    }
  }

  /// A callback that is executed when predictor data arrives.
  Future<void> onPData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      log.i("🛜→🚦 Received prediction from predictor: $json");
      final prediction = PredictorPrediction.fromJson(json);
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
      // Don't unsubscribe just yet. We might get a new prediction soon.
      disconnectTimer?.cancel();
      disconnectTimer = null;

      this.prediction = prediction;
      this.recommendation = recommendation;
      this.status = status;
      usesPredictorFailover = true;

      // Note: for the predictor, we cannot disconnect,
      // as a new prediction may arrive at any point in time.

      // Needs to be called before onNewPredictionStatusDuringRide() to ensure that (if used) the hybrid mode selects the
      // used prediction component before correctly.
      notifyListeners();
    }
  }

  /// Stop the navigation.
  Future<void> stopNavigation() async {
    disconnectTimer?.cancel();
    disconnectTimer = null;
    resubscribeTimer?.cancel();
    resubscribeTimer = null;
    psClient?.disconnect();
    psClient = null;
    pClient?.disconnect();
    pClient = null;
  }

  /// Reset the service.
  Future<void> reset() async {
    psClient?.disconnect();
    psClient = null;
    pClient?.disconnect();
    pClient = null;
    predictionServicePredictions.clear();
    predictorPredictions.clear();
    recommendation = null;
    prediction = null;
    status = null;
    usesPredictorFailover = null;
    disconnectTimer?.cancel();
    disconnectTimer = null;
    resubscribeTimer?.cancel();
    resubscribeTimer = null;
  }
}
