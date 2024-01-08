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

  /// The unique key to identify the device in the simulator. Remove the brackets and hash sign.
  final deviceId = UniqueKey().toString().replaceAll("[", "").replaceAll("]", "").replaceAll("#", "");

  /// Whether the device received a successful pair response from the simulator.
  bool pairSuccessful = false;

  /// The topic for the MQTT messages.
  final topic = "simulation";

  /// The last time a pair request was sent to the simulator.
  DateTime? lastSendPairRequest;

  /// Whether the device received a stop ride message from the simulator, indicating the simulation needs to be stopped.
  bool receivedStopRide = false;

  /// The subscription for the MQTT messages.
  Subscription? subscription;

  /// the Speed Sensor
  askForPermission() {
    // TODO: implement askForPermission
  }

  connectWithSensor() async {
    // TODO: implement connectWithDevice
  }

  sendTrafficLights() {
    // Format: App: {"type":"TrafficLight", "deviceID":"123", "tlID":"456", "longitude":"10.12345", "latitude":"50.12345", "bearing":"-80", "state":"red"}
    // TODO: implement sendTrafficLights
  }

  sendUpdateForTrafficLight() {
    // Format: App: {"type":"TrafficLightChange", "deviceID":"123", "tlID":"456", "state":"yellow", "timestamp":"..."}
    // TODO: implement sendUpdateForTrafficLight
  }

  Future<void> sendReadyPairRequest() async {
    if (client == null) await connectMQTTClient();

    // Only send a ready pair request every 10 seconds to avoid spamming the simulator.
    if (lastSendPairRequest != null && DateTime.now().difference(lastSendPairRequest!).inSeconds < 10) return;
    lastSendPairRequest = DateTime.now();

    const qualityOfService = MqttQos.atLeastOnce;

    Map<String, String> json = {};
    json['type'] = 'PairRequest';
    json['deviceID'] = deviceId;
    json['deviceName'] = 'Priobike';

    final String message = jsonEncode(json);

    await sendViaMQTT(
      message: message,
      qualityOfService: qualityOfService,
    );
  }

  /// Sends a start ride message to the simulator via MQTT.
  Future<void> sendStartRide() async {
    if (client == null) await connectMQTTClient();

    const qualityOfService = MqttQos.atLeastOnce;

    Map<String, String> json = {};
    json['type'] = 'StartRide';
    json['deviceID'] = deviceId;

    final String message = jsonEncode(json);

    await sendViaMQTT(
      message: message,
      qualityOfService: qualityOfService,
    );

    await sendTrafficLights();
  }

  /// Sends a ready pair request to the simulator via MQTT.
  Future<void> sendStopRide() async {
    if (client == null) await connectMQTTClient();

    const qualityOfService = MqttQos.atLeastOnce;

    Map<String, String> json = {};
    json['type'] = 'StopRide';
    json['deviceID'] = deviceId;

    final String message = jsonEncode(json);

    await sendViaMQTT(
      message: message,
      qualityOfService: qualityOfService,
    );
  }

  /// Send the current position to the simulator via MQTT.
  Future<void> sendCurrentPosition() async {
    if (client == null) await connectMQTTClient();

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
      qualityOfService: qualityOfService,
    );
  }

  /// Sends a message to the simulator via MQTT.
  Future<void> sendViaMQTT({required String message, required MqttQos qualityOfService}) async {
    if (client == null) await connectMQTTClient();

    // convert message to byte array
    final Uint8List data = Uint8List.fromList(utf8.encode(message));
    Uint8Buffer dataBuffer = Uint8Buffer();
    dataBuffer.addAll(data);
    log.i("Sending to simulator: $message");

    // publish message
    try {
      client!.publishMessage(topic, qualityOfService, dataBuffer);
    } catch (e, stacktrace) {
      log.e("Error while sending $message to simulator: $e, $stacktrace");
    }
  }

  /// A callback that is executed when data arrives.
  Future<void> onData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    if (messages == null) return;
    if (pairSuccessful) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      log.i("Received for simulator: $json");

      // Paring
      if (json['type'] == 'PairStart' && json['deviceID'] == deviceId) {
        pairSuccessful = true;
        log.i("Pairing with simulator successful.");

        // send pair confirm
        const qualityOfService = MqttQos.atLeastOnce;
        final String message = '{"type":"PairConfirm", "deviceID":"$deviceId"}';
        await sendViaMQTT(
          message: message,
          qualityOfService: qualityOfService,
        );
      }

      // Stop ride
      if (json['type'] == 'StopRide' && json['deviceID'] == deviceId) {
        log.i("Stop ride received from simulator.");
        receivedStopRide = true;
      }
    }
  }

  /// Connects the MQTT client to the simulator.
  Future<void> connectMQTTClient() async {
    resetVariables();

    // Get the backend that is currently selected.
    final settings = getIt<Settings>();

    // must be "app", otherwise the simulator won't accept the connection
    const clientId = 'app';
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
      client!.onSubscribed = (topic) => log.i("Simulator MQTT client subscribed to $topic");
      client!.onUnsubscribed = (topic) => log.i("Simulator MQTT client unsubscribed from $topic");
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

      client!.updates?.listen(onData);

      await sendReadyPairRequest();
      subscription = client?.subscribe(topic, MqttQos.atLeastOnce);
    } catch (e, stacktrace) {
      client = null;
      final hint = "Failed to connect the simulator MQTT client: $e, $stacktrace";
      log.e(hint);
      final ride = getIt<Ride>();
      if (ride.navigationIsActive) {
        // TODO: we can use this in the simulator as well, right??
        await Future.delayed(const Duration(seconds: 10));
        await connectMQTTClient();
      } else {
        disconnectMQTTClient();
      }
    }
  }

  /// Disconnects the MQTT client from the simulator.
  Future<void> disconnectMQTTClient() async {
    if (client != null) {
      await sendStopRide();
      client!.unsubscribe(topic);
      client!.disconnect();
      client = null;
      resetVariables();
      log.i("Disconnected from simulator MQTT broker.");
    }
  }

  /// Resets the variables for the simulation.
  resetVariables() {
    pairSuccessful = false;
    lastSendPairRequest = null;
    receivedStopRide = false;
    subscription = null;
  }
}
