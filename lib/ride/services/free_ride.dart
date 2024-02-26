import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  /// All SGs.
  Map<String, LatLng>? sgs;

  /// All SG geometries (GeoJSONs).
  Map<String, Map<String, dynamic>>? sgGeometries;

  /// All SG bearings.
  Map<String, double>? sgBearings;

  /// Clustered SGs by intersection.
  Map<String, LatLng>? clusteredSgs;

  /// The SGs that belong to a cluster.
  Map<String, List<String>>? sgsInCluster;

  /// The current SGs we are subscribed to.
  final Set<String> subscriptions = {};

  /// The max distance in meters for an SG to be considered on screen.
  static const maxDistance = 200;

  final vincenty = const Distance(roundResult: false);

  /// The prediction client.
  MqttServerClient? client;

  /// The received predictions by their sg id.
  Map<String, PredictionServicePrediction> receivedPredictions = {};

  /// Prepares the required data for the free ride view.
  Future<void> prepare() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      await fetchSgs();
      await fetchSgGeometries();
      await clusterSgs();
      connectMQTTClient();
      isLoading = false;
      notifyListeners();
    } catch (e, stacktrace) {
      isLoading = false;
      notifyListeners();
      final hint = "Error while preparing the free ride view: $e $stacktrace";
      log.e(hint);
    }
  }

  /// Fetch all SGs from the backend.
  Future<void> fetchSgs() async {
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;

    final url = "https://$baseUrl/sg-selector-nginx/sgs_min.json.gz";
    final endpoint = Uri.parse(url);

    final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      final err = "Error while fetching SGs from $endpoint: ${response.statusCode}";
      throw Exception(err);
    }

    final uncompressed = gzip.decode(response.bodyBytes);
    final decoded = utf8.decode(uncompressed);

    final json = jsonDecode(decoded);

    sgs = {};
    for (final sg in json) {
      final id = sg["id"];
      final lat = sg["position"]["lat"];
      final lon = sg["position"]["lon"];
      sgs![id] = LatLng(lat, lon);
    }

    log.i("Fetched ${sgs!.length} SGs.");
  }

  /// Fetch all SG geometries from the backend.
  Future<void> fetchSgGeometries() async {
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;

    final url = "https://$baseUrl/sg-selector-nginx/sgs_geo.json.gz";
    final endpoint = Uri.parse(url);

    final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      final err = "Error while fetching SGs from $endpoint: ${response.statusCode}";
      throw Exception(err);
    }

    final uncompressed = gzip.decode(response.bodyBytes);
    final decoded = utf8.decode(uncompressed);

    final json = jsonDecode(decoded);

    sgGeometries = {};
    sgBearings = {};
    for (final sg in json) {
      final id = sg["id"];
      final geometry = jsonDecode(sg["geometry"]);
      final first = geometry["coordinates"].first;
      final second = geometry["coordinates"][1];
      final bearing = vincenty.bearing(LatLng(first[1], first[0]), LatLng(second[1], second[0]));
      sgGeometries![id] = geometry;
      sgBearings![id] = bearing;
    }

    log.i("Fetched ${sgGeometries!.length} SG geometries.");
  }

  /// Cluster the SGs.
  Future<void> clusterSgs() async {
    if (sgs == null || sgs!.isEmpty) return;
    Map<String, List<LatLng>> clusters = {};
    sgsInCluster = {};
    for (final entry in sgs!.entries) {
      final lat = entry.value.latitude;
      final lon = entry.value.longitude;
      final coordinate = LatLng(lat, lon);
      final key = entry.key.replaceAll("hamburg/", "").split("_").first;
      if (!clusters.containsKey(key)) {
        clusters[key] = [coordinate];
        sgsInCluster![key] = [entry.key];
      } else {
        clusters[key]!.add(coordinate);
        sgsInCluster![key]!.add(entry.key);
      }
    }

    Map<String, LatLng> clusterCenters = {};
    for (final entry in clusters.entries) {
      final key = entry.key;
      final coordinates = entry.value;
      final lat = coordinates.map((e) => e.latitude).reduce((a, b) => a + b) / coordinates.length;
      final lon = coordinates.map((e) => e.longitude).reduce((a, b) => a + b) / coordinates.length;
      clusterCenters[key] = LatLng(lat, lon);
    }

    clusteredSgs = clusterCenters;

    log.i("Clustered ${sgs!.length} SGs into ${clusterCenters.length} clusters.");
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

      for (final entry in clusteredSgs!.entries) {
        if (entry.value.latitude < s || entry.value.latitude > n) continue;
        if (entry.value.longitude < w || entry.value.longitude > e) continue;
        if (vincenty.distance(cameraCenter, entry.value) > maxDistance) continue;
        final key = entry.key;
        final sgs = sgsInCluster![key];
        onScreenSGs.addAll(sgs!);
      }
    }
    log.i("Updating subscriptions for ${onScreenSGs.length} SGs.");
    updateSubscriptions(onScreenSGs);
  }

  /// Update the prediction subscriptions.
  Future<void> updateSubscriptions(Set<String> onScreenSGs) async {
    final newSgsToSubscribeTo = onScreenSGs.difference(subscriptions);
    final outdatedSgs = subscriptions.difference(onScreenSGs);
    for (final sg in newSgsToSubscribeTo) {
      await subscribe(sg);
    }
    for (final sg in outdatedSgs) {
      await unsubscribe(sg);
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
      throw Exception(hint);
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
    isLoading = false;
    sgs = null;
    sgGeometries = null;
    subscriptions.clear();
    receivedPredictions.clear();
    client?.disconnect();
    client = null;
    notifyListeners();
  }
}
