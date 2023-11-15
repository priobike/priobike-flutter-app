import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
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

  /// The unique key to identify the device in the simulator.
  final deviceId = UniqueKey().toString().replaceAll("[", "").replaceAll("]", "").replaceAll("#", "");

  askForPermission() {
    // TODO: implement askForPermission
  }

  conntectWithSensor() {
    // TODO: implement conntectWithDevice
  }

  /// Sends a ready pair request to the simulator via MQTT.
  Future<void> sendReadyPairRequest() async {
    if (client == null) await connectMQTTClient();

    const topic = "simulation";
    const qualityOfService = MqttQos.atLeastOnce;

    Map<String, String> json = {};
    json['type'] = 'ReadyPairRequest';
    json['deviceID'] = deviceId;

    final String message = jsonEncode(json);

    await sendViaMQTT(
      message: message,
      topic: topic,
      qualityOfService: qualityOfService,
    );
    // TODO: muss ich hier noch irgendwie auf eine Antwort warten??
  }

  /// Send the current position to the simulator via MQTT.
  Future<void> sendCurrentPosition() async {
    if (client == null) await connectMQTTClient();

    const topic = "simulation";
    const qualityOfService = MqttQos.atMostOnce;

    final Positioning positioning = getIt<Positioning>();
    final position = positioning.lastPosition;
    if (position == null) return;
    final longitude = position.longitude;
    final latitude = position.latitude;
    final heading = position.heading;

    // Format:
    // {"type":"NextCoordinate", "deviceID":"1234567890", "longitude":"10.
    // 12345", "latitude":"50.12345", "bearing":"-80"}

    Map<String, String> json = {};
    json['type'] = 'NextCoordinate';
    json['deviceID'] = deviceId;
    json['longitude'] = longitude.toString();
    json['latitude'] = latitude.toString();
    json['bearing'] = heading.toString();

    final String message = jsonEncode(json);

    await sendViaMQTT(
      message: message,
      topic: topic,
      qualityOfService: qualityOfService,
    );
  }

  /// Sends a message to the simulator via MQTT.
  Future<void> sendViaMQTT({required String message, required String topic, required MqttQos qualityOfService}) async {
    if (client == null) await connectMQTTClient();

    // convert message to byte array
    final Uint8List data = Uint8List.fromList(utf8.encode(message));
    Uint8Buffer dataBuffer = Uint8Buffer();
    dataBuffer.addAll(data);
    log.i("Sending $message from $deviceId to simulator.");

    // publish message
    try {
      client!.publishMessage(topic, qualityOfService, dataBuffer);
    } catch (e, stacktrace) {
      log.e("Error while sending $message to simulator: $e, $stacktrace");
    }
  }

  /// Connects the MQTT client to the simulator.
  Future<void> connectMQTTClient() async {
    // Get the backend that is currently selected.
    final settings = getIt<Settings>();
    final clientId = 'priobike-app-${deviceId.toString()}';
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

      await sendReadyPairRequest();
      // TODO: implement MQTT handshake
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
    if (client != null) {
      client!.disconnect();
      client = null;
      log.i("Disconnected from simulator MQTT broker.");
    }
  }
}
