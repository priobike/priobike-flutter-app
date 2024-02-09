import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:typed_data/typed_buffers.dart';

class Simulator with ChangeNotifier {
  ///
  /// - Positioing (new Position)
  /// - Ride (Ampeln)

  /// The logger.
  final log = Logger("Simulator");

  /// The topic for the MQTT messages.
  static const topic = "simulation";

  /// The mqtt client.
  MqttServerClient? client;

  /// Current route. Used to only send a route if it changed.
  Route? currentRoute;

  /// The current state of the next signal group. Used to only send a state if it changed.
  String? currentSGState;

  // The last send signal group id. Used to only send an SG if it changed.
  String? currentSGId;

  /// The unique key to identify the device in the simulator. Remove the brackets and hash sign.
  final deviceId = UniqueKey().toString().replaceAll("[", "").replaceAll("]", "").replaceAll("#", "");

  /// The last time a pair request was sent to the simulator.
  DateTime? lastSentPairRequest;

  /// If the simulator is paired.
  bool paired = false;

  /// Positioning service.
  Positioning? positioning;

  /// Routing service.
  Routing? routing;

  /// Ride service.
  Ride? ride;

  /// Make ready for the ride.
  Future<void> makeReadyForRide() async {
    positioning = getIt<Positioning>();
    positioning!.addListener(processPositioningUpdates);
    routing = getIt<Routing>();
    routing!.addListener(processRoutingUpdates);
    ride = getIt<Ride>();
    ride!.addListener(processRideUpdates);
  }

  /// Process positioning updates.
  void processPositioningUpdates() {
    if (!ride!.navigationIsActive) return;
    sendCurrentPosition();
  }

  /// Process routing updates.
  void processRoutingUpdates() {
    if (routing!.selectedRoute != currentRoute) {
      currentRoute = routing!.selectedRoute;
      sendRouteData();
      sendSignalGroups();
    }
  }

  /// Process ride updates.
  void processRideUpdates() {
    if (!ride!.navigationIsActive) return;
    sendSignalGroupUpdate();
  }

  /// Sends a ready pair request to the simulator via MQTT.
  /// The simulator must confirm the pairing before the ride can start.
  /// Format: {"type":"PairRequest","deviceID":"5d2b1","deviceName":"Priobike"}
  /// Returns true if pair request was sent.
  /// Returns false if the request was not sent because it was sent too recently/an error occured.
  Future<bool> sendReadyPairRequest() async {
    if (client == null) {
      final successfullyConnected = await connectMQTTClient();
      if (!successfullyConnected) return false;
    }

    // Only send a ready pair request every 10 seconds to avoid spamming the simulator.
    if (lastSentPairRequest != null && DateTime.now().difference(lastSentPairRequest!).inSeconds < 10) return false;
    lastSentPairRequest = DateTime.now();

    const qualityOfService = MqttQos.atLeastOnce;

    Map<String, String> json = {};
    json['type'] = 'PairRequest';
    json['deviceID'] = deviceId;
    json['deviceName'] = 'Priobike';

    final String message = jsonEncode(json);

    final successfullySent = await _sendViaMQTT(
      message: message,
      qualityOfService: qualityOfService,
    );

    return successfullySent;
  }

  /// Helper function to encode and send a message to the simulator via MQTT.
  Future<bool> _sendViaMQTT({required String message, required MqttQos qualityOfService}) async {
    if (client == null) {
      final successfullyConnected = await connectMQTTClient();
      if (!successfullyConnected) return false;
    }

    // Convert message to byte array
    final Uint8List data = Uint8List.fromList(utf8.encode(message));
    Uint8Buffer dataBuffer = Uint8Buffer();
    dataBuffer.addAll(data);
    log.i("Sending to simulator: $message");

    // Publish message
    try {
      client!.publishMessage(topic, qualityOfService, dataBuffer);
      return true;
    } catch (e, stacktrace) {
      log.e("Error while sending $message to simulator: $e, $stacktrace");
      return false;
    }
  }

