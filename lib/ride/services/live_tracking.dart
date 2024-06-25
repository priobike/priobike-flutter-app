import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' hide Summary;
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/user.dart';
import 'package:typed_data/typed_buffers.dart';

class LiveTracking {
  /// The logger.
  final log = Logger("Live-Tracking");

  /// The MQTT topic where we send messages from the app to.
  static const topicApp = "priobike-app";

  /// The mqtt client.
  MqttServerClient? client;

  /// The unique key to identify the device in the live tracking MQTT.
  String? appId;

  /// Positioning service.
  Positioning? positioning;

  /// Make ready for the ride.
  Future<void> makeReadyForRide() async {
    positioning ??= getIt<Positioning>();
    positioning!.addListener(_sendCurrentPosition);
    appId = (await User.getOrCreateId()).replaceAll("#", "").replaceAll("+", "");
  }

  /// Dispose the live tracking service.
  void cleanUp() {
    if (positioning != null) positioning!.removeListener(_sendCurrentPosition);
    _disconnectMQTTClient();
  }

  /// Helper function to encode and send a message to the MQTT broker.
  Future<bool> _sendViaMQTT({required Map<String, dynamic> messageData, required MqttQos qualityOfService}) async {
    if (client == null) {
      final successfullyConnected = await _connectMQTTClient();
      if (!successfullyConnected) return false;
    }

    final String message = jsonEncode(messageData);

    // Convert message to byte array
    final Uint8List data = Uint8List.fromList(utf8.encode(message));
    Uint8Buffer dataBuffer = Uint8Buffer();
    dataBuffer.addAll(data);
    log.i("Sending to live tracking MQTT broker: $message");

    // Publish message
    try {
      final topic = "$topicApp/$appId";
      client!.publishMessage(topic, qualityOfService, dataBuffer);
      return true;
    } catch (e, stacktrace) {
      log.e("Error while sending $message to live tracking MQTT broker: $e, $stacktrace");
      return false;
    }
  }

  /// Connects the MQTT client to the broker.
  Future<bool> _connectMQTTClient() async {
    // Get the backend that is currently selected.
    final settings = getIt<Settings>();
    final backend = settings.city.selectedBackend(true);
    final clientId = "priobike-app-$appId";
    try {
      client = MqttServerClient(
        backend.liveTrackingMQTTPath,
        clientId,
      );
      client!.logging(on: false);
      client!.keepAlivePeriod = 30;
      client!.secure = false;
      client!.port = backend.liveTrackingMQTTPort;
      client!.autoReconnect = true;
      client!.resubscribeOnAutoReconnect = true;
      client!.onDisconnected = () => log.i("Simulator MQTT client disconnected");
      client!.onConnected = () => log.i("Simulator MQTT client connected");
      client!.onSubscribed = (topic) => log.i("Simulator MQTT client subscribed to $topic");
      client!.onUnsubscribed = (topic) => log.i("Simulator MQTT client unsubscribed from $topic");
      client!.onAutoReconnect = () => log.i("Simulator MQTT client auto reconnect");
      client!.onAutoReconnected = () => log.i("Simulator MQTT client auto reconnected");
      client!.setProtocolV311(); // Default Mosquitto protocol
      client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(client!.clientIdentifier)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      log.i("Connecting to live tracking MQTT broker.");
      await client!.connect().timeout(const Duration(seconds: 5));

      client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(client!.clientIdentifier)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);

      return true;
    } catch (e, stacktrace) {
      client = null;
      final hint = "Failed to connect the live tracking MQTT client: $e, $stacktrace";
      log.e(hint);
      return false;
    }
  }

  /// Send the current position to the live tracking via MQTT.
  /// Format: {"type":"NextCoordinate", "appID":"1234567890", "longitude":"10.12345",
  /// "latitude":"50.12345", "bearing":"-80"}
  Future<void> _sendCurrentPosition() async {
    if (client == null) await _connectMQTTClient();

    const qualityOfService = MqttQos.atMostOnce;

    final Positioning positioning = getIt<Positioning>();
    final Position position = positioning.lastPosition!;

    // if it is the first position, send the starting point of the route
    if (positioning.lastPosition == null) return;
    final longitude = position.longitude;
    final latitude = position.latitude;
    final heading = position.heading;
    final speed = position.speed;
    const type = 'NextCoordinate';

    Map<String, String> json = {};
    json['type'] = type;
    json['longitude'] = longitude.toString();
    json['latitude'] = latitude.toString();
    json['bearing'] = heading.toString();
    json['speed'] = speed.toString();

    await _sendViaMQTT(
      messageData: json,
      qualityOfService: qualityOfService,
    );
  }

  /// Disconnects the MQTT client from the live tracking MQTT broker.
  Future<void> _disconnectMQTTClient() async {
    if (client != null) {
      client!.disconnect();
      client = null;
      log.i("Disconnected from live tracking MQTT broker.");
    }
  }
}
