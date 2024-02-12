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
import 'package:priobike/ride/services/speedsensor.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:typed_data/typed_buffers.dart';

class Simulator with ChangeNotifier {
  /// The logger.
  final log = Logger("Simulator");

  /// The MQTT topic where we send messages from the app to.
  static const topicApp = "app";

  /// The MQTT topic where we receive messages from the simulator.
  static const topicSimulator = "simulator";

  /// The mqtt client.
  MqttServerClient? client;

  /// Current route. Used to only send a route if it changed.
  Route? currentRoute;

  /// The current state of the next signal group. Used to only send a state if it changed.
  String? currentSGState;

  /// The last send signal group id. Used to only send an SG if it changed.
  String? currentSGId;

  /// The unique key to identify the device in the simulator. Remove the brackets and hash sign.
  final appId = UniqueKey().toString().replaceAll("[", "").replaceAll("]", "").replaceAll("#", "");

  /// The last time a pair request was sent to the simulator.
  DateTime? lastSentPairRequest;

  /// If the simulator is paired.
  bool paired = false;

  /// Currently driving?
  bool driving = false;

  /// Positioning service.
  Positioning? positioning;

  /// Routing service.
  Routing? routing;

  /// Ride service.
  Ride? ride;

  /// If the pairing is currently in progress.
  bool pairingInProgress = false;

  /// List of pair acknowledgements (IDs of the simulators).
  List<String> pairAcknowledgements = [];

  /// The ID of the paired simulator.
  String? pairedSimulatorID;

  /// Make ready for the ride.
  Future<void> makeReadyForRide() async {
    pairingInProgress = true;
    notifyListeners();

    _sendReadyPairRequest();

    positioning ??= getIt<Positioning>();
    positioning!.addListener(_processPositioningUpdates);
    routing ??= getIt<Routing>();
    routing!.addListener(_processRoutingUpdates);
    ride ??= getIt<Ride>();
    ride!.addListener(_processRideUpdates);

    notifyListeners();
  }

  /// Dispose the simulator.
  void cleanUp() {
    _sendUnpair();
    _disconnectMQTTClient();
    paired = false;
    pairingInProgress = false;
    pairAcknowledgements = [];
    pairedSimulatorID = null;
    if (positioning != null) positioning!.removeListener(_processPositioningUpdates);
    if (routing != null) routing!.removeListener(_processRoutingUpdates);
    if (ride != null) ride!.removeListener(_processRideUpdates);
    getIt<SpeedSensor>().reset();
    notifyListeners();
  }

  /// Accept the pairing with the simulator.
  void acknowledgePairing(String simulatorID) {
    if (pairAcknowledgements.contains(simulatorID)) {
      paired = true;
      pairedSimulatorID = simulatorID;
      pairingInProgress = false;
      const qualityOfService = MqttQos.atLeastOnce;

      Map<String, String> json = {};
      json['type'] = 'PairAppAck';
      json['deviceName'] = 'Priobike';

      _sendViaMQTT(
        messageData: json,
        qualityOfService: qualityOfService,
      );

      notifyListeners();

      pairAcknowledgements = [];
    }
  }

  /// Process positioning updates.
  void _processPositioningUpdates() {
    if (!ride!.navigationIsActive) return;
    _sendCurrentPosition();
  }

  /// Process routing updates.
  void _processRoutingUpdates() {
    if (routing!.selectedRoute != currentRoute) {
      currentRoute = routing!.selectedRoute;
      _sendRouteData();
      _sendSignalGroups();
    }
  }

  /// Process ride updates.
  void _processRideUpdates() {
    if (!ride!.navigationIsActive) {
      if (driving) {
        _sendStopRide();
        getIt<SpeedSensor>().reset();
        driving = false;
      }
      return;
    }

    if (!driving) {
      driving = true;
      getIt<SpeedSensor>().initConnectionToSpeedSensor();
    }
    _sendSignalGroupUpdate();
  }

  /// Sends a ready pair request to the simulator via MQTT.
  /// The simulator must confirm the pairing before the ride can start.
  /// Format: {"type":"PairRequest","appID":"5d2b1","deviceName":"Priobike"}
  /// Returns true if pair request was sent.
  /// Returns false if the request was not sent because it was sent too recently/an error occured.
  Future<void> _sendReadyPairRequest() async {
    pairingInProgress = true;

    if (client == null) {
      final successfullyConnected = await _connectMQTTClient();
      if (!successfullyConnected) {
        pairingInProgress = false;
      }
    }

    // Only send a ready pair request every 10 seconds to avoid spamming the simulator.
    if (lastSentPairRequest != null && DateTime.now().difference(lastSentPairRequest!).inSeconds < 10) {
      pairingInProgress = false;
    }
    lastSentPairRequest = DateTime.now();

    const qualityOfService = MqttQos.atLeastOnce;

    Map<String, String> json = {};
    json['type'] = 'PairRequest';
    json['deviceName'] = 'Priobike';

    final successfullySent = await _sendViaMQTT(
      messageData: json,
      qualityOfService: qualityOfService,
    );

    if (!successfullySent) {
      pairingInProgress = false;
    }
  }

