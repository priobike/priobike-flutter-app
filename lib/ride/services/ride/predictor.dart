import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride/interface.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

/// The distance model.
const vincenty = Distance(roundResult: false);

class Predictor extends Ride {
  /// Get the mqtt prediction topic for a signal group.
  static String? topic(String? sgId) {
    if (sgId == null) return null;
    if (sgId.contains("hamburg/")) {
      return "prediction/${sgId.substring(8)}";
    }
    return "prediction/($sgId)";
  }

  /// Logger for this class.
  final log = Logger("Predictor");

  /// A boolean indicating if the navigation is active.
  var navigationIsActive = false;

  /// The prediction client.
  MqttServerClient? client;

  /// The set of current subscriptions.
  final Set<String> subscriptions = {};

  /// The current prediction.
  Prediction? prediction;

  /// A timestamp when the last calculation was performed.
  /// This is used to prevent fast recurring calculations.
  DateTime? calcLastTime;

  /// Reset the predictor.
  @override
  Future<void> reset() async {
    super.reset();
    navigationIsActive = false;
    client?.disconnect();
    client = null;
    subscriptions.clear();
    prediction = null;
    calcLastTime = null;
    notifyListeners();
  }

  /// Unsubscribe from a datastream.
  void unsubscribe(String? sgId) {
    if (sgId == null) return;
    final t = topic(sgId)!;
    client?.unsubscribe(t);
    subscriptions.remove(t);
    notifyListeners();
  }

  /// Subscribe to a datastream.
  void subscribe(String? sgId) {
    if (sgId == null) return;
    final t = topic(sgId)!;
    client?.subscribe(t, MqttQos.exactlyOnce);
    subscriptions.add(t);
    notifyListeners();
  }

  /// Update the current route.
  @override
  Future<void> selectRoute(BuildContext context, Route route) async {
    this.route = route;
    notifyListeners();
  }