  /// Connects the MQTT client to the simulator.
  Future<bool> connectMQTTClient() async {
    // Get the backend that is currently selected.
    final settings = getIt<Settings>();

    final clientId = deviceId;
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

      client!.updates?.listen(_onData);

      client?.subscribe(topic, MqttQos.atLeastOnce);

      return true;
    } catch (e, stacktrace) {
      client = null;
      final hint = "Failed to connect the simulator MQTT client: $e, $stacktrace";
      log.e(hint);
      return false;
    }
  }

  /// A callback that is executed when data arrives.
  Future<void> _onData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    if (client == null) await connectMQTTClient();

    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      if (json['deviceID'] != deviceId) return;
      log.i("Received from simulator: $json");

      // Paring
      if (!paired && json['type'] == 'PairStart') {
        paired = true;
        log.i("Pairing with simulator successful.");

        // Send Pair Confirm to finish pairing
        const qualityOfService = MqttQos.atLeastOnce;
        final String message = '{"type":"PairConfirm", "deviceID":"$deviceId"}';
        await _sendViaMQTT(
          message: message,
          qualityOfService: qualityOfService,
        );

        makeReadyForRide();

        notifyListeners();
      }

      // Un-pair message from simulator.
      if (paired && json['type'] == 'Unpair') {
        log.i("Unpair received from simulator.");
        paired = false;
        notifyListeners();
      }
    }
  }

  /// Sends a stop ride message to the simulator via MQTT to stop the simulation.
  /// This will be called when the user ends the ride.
  /// Format: {"type":"StopRide","deviceID":"5d2b1"}
  Future<void> sendStopRide() async {
    if (client == null) await connectMQTTClient();

    const qualityOfService = MqttQos.atLeastOnce;

    Map<String, String> json = {};
    json['type'] = 'StopRide';
    json['deviceID'] = deviceId;

    final String message = jsonEncode(json);

    await _sendViaMQTT(
      message: message,
      qualityOfService: qualityOfService,
    );
  }

  /// Send the current position to the simulator via MQTT.
  /// This will be called every second to update the position in the simulator.
  /// Format: {"type":"NextCoordinate", "deviceID":"1234567890", "longitude":"10.12345",
  /// "latitude":"50.12345", "bearing":"-80"}
  Future<void> sendCurrentPosition() async {
    if (client == null) await connectMQTTClient();

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
    json['deviceID'] = deviceId;
    json['longitude'] = longitude.toString();
    json['latitude'] = latitude.toString();
    json['bearing'] = heading.toString();
    json['speed'] = speed.toString();

    final String message = jsonEncode(json);

    await _sendViaMQTT(
      message: message,
      qualityOfService: qualityOfService,
    );
  }

  /// Sends the route points before the rides startes to the simulator.
  /// Format: [{"type":"RouteDataStart","deviceID":"87c22"},{"lon":9.993686,"lat":53.551085}
  /// ... {"lon":9.976977980510583,"lat":53.56440493672994}]
  Future<void> sendRouteData() async {
    if (client == null) await connectMQTTClient();

    const qualityOfService = MqttQos.atLeastOnce;

    final List<Map<String, dynamic>> payload = [];
    Map<String, String> jsonStart = {};
    jsonStart['type'] = 'RouteDataStart';
    jsonStart['deviceID'] = deviceId;
    payload.add(jsonStart);

    final routing = getIt<Routing>();
    for (final node in routing.selectedRoute!.route) {
      final Map<String, dynamic> json = {};
      json['lon'] = node.lon;
      json['lat'] = node.lat;
      payload.add(json);
    }

    final String message = jsonEncode(payload);

    await _sendViaMQTT(
      message: message,
      qualityOfService: qualityOfService,
    );
  }

  /// Sends the traffic lights to the simulator.
  /// This will be called once before the ride starts to place the traffic lights on the map in the simulator.
  /// Format: {"type":"TrafficLight", "deviceID":"123", "tlID":"456", "longitude":"10.12345",
  /// "latitude":"50.12345", "bearing":"80"}
  Future<void> sendSignalGroups() async {
    if (client == null) await connectMQTTClient();

    final routing = getIt<Routing>();
    if (routing.selectedRoute == null) return;

    for (final sg in routing.selectedRoute!.signalGroups) {
      final tlID = sg.id;
      const type = "TrafficLight";
      final deviceID = deviceId;
      final longitude = sg.position.lon;
      final latitude = sg.position.lat;
      final bearing = sg.bearing ?? 0;

      Map<String, String> json = {};
      json['type'] = type;
      json['deviceID'] = deviceID;
      json['tlID'] = tlID;
      json['longitude'] = longitude.toString();
      json['latitude'] = latitude.toString();
      json['bearing'] = bearing.toString();
      final String message = jsonEncode(json);
      await _sendViaMQTT(message: message, qualityOfService: MqttQos.atLeastOnce);
    }
  }

  /// Sends updates of the state of the signal group to the simulator.
  /// This will be called throughout the ride whenever the state of the signal group changes.
  /// Format: {"type":"TrafficLightChange", "deviceID":"123", "tlID":"456", "state":"red"}
  Future<void> sendSignalGroupUpdate() async {
    if (client == null) await connectMQTTClient();

    final ride = getIt<Ride>();

    if (ride.calcCurrentSG == null ||
        ride.predictionComponent == null ||
        ride.predictionComponent!.recommendation == null) return;

    final currentSg = ride.calcCurrentSG!;

    // Only send update if same traffic light has different state
    final state = ride.predictionComponent!.recommendation!.calcCurrentSignalPhase.toString().split(".")[1];
    final tlID = currentSg.id;
    if (currentSGState != null && currentSGId != null && currentSGState == state && currentSGId == tlID) return;
    currentSGState = state;
    currentSGId = tlID;

    final simulator = getIt<Simulator>();
    const type = "TrafficLightChange";
    final deviceID = simulator.deviceId;

    Map<String, String> json = {};
    json['type'] = type;
    json['deviceID'] = deviceID;
    json['tlID'] = tlID;
    json['state'] = state;
    final String message = jsonEncode(json);
    await _sendViaMQTT(
      message: message,
      qualityOfService: MqttQos.atLeastOnce,
    );
  }

  /// Disconnects the MQTT client from the simulator.
  Future<void> disconnectMQTTClient() async {
    if (client != null) {
      await sendStopRide();
      client!.unsubscribe(topic);
      client!.disconnect();
      client = null;
      log.i("Disconnected from simulator MQTT broker.");
    }
  }
}
