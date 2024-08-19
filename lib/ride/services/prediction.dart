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
import 'package:priobike/settings/services/auth.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';

class PredictionProvider {
  /// The current best prediction.
  Prediction? prediction;

  /// The current best recommendation, calculated periodically.
  Recommendation? recommendation;

  /// The current best status.
  SGStatusData? status;

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

  /// The prediction service client.
  MqttServerClient? psClient;

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
    if (sg != null && !psClientConn) {
      // Driving toward a signal group, connect the clients.
      final settings = getIt<Settings>();
      final auth = await Auth.load(settings.city.selectedBackend(true));
      await psClient!
          .connect(auth.predictionServiceMQTTUsername, auth.predictionServiceMQTTPassword)
          .timeout(const Duration(seconds: 5));
      psClient!.updates!.listen(onPsData); // Needs to happen after connect!
    }

    bool unsubscribed = false;

    psClientConn = psClient!.connectionStatus?.state == MqttConnectionState.connected;
    if (subscribedSG != null && subscribedSG != sg) {
      // If we transition from one to another signal group, unsubscribe from the previous one.
      if (psClientConn) psClient?.unsubscribe(subscribedSG!.id);

      // Reset all values that were calculated for the previous signal group.
      prediction = null;
      recommendation = null;
      status = null;
      unsubscribed = true;
    }

    psClientConn = psClient!.connectionStatus?.state == MqttConnectionState.connected;
    if (sg == null) {
      // If the signal group is null, disconnect the clients.
      if (psClientConn) log.i("🛜🔋 No sg: disconnecting from Prediction brokers to save energy.");
      if (psClientConn) psClient?.disconnect();
    } else if (sg != subscribedSG || resubscribe) {
      // If the signal group is different from the previous one, subscribe to the new signal group.
      psClient?.subscribe(sg.id, MqttQos.atLeastOnce);
      // Launch a timer that will disconnect if no new prediction is arriving.
      disconnectTimer = Timer(const Duration(seconds: 5), () {
        if (prediction != null) return; // If a prediction arrived, don't disconnect.
        log.i("🛜🔋 No good prediction arrived: disconnecting from Prediction brokers to save energy.");
        psClient?.disconnect();
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
    final backend = getIt<Settings>().city.selectedBackend(true);
    // Get the backend that is currently selected.
    try {
      psClient = initClient(
        "PredictionService",
        backend.predictionServiceMQTTPath,
        backend.predictionServiceMQTTPort,
      );
      onConnected();
    } catch (e) {
      psClient = null;
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
        // Disconnect client
        log.i("🛜🔋 Disconnecting from broker to save energy.");
        psClient?.disconnect();
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
  }

  /// Reset the service.
  Future<void> reset() async {
    psClient?.disconnect();
    psClient = null;
    predictionServicePredictions.clear();
    recommendation = null;
    prediction = null;
    status = null;
    disconnectTimer?.cancel();
    disconnectTimer = null;
    resubscribeTimer?.cancel();
    resubscribeTimer = null;
  }
}
