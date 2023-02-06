import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/messages/observations.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class Datastream with ChangeNotifier {
  /// Logger for this class.
  final log = Logger('Datastream');

  /// The mqtt client.
  MqttServerClient? client;

  /// The currently active signal group.
  Sg? sg;

  /// The timer that updates the history every second.
  Timer? timer;

  /// The current value for the car detector.
  DetectorCarObservation? detectorCar;

  /// The current value for the cyclists detector.
  DetectorCyclistsObservation? detectorCyclists;

  /// The current value for the cycle second.
  CycleSecondObservation? cycleSecond;

  /// The current value for the primary signal.
  PrimarySignalObservation? primarySignal;

  /// The last 180 seconds of the primary signal.
  final primarySignalHistory = List<PrimarySignalObservation?>.filled(180, null);

  /// The current value for the signal program.
  SignalProgramObservation? signalProgram;

  /// The set of current subscriptions.
  final Set<String> subscriptions = {};

  /// Get the topic for a datastream.
  static String? topic(String? datastreamId) =>
      datastreamId == null ? null : "v1.1/Datastreams($datastreamId)/Observations";

  /// Unsubscribe from a datastream.
  void unsubscribe(String? datastreamId) {
    if (datastreamId == null || client == null) return;
    final t = topic(datastreamId)!;
    client?.unsubscribe(t);
    subscriptions.remove(t);
    notifyListeners();
  }

  /// Subscribe to a datastream.
  void subscribe(String? datastreamId) {
    if (datastreamId == null || client == null) return;
    final t = topic(datastreamId)!;
    client?.subscribe(t, MqttQos.exactlyOnce);
    subscriptions.add(t);
    notifyListeners();
  }

  /// Connect the mqtt client.
  Future<void> connect(BuildContext context) async {
    try {
      // Get the backend that is currently selected.
      final backend = Provider.of<Settings>(context, listen: false).backend;
      client = MqttServerClient(backend.frostMQTTPath, 'priobike-app-${UniqueKey().toString()}');
      client!.logging(on: false);
      client!.keepAlivePeriod = 30;
      client!.secure = false;
      client!.port = backend.frostMQTTPort;
      client!.autoReconnect = true;
      client!.resubscribeOnAutoReconnect = true;
      client!.onDisconnected = () => log.i("MQTT client disconnected");
      client!.onConnected = () => log.i("MQTT client connected");
      client!.onSubscribed = (topic) => log.i("MQTT client subscribed to $topic");
      client!.onUnsubscribed = (topic) => log.i("MQTT client unsubscribed from $topic");
      client!.onAutoReconnect = () => log.i("MQTT client auto reconnect");
      client!.onAutoReconnected = () => log.i("MQTT client auto reconnected");
      client!.setProtocolV311();
      client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(client!.clientIdentifier)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      log.i("Connecting to MQTT broker ${backend.frostMQTTPath}:${backend.frostMQTTPort}");
      await client!.connect().timeout(const Duration(seconds: 5));
      client!.updates?.listen(onData);

      // Init the timer that updates the history every second.
      timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          // Shift the history to the left.
          for (var i = 0; i < primarySignalHistory.length - 1; i++) {
            primarySignalHistory[i] = primarySignalHistory[i + 1];
          }
          // Add the current value to the history.
          primarySignalHistory[primarySignalHistory.length - 1] = primarySignal;
          // If we have a primary signal, update the history by the phenomenon time.
          if (primarySignal != null) {
            final diff = DateTime.now().difference(primarySignal!.phenomenonTime);
            final startIndex = max(primarySignalHistory.length - 1 - diff.inSeconds, 0);
            for (var i = startIndex; i < primarySignalHistory.length; i++) {
              primarySignalHistory[i] = primarySignal;
            }
          }
          notifyListeners();
        },
      );
    } catch (e) {
      client = null;
      log.w("Failed to connect the Frost MQTT client: $e");
    }
  }

  /// A callback that is executed when data arrives.
  Future<void> onData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      // Get the result of the observation.
      final json = jsonDecode(data);
      // Match the result to the correct datastream.
      try {
        if (message.topic == topic(sg?.datastreamDetectorCar)) {
          detectorCar = DetectorCarObservation.fromJson(json);
          log.i("MQTT: Received detectorCar: ${detectorCar!.pct}%");
        } else if (message.topic == topic(sg?.datastreamDetectorCyclists)) {
          detectorCyclists = DetectorCyclistsObservation.fromJson(json);
          log.i("MQTT: Received detectorCyclists: ${detectorCyclists!.pct}%");
        } else if (message.topic == topic(sg?.datastreamCycleSecond)) {
          cycleSecond = CycleSecondObservation.fromJson(json);
          log.i("MQTT: Received cycleSecond: ${cycleSecond!.second}s");
        } else if (message.topic == topic(sg?.datastreamPrimarySignal)) {
          primarySignal = PrimarySignalObservation.fromJson(json);
          log.i("MQTT: Received primarySignal: ${primarySignal!.state.name}");
        } else if (message.topic == topic(sg?.datastreamSignalProgram)) {
          signalProgram = SignalProgramObservation.fromJson(json);
          log.i("MQTT: Received signalProgram: #${signalProgram!.program}");
        }
        notifyListeners();
      } catch (e) {
        log.e("MQTT: Error while parsing message: $e");
      }
    }
  }

  /// Connect the datastream to the selected sg.
  Future<void> select({required Sg? sg}) async {
    // Verify that the sg is different.
    if (this.sg?.id == sg?.id) return;

    // If we have an old sg, we need to unsubscribe from it.
    if (this.sg != null) {
      detectorCar = null;
      unsubscribe(this.sg?.datastreamDetectorCar);
      detectorCyclists = null;
      unsubscribe(this.sg?.datastreamDetectorCyclists);
      cycleSecond = null;
      unsubscribe(this.sg?.datastreamCycleSecond);
      primarySignal = null;
      for (var i = 0; i < primarySignalHistory.length; i++) {
        primarySignalHistory[i] = null;
      }
      unsubscribe(this.sg?.datastreamPrimarySignal);
      signalProgram = null;
      unsubscribe(this.sg?.datastreamSignalProgram);
    }

    // Set the new sg.
    this.sg = sg;

    // Subscribe to the new sg, if it exists.
    if (this.sg != null) {
      subscribe(this.sg?.datastreamDetectorCar);
      subscribe(this.sg?.datastreamDetectorCyclists);
      subscribe(this.sg?.datastreamCycleSecond);
      subscribe(this.sg?.datastreamPrimarySignal);
      subscribe(this.sg?.datastreamSignalProgram);
    }
  }

  /// Disconnect and dispose the mqtt client.
  Future<void> disconnect() async {
    if (client != null) {
      for (final t in subscriptions) {
        client?.unsubscribe(t);
      }
      client?.disconnect();
      client = null;
    }
    subscriptions.clear();
    timer?.cancel();
    timer = null;
    for (var i = 0; i < primarySignalHistory.length; i++) {
      primarySignalHistory[i] = null;
    }
  }
}