  /// Helper function to encode and send a message to the simulator via MQTT.
  Future<bool> _sendViaMQTT({required Map<String, dynamic> messageData, required MqttQos qualityOfService}) async {
    if (client == null) {
      final successfullyConnected = await _connectMQTTClient();
      if (!successfullyConnected) return false;
    }

    // For every other message than PairRequest, we need to have a paired simulator ID.
    if (pairedSimulatorID == null && messageData['type'] != "PairRequest") return false;

    messageData['appID'] = appId;
    if (pairedSimulatorID != null) messageData['simulatorID'] = pairedSimulatorID;

    final String message = jsonEncode(messageData);

    // Convert message to byte array
    final Uint8List data = Uint8List.fromList(utf8.encode(message));
    Uint8Buffer dataBuffer = Uint8Buffer();
    dataBuffer.addAll(data);
    log.i("Sending to simulator: $message");

    // Publish message
    try {
      client!.publishMessage(topicApp, qualityOfService, dataBuffer);
      return true;
    } catch (e, stacktrace) {
      log.e("Error while sending $message to simulator: $e, $stacktrace");
      return false;
    }
  }

  /// Connects the MQTT client to the simulator.
  Future<bool> _connectMQTTClient() async {
    // Get the backend that is currently selected.
    final settings = getIt<Settings>();

    final clientId = appId;
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

      client?.subscribe(topicSimulator, MqttQos.atLeastOnce);

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
    if (client == null) await _connectMQTTClient();

    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      if (json['appID'] != appId) return;
      log.i("Received from simulator: $json");

      // Paring
      if (!paired && json['type'] == 'PairSimulatorAck') {
        pairingInProgress = false;
        log.i("Pair request accepted by ${json['simulatorID']}.");
        pairAcknowledgements.add(json['simulatorID']);
        notifyListeners();
      }

      // Un-pair message from simulator.
      if (paired && json['type'] == 'Unpair') {
        log.i("Unpair received from simulator.");
        cleanUp();
        notifyListeners();
      }
    }
  }

  /// Sends a stop ride message to the simulator via MQTT to stop the simulation.
  /// This will be called when the user ends the ride.
  /// Format: {"type":"StopRide","appID":"5d2b1"}
  Future<void> _sendStopRide() async {
    if (client == null) await _connectMQTTClient();

    const qualityOfService = MqttQos.atLeastOnce;

    Map<String, String> json = {};
    json['type'] = 'StopRide';

    await _sendViaMQTT(
      messageData: json,
      qualityOfService: qualityOfService,
    );
  }

  /// Sends an unpair message to the simulator via MQTT.
  /// This will be called when the user un-pairs the device from the simulator.
  /// Format: {"type":"Unpair","appID":"5d2b1"}
  Future<void> _sendUnpair() async {
    if (client == null) await _connectMQTTClient();

    const qualityOfService = MqttQos.atLeastOnce;

    Map<String, String> json = {};
    json['type'] = 'Unpair';

    await _sendViaMQTT(
      messageData: json,
      qualityOfService: qualityOfService,
    );
  }

  /// Send the current position to the simulator via MQTT.
  /// This will be called every second to update the position in the simulator.
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

  /// Sends the route points before the rides startes to the simulator.
  /// Format: [{"type":"RouteDataStart","appID":"87c22"},{"lon":9.993686,"lat":53.551085}
  /// ... {"lon":9.976977980510583,"lat":53.56440493672994}]
  Future<void> _sendRouteData() async {
    if (client == null) await _connectMQTTClient();

    const qualityOfService = MqttQos.atLeastOnce;

    Map<String, dynamic> json = {};
    json['type'] = 'RouteDataStart';
    json['routeData'] = [];

    final routing = getIt<Routing>();
    for (final node in routing.selectedRoute!.route) {
      final Map<String, dynamic> coordinate = {};
      coordinate['lon'] = node.lon;
      coordinate['lat'] = node.lat;
      json['routeData'].add(coordinate);
    }

    await _sendViaMQTT(
      messageData: json,
      qualityOfService: qualityOfService,
    );
  }

  /// Sends the traffic lights to the simulator.
  /// This will be called once before the ride starts to place the traffic lights on the map in the simulator.
  /// Format: {"type":"TrafficLight", "appID":"123", "tlID":"456", "longitude":"10.12345",
  /// "latitude":"50.12345", "bearing":"80"}
  Future<void> _sendSignalGroups() async {
    if (client == null) await _connectMQTTClient();

    final routing = getIt<Routing>();
    if (routing.selectedRoute == null) return;

    for (final sg in routing.selectedRoute!.signalGroups) {
      final tlID = sg.id;
      const type = "TrafficLight";
      final longitude = sg.position.lon;
      final latitude = sg.position.lat;
      final bearing = sg.bearing ?? 0;

      Map<String, String> json = {};
      json['type'] = type;
      json['tlID'] = tlID;
      json['longitude'] = longitude.toString();
      json['latitude'] = latitude.toString();
      json['bearing'] = bearing.toString();

      await _sendViaMQTT(messageData: json, qualityOfService: MqttQos.atLeastOnce);
    }
  }

  /// Sends updates of the state of the signal group to the simulator.
  /// This will be called throughout the ride whenever the state of the signal group changes.
  /// Format: {"type":"TrafficLightChange", "appID":"123", "tlID":"456", "state":"red"}
  Future<void> _sendSignalGroupUpdate() async {
    if (client == null) await _connectMQTTClient();

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

    const type = "TrafficLightChange";

    Map<String, String> json = {};
    json['type'] = type;
    json['tlID'] = tlID;
    json['state'] = state;

    await _sendViaMQTT(
      messageData: json,
      qualityOfService: MqttQos.atLeastOnce,
    );
  }

  /// Disconnects the MQTT client from the simulator.
  Future<void> _disconnectMQTTClient() async {
    if (client != null) {
      client!.unsubscribe(topicSimulator);
      client!.disconnect();
      client = null;
      log.i("Disconnected from simulator MQTT broker.");
    }
  }
}