  /// Connect the mqtt client.
  @override
  Future<void> startNavigation(BuildContext context) async {
    // Do nothing if the navigation has already been started.
    if (navigationIsActive) return;
    // Mark that navigation is now active.
    navigationIsActive = true;
    // Get the backend that is currently selected.
    final backend = Provider.of<Settings>(context, listen: false).backend;
    client = MqttServerClient(backend.predictorMQTTPath, 'priobike-app-${UniqueKey().toString()}');
    client!.logging(on: false);
    client!.keepAlivePeriod = 30;
    client!.secure = false;
    client!.port = backend.predictorMQTTPort;
    client!.autoReconnect = true;
    client!.resubscribeOnAutoReconnect = true;
    client!.onDisconnected = () => log.i("Predictor MQTT client disconnected");
    client!.onConnected = () => log.i("Predictor MQTT client connected");
    client!.onSubscribed = (topic) => log.i("Predictor MQTT client subscribed to $topic");
    client!.onUnsubscribed = (topic) => log.i("Predictor MQTT client unsubscribed from $topic");
    client!.onAutoReconnect = () => log.i("Predictor MQTT client auto reconnect");
    client!.onAutoReconnected = () => log.i("Predictor MQTT client auto reconnected");
    client!.setProtocolV311(); // Default Mosquitto protocol
    client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(client!.clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    log.i("Connecting to Predictor MQTT broker ${backend.predictorMQTTPath}:${backend.predictorMQTTPort}");
    await client!.connect(backend.predictorMQTTUsername, backend.predictorMQTTPassword);
    client!.updates?.listen(onData);
  }

  /// A callback that is executed when data arrives.
  Future<void> onData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      final prediction = Prediction.fromJson(json);
      log.i("Received prediction from predictor: $prediction");
      this.prediction = prediction;
      calculateRecommendationInfo();
      notifyListeners();
    }
  }

  /// Calculate stuff periodically.
  Future<void> calculateRecommendationInfo({scheduled = false}) async {
    // Don't do a computation if the last one was recently done.
    if (calcLastTime != null && calcLastTime!.difference(DateTime.now()).inMilliseconds.abs() < 1000) return;
    calcLastTime = DateTime.now();

    // This will be executed if we fail somewhere.
    onFailure(reason) {
      log.w("Failed to calculate predictor info: $reason");
      calcPhasesFromNow = null;
      calcQualitiesFromNow = null;
      calcCurrentPhaseChangeTime = null;
      calcCurrentSignalPhase = null;
      calcPredictionQuality = null;
      calcCurrentSG = null;
      calcDistanceToNextSG = null;
      notifyListeners();
    }

    if (prediction == null) return onFailure("No prediction available");

    final now = prediction!.now.map((e) => PhaseColor.fromInt(e)).toList();
    if (now.isEmpty) return onFailure("No prediction available (now.length == 0)");
    final nowQuality = prediction!.nowQuality.map((e) => e.toInt() / 100).toList();
    final then = prediction!.then.map((e) => PhaseColor.fromInt(e)).toList();
    if (then.isEmpty) return onFailure("No prediction available (then.length == 0)");
    final thenQuality = prediction!.thenQuality.map((e) => e.toInt() / 100).toList();
    final diff = DateTime.now().difference(prediction!.referenceTime).inSeconds;
    if (diff < 0) return onFailure("Prediction is in the future");
    if (diff > 300) return onFailure("Prediction is too old");
    final index = max(0, diff);

    calcPhasesFromNow = List<Phase>.empty(growable: true);
    calcQualitiesFromNow = List<double>.empty(growable: true);
    if (index < now.length) {
      calcPhasesFromNow = (now.sublist(index) + then);
      calcQualitiesFromNow = nowQuality.sublist(index) + thenQuality;
    } else {
      calcPhasesFromNow = (then.sublist((index - now.length) % then.length) + then);
      calcQualitiesFromNow = thenQuality.sublist((index - now.length) % then.length) + thenQuality;
    }
    // Fill the phases array until we have > 300 values.
    while (calcPhasesFromNow!.length < 300) {
      calcPhasesFromNow = calcPhasesFromNow! + then;
      calcQualitiesFromNow = calcQualitiesFromNow! + thenQuality;
    }
    // Calculate the current phase.
    final currentPhase = calcPhasesFromNow![0];
    // Calculate the current phase change time.
    for (int i = 0; i < calcPhasesFromNow!.length; i++) {
      if (calcPhasesFromNow![i] != currentPhase) {
        calcCurrentPhaseChangeTime = DateTime.now().add(Duration(seconds: i));
        break;
      }
    }
    calcCurrentSignalPhase = currentPhase;
    calcPredictionQuality = calcQualitiesFromNow![0];

    // Check if everything is calculated.
    if (!everythingCalculated) return onFailure("Not everything is calculated.");

    notifyListeners();

    // Schedule another execution. If the current execution is scheduled, we take a delay of 1s.
    // Otherwise, we take a delay of 1.25s to await the next recommendation from the server.
    final delay = Duration(milliseconds: scheduled ? 1000 : 1250);
    await Future.delayed(delay, () => calculateRecommendationInfo(scheduled: true));
  }

  /// Disconnect and dispose the mqtt client.
  @override
  Future<void> stopNavigation(BuildContext context) async {
    for (final t in subscriptions) {
      client?.unsubscribe(t);
    }
    client?.disconnect();
    client = null;
    subscriptions.clear();
  }

  /// Update the current position.
  @override
  Future<void> updatePosition(BuildContext context) async {
    if (!navigationIsActive) await startNavigation(context);
    final positioning = Provider.of<Positioning>(context, listen: false);
    if (positioning.lastPosition == null) return;
    final p = positioning.lastPosition!;
    if (route == null) return;
    if (route!.route.length < 2) return;
    // Draw snapping lines to all route segments.
    var shortestDistance = double.infinity;
    var shortestDistanceIndex = 0;
    var shortestDistanceP2 = LatLng(0, 0);
    var shortestDistancePSnapped = LatLng(0, 0);
    for (int i = 0; i < route!.route.length - 1; i++) {
      final n1 = route!.route[i], n2 = route!.route[i + 1];
      final p1 = LatLng(n1.lat, n1.lon), p2 = LatLng(n2.lat, n2.lon);
      final s = snap(LatLng(p.latitude, p.longitude), p1, p2);
      final d = vincenty.distance(LatLng(p.latitude, p.longitude), s);
      if (d < shortestDistance) {
        shortestDistance = d;
        shortestDistanceIndex = i;
        shortestDistanceP2 = p2;
        shortestDistancePSnapped = s;
      }
    }
    // Find the next signal group.
    final nextNavNode = route!.route[shortestDistanceIndex + 1];
    Sg? nextSg;
    for (final sg in route!.signalGroups) {
      if (sg.id == nextNavNode.signalGroupId) {
        nextSg = sg;
        break;
      }
    }
    if (calcCurrentSG != nextSg) {
      log.i("Unsubscribing from signal group ${calcCurrentSG?.id}");
      unsubscribe(calcCurrentSG?.id);
      calcCurrentSG = nextSg;
      onSelectNextSignalGroup?.call(calcCurrentSG);
      // Reset all values.
      calcPhasesFromNow = null;
      calcQualitiesFromNow = null;
      calcCurrentPhaseChangeTime = null;
      calcCurrentSignalPhase = null;
      calcPredictionQuality = null;
      calcDistanceToNextSG = null;
      log.i("Subscribing to signal group ${calcCurrentSG?.id}");
      subscribe(calcCurrentSG?.id);
    }
    // Calculate the distance to the next signal group.
    calcDistanceToNextSG = nextNavNode.distanceToNextSignal != null
        ? nextNavNode.distanceToNextSignal! + vincenty.distance(shortestDistancePSnapped, shortestDistanceP2)
        : null;

    notifyListeners();
  }

  /// Calculate the nearest point on the line between p1 and p2,
  /// with respect to the reference point pos.
  LatLng snap(LatLng pos, LatLng p1, LatLng p2) {
    final x = pos.latitude, y = pos.longitude;
    final x1 = p1.latitude, y1 = p1.longitude;
    final x2 = p2.latitude, y2 = p2.longitude;

    final A = x - x1, B = y - y1, C = x2 - x1, D = y2 - y1;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    var param = -1.0;
    if (lenSq != 0) param = dot / lenSq;

    double xx, yy;
    if (param < 0) {
      // Snap to point 1.
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      // Snap to point 2.
      xx = x2;
      yy = y2;
    } else {
      // Snap to shortest point inbetween.
      xx = x1 + param * C;
      yy = y1 + param * D;
    }
    return LatLng(xx, yy);
  }
}
