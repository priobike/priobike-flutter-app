import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:path/path.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:typed_data/typed_buffers.dart';

class Simulator {
  /// The logger.
  final log = Logger("Simulator");

  /// The mqtt client.
  MqttServerClient? client;

  /// The last time the current speed was sent to the simulator.
  DateTime? lastSend;

  /// The timer that is used to periodically calculate the prediction.
  Timer? calcTimer;

  double currentSpeed = 20.0;

  /// How often the current speed should be sent to the simulator.
  final Duration sendInterval = const Duration(seconds: 3);

  askForPermission() {
    // TODO: implement askForPermission
  }

  conntectWithDevice() {
    // TODO: implement conntectWithDevice
  }

  Future<void> sendCurrentSpeedToMQTT() async {
    if (client == null) await connectMQTTClient();

    const topic = "simulation";
    const qualityOfService = MqttQos.exactlyOnce;

    // Debug-Feature: Set the current speed to a random value between 20 and 40.
    final oldSpeed = currentSpeed;
    double newSpeed = 0.0;
    const minSpeed = 20.0;
    const maxSpeed = 40.0;
    while (newSpeed > maxSpeed || newSpeed < minSpeed || (newSpeed - oldSpeed).abs() > 2) {
      newSpeed = minSpeed + Random().nextDouble() * (maxSpeed - minSpeed);
    }
    currentSpeed = newSpeed;
    final positioning = getIt<Positioning>();
    positioning.setDebugSpeed(currentSpeed / 3.6);

    final String message = currentSpeed.toStringAsFixed(2); // FIXME: dummy data

    // convert message to byte array
    final Uint8List data = Uint8List.fromList(utf8.encode(message));
    Uint8Buffer dataBuffer = Uint8Buffer();
    dataBuffer.addAll(data);
    log.i("Sending $message to simulator.");

    // publish message
    try {
      client!.publishMessage(topic, qualityOfService, dataBuffer);
    } catch (e, stacktrace) {
      log.e("Error while sending $message to simulator: $e, $stacktrace");
    }
  }

  Future<void> connectMQTTClient() async {
    // Get the backend that is currently selected.
    final settings = getIt<Settings>();
    final clientId = 'priobike-app-${UniqueKey().toString()}';
    try {
      client = MqttServerClient(
        settings.backend.simulatorMQTTPath,
        clientId,
      );
      client!.logging(on: false);
      client!.keepAlivePeriod = 30;
      client!.secure = false;
      client!.port = settings.backend.simulatorMQTTPort;
      client!.autoReconnect = true;
      client!.resubscribeOnAutoReconnect = true;
      client!.onDisconnected = () => log.i("Simulator MQTT client disconnected");
      client!.onConnected = () => log.i("Simulator MQTT client connected");
      // client!.onSubscribed = (topic) => log.i("Simulator MQTT client subscribed to $topic");
      // client!.onUnsubscribed = (topic) => log.i("Simulator MQTT client unsubscribed from $topic");
      client!.onAutoReconnect = () => log.i("Simulator MQTT client auto reconnect");
      client!.onAutoReconnected = () => log.i("Simulator MQTT client auto reconnected");
      client!.setProtocolV311(); // Default Mosquitto protocol
      client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(client!.clientIdentifier)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      log.i("Connecting to Simulator MQTT broker.");
      await client!
          .connect(
            settings.backend.simulatorMQTTPublishUsername,
            settings.backend.simulatorMQTTPublishPassword,
          )
          .timeout(const Duration(seconds: 5));

      client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(client!.clientIdentifier)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);

      // Start the timer that updates the prediction once per second.
      calcTimer = Timer.periodic(sendInterval, (timer) {
        sendCurrentSpeedToMQTT();
      });
    } catch (e, stacktrace) {
      client = null;
      final hint = "Failed to connect the simulator MQTT client: $e, $stacktrace";
      log.e(hint);
      final ride = getIt<Ride>();
      if (ride.navigationIsActive) {
        // TODO: we can use this in the simulator as well, right??
        await Future.delayed(const Duration(seconds: 10));
        connectMQTTClient();
      } else {
        disconnectMQTTClient();
      }
    }
  }

  Future<void> disconnectMQTTClient() async {
    calcTimer?.cancel();
    calcTimer = null;
    if (client != null) {
      client!.disconnect();
      client = null;
      log.i("Disconnected from simulator MQTT broker.");
    }
  }
}
