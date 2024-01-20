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
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:typed_data/typed_buffers.dart';

class Simulator with ChangeNotifier {
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

  /// The last send state of the next signal group. Used to only send a state if it changed.
  String? lastSendSGState;

  // The last send signal group id. Used to only send a state if it changed.
  String? lastSendSGId;

  /// Asks the user for the bluetooth permission to connect the sensor.
  askForPermission() {
    // TODO: implement askForPermission
  }

  /// Connects the device with the sensor.
  connectWithSensor() {
    // TODO: implement conntectWithDevice
  }

  /// Sends a ready pair request to the simulator via MQTT.
  /// The simulator must confirm the pairing before the ride can start.
  /// Format: {"type":"PairRequest","deviceID":"5d2b1","deviceName":"Priobike"}
  Future<void> sendReadyPairRequest() async {
    if (getIt<Settings>().enableSimulatorMode == false) return;
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

    await _sendViaMQTT(
      message: message,
      qualityOfService: qualityOfService,
    );
  }

  /// Sends a stop ride message to the simulator via MQTT to stop the simulation.
  /// This will be called when the user ends the ride.
  /// Format: {"type":"StopRide","deviceID":"5d2b1"}
  Future<void> sendStopRide() async {
    if (getIt<Settings>().enableSimulatorMode == false) return;
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
  Future<void> sendCurrentPosition({required bool isFirstPosition}) async {
    if (getIt<Settings>().enableSimulatorMode == false) return;
    if (client == null) await connectMQTTClient();

    const qualityOfService = MqttQos.atMostOnce;

    final Positioning positioning = getIt<Positioning>();
    final Position position = positioning.lastPosition!;
    final double longitude;
    final double latitude;
    final double heading;
    final String type;

    // if it is the first position, send the starting point of the route
    if (isFirstPosition) {
      final routing = getIt<Routing>();
      if (routing.selectedRoute == null) return;
      if (routing.selectedRoute!.route.isEmpty) return;
      final startingPoint = routing.selectedRoute!.route.first;
      longitude = startingPoint.lon;
      latitude = startingPoint.lat;
      heading = position.heading;
      type = 'FirstCoordinate';
    } else {
      if (positioning.lastPosition == null) return;
      longitude = position.longitude;
      latitude = position.latitude;
      heading = position.heading;
      type = 'NextCoordinate';
    }

    Map<String, String> json = {};
    json['type'] = type;
    json['deviceID'] = deviceId;
    json['longitude'] = longitude.toString();
    json['latitude'] = latitude.toString();
    json['bearing'] = heading.toString();

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
    if (getIt<Settings>().enableSimulatorMode == false) return;
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

  /// A callback that is executed when data arrives.
  Future<void> _onData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    if (getIt<Settings>().enableSimulatorMode == false) return;
    if (client == null) await connectMQTTClient();

    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      log.i("Received for simulator: $json");

      // Paring
      if (!pairSuccessful && json['type'] == 'PairStart' && json['deviceID'] == deviceId) {
        pairSuccessful = true;
        log.i("Pairing with simulator successful.");

        // Send Pair Confirm to finish pairing
        const qualityOfService = MqttQos.atLeastOnce;
        final String message = '{"type":"PairConfirm", "deviceID":"$deviceId"}';
        await _sendViaMQTT(
          message: message,
          qualityOfService: qualityOfService,
        );

        // Send the first position so the simulator can move the bike to the starting point of the route.
        await sendCurrentPosition(isFirstPosition: true);

        notifyListeners();
      }

      // When the simulator sends a stop ride message, the ride ends.
      if (!receivedStopRide && json['type'] == 'StopRide' && json['deviceID'] == deviceId) {
        log.i("Stop ride received from simulator.");
        receivedStopRide = true;
        notifyListeners();
      }
    }
  }

  /// Sends the traffic lights to the simulator.
  /// This will be called once before the ride starts to place the traffic lights on the map in the simulator.
  /// Format: {"type":"TrafficLight", "deviceID":"123", "tlID":"456", "longitude":"10.12345",
  /// "latitude":"50.12345", "bearing":"80"}
  Future<void> sendSignalGroups() async {
    if (getIt<Settings>().enableSimulatorMode == false) return;
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
    if (getIt<Settings>().enableSimulatorMode == false) return;
    if (client == null) await connectMQTTClient();

    final ride = getIt<Ride>();

    if (ride.calcCurrentSG == null ||
        ride.predictionComponent == null ||
        ride.predictionComponent!.recommendation == null) return;

    final currentSg = ride.calcCurrentSG!;

    // Only send update if same traffic light has different state
    final state = ride.predictionComponent!.recommendation!.calcCurrentSignalPhase.toString().split(".")[1];
    final tlID = currentSg.id;
    if (lastSendSGState != null && lastSendSGId != null && lastSendSGState == state && lastSendSGId == tlID) return;
    lastSendSGState = state;
    lastSendSGId = tlID;

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

  /// Helper function to encode and send a message to the simulator via MQTT.
  Future<void> _sendViaMQTT({required String message, required MqttQos qualityOfService}) async {
    if (getIt<Settings>().enableSimulatorMode == false) return;
    if (client == null) await connectMQTTClient();

    if (receivedStopRide) return;

    // Convert message to byte array
    final Uint8List data = Uint8List.fromList(utf8.encode(message));
    Uint8Buffer dataBuffer = Uint8Buffer();
    dataBuffer.addAll(data);
    log.i("Sending to simulator: $message");

    // Publish message
    try {
      client!.publishMessage(topic, qualityOfService, dataBuffer);
    } catch (e, stacktrace) {
      log.e("Error while sending $message to simulator: $e, $stacktrace");
    }
  }

  /// Connects the MQTT client to the simulator.
  Future<void> connectMQTTClient() async {
    resetVariables();

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

      await sendReadyPairRequest();
      subscription = client?.subscribe(topic, MqttQos.atLeastOnce);
    } catch (e, stacktrace) {
      client = null;
      final hint = "Failed to connect the simulator MQTT client: $e, $stacktrace";
      log.e(hint);
      final ride = getIt<Ride>();
      if (ride.navigationIsActive) {
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
    lastSendSGState = null;
    lastSendSGId = null;
    notifyListeners();
  }
}
