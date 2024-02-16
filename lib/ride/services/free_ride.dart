import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' hide Route, Shortcuts;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

/// The distance model.
const vincenty = Distance(roundResult: false);

class FreeRide with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("FreeRide");

  /// Whether the service is currently loading data.
  bool isLoading = false;

  /// The timer which triggers updates to all SGs that should receive predictions.
  Timer? sgUpdateTimer;

  /// All SGs.
  Map<String, LatLng>? sgs;

  /// The current SGs we are subscribed to.
  final Set<String> subscriptions = {};

  /// The max distance in meters for an SG to be considered on screen.
  static const maxDistance = 200;

  final vincenty = const Distance(roundResult: false);

  /// The prediction client.
  MqttServerClient? client;

  /// The received predictions by their sg id.
  Map<String, PredictionServicePrediction> receivedPredictions = {};

  /// Fetch all SGs from the backend.
  Future<void> fetchSgs() async {
    if (isLoading) return;
    connectMQTTClient();
    isLoading = true;
    notifyListeners();

    try {
      final settings = getIt<Settings>();
      final baseUrl = settings.backend.path;

      final url = "https://$baseUrl/sg-selector-backend/routing/all";
      final endpoint = Uri.parse(url);

      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        isLoading = false;
        notifyListeners();
        final err = "Error while fetching SGs from $endpoint: ${response.statusCode}";
        throw Exception(err);
      }

      final json = jsonDecode(response.body);

      sgs = {};
      for (final sg in json) {
        final id = sg["id"];
        final lat = sg["position"]["lat"];
        final lon = sg["position"]["lon"];
        sgs![id] = LatLng(lat, lon);
      }

      isLoading = false;
      notifyListeners();
    } catch (e, stacktrace) {
      isLoading = false;
      notifyListeners();
      final hint = "Error while fetching SGs: $e $stacktrace";
      log.e(hint);
    }
  }

  /// Update the SGs that should receive predictions.
  Future<void> updateVisibleSgs(CameraBounds bounds, LatLng cameraCenter, double cameraZoom) async {
    if (sgs == null) return;
    final onScreenSGs = <String>{};
    // Only show predictions for close SGs if the camera is zoomed in.
    if (cameraZoom > 15) {
      final coordinatesSouthwest = bounds.bounds.southwest["coordinates"] as List;
      final s = coordinatesSouthwest[1] as double;
      final w = coordinatesSouthwest[0] as double;
      final coordinatesNortheast = bounds.bounds.northeast["coordinates"] as List;
      final n = coordinatesNortheast[1] as double;
      final e = coordinatesNortheast[0] as double;

      for (final entry in sgs!.entries) {
        if (entry.value.latitude < s || entry.value.latitude > n) continue;
        if (entry.value.longitude < w || entry.value.longitude > e) continue;
        if (vincenty.distance(cameraCenter, entry.value) > maxDistance) continue;
        onScreenSGs.add(entry.key);
      }
    }
    log.i("On screen SGs: $onScreenSGs");
    updateSubscriptions(onScreenSGs);
  }

  /// Update the prediction subscriptions.
  Future<void> updateSubscriptions(Set<String> onScreenSGs) async {
    for (final sg in subscriptions) {
      if (!onScreenSGs.contains(sg)) {
        unsubscribe(sg);
      } else {
        onScreenSGs.remove(sg);
      }
    }
    for (final sg in onScreenSGs) {
      subscribe(sg);
    }
  }

  /// Establish a connection with the MQTT client.
  Future<void> connectMQTTClient() async {
    // Get the backend that is currently selected.
    final settings = getIt<Settings>();
    final clientId = 'priobike-app-free-ride-view-${UniqueKey().toString()}';
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
    } catch (e) {
      client = null;
      final hint = "Failed to connect the prediction MQTT client: $e";
      log.e(hint);
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
      final prediction = PredictionServicePrediction.fromJson(json);
      receivedPredictions["hamburg/${json["signalGroupId"]}"] = prediction;
    }
  }

  /// Unsubscribe from the given SG.
  Future<void> unsubscribe(String sg) async {
    subscriptions.remove(sg);
    receivedPredictions.remove(sg);
    if (client != null && client!.connectionStatus!.state == MqttConnectionState.connected) {
      client!.unsubscribe(sg);
    }
  }

  /// Subscribe to the given SG.
  Future<void> subscribe(String sg) async {
    subscriptions.add(sg);
    if (client != null && client!.connectionStatus!.state == MqttConnectionState.connected) {
      client!.subscribe(sg, MqttQos.atMostOnce);
    }
  }

  /// Reset the service.
  Future<void> reset() async {
    sgUpdateTimer?.cancel();
    sgUpdateTimer = null;
    isLoading = false;
    sgs = null;
    subscriptions.clear();
    receivedPredictions.clear();
    client?.disconnect();
    client = null;
    notifyListeners();
  }
}
