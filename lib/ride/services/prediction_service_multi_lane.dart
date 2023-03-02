import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
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
  final log = Logger("Crossing-Prediction-Service");

  /// The predictions received during the ride, from the prediction service.
  final List<PredictionServicePrediction> predictionServicePredictions = [];

  /// The timer that is used to periodically calculate the prediction.
  Timer? calcTimer;

  /// The prediction client.
  MqttServerClient? client;

  /// The currently subscribed crossing.
  Crossing? subscribedCrossing;

  /// Subscribe to the signal groups of the current crossing.
  bool selectCrossing(Crossing? crossing) {
    if (client == null) return false;

    bool unsubscribed = false;

    if (subscribedCrossing != null && subscribedCrossing != crossing) {
      log.i("Unsubscribing from signal groups");
      for (final sg in subscribedCrossing!.signalGroups) {
        client?.unsubscribe(sg.id);
      }

      // Reset all values that were calculated for the previous signal group.
      subscribedCrossing?.onUnselected();
      subscribedCrossing = null;
      unsubscribed = true;
    }

    if (crossing != null && crossing != subscribedCrossing) {
      log.i("Subscribing to signal groups");
      for (final sg in crossing.signalGroups) {
        client?.subscribe(sg.id, MqttQos.atLeastOnce);
      }
    }

    subscribedCrossing = crossing;
    if (subscribedCrossing != null) {
      subscribedCrossing!.onSelected(notifyListeners, onNewPredictionStatusDuringRide);
    }

    return unsubscribed;
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
        subscribedCrossing?.update();
      });
    } catch (e, stackTrace) {
      client = null;
      final hint = "Failed to connect the prediction MQTT client: $e";
      log.e(hint);
      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: stackTrace, hint: hint);
      }
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
      log.i("Received prediction from prediction service: $json");
      final prediction = PredictionServicePrediction.fromJson(json);
      subscribedCrossing?.addPrediction(prediction);
      subscribedCrossing?.calculateRecommendation(prediction);
      predictionServicePredictions.add(prediction);
    }
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
    predictionServicePredictions.clear();
    subscribedCrossing = null;
  }
}
