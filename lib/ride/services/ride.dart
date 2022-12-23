import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

/// The distance model.
const vincenty = Distance(roundResult: false);

class Ride with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("Ride");

  /// The threshold used for showing traffic light colors and speedometer colors
  static const qualityThreshold = 0.5;

  /// An optional callback that is called when a new recommendation is received.
  void Function(Sg?)? onSelectNextSignalGroup;

  /// A boolean indicating if the navigation is active.
  var navigationIsActive = false;

  /// The prediction client.
  MqttServerClient? client;

  /// The set of current subscriptions.
  final Set<String> subscriptions = {};

  /// The currently selected route.
  Route? route;

  /// The current prediction mode.
  PredictionMode? predictionMode;

  /// The current prediction.
  dynamic prediction;

  /// A timestamp when the last calculation was performed.
  /// This is used to prevent fast recurring calculations.
  DateTime? calcLastTime;

  /// The current predicted phases.
  List<Phase>? calcPhasesFromNow;

  /// The prediction qualities from now in [0.0, 1.0], calculated periodically.
  List<double>? calcQualitiesFromNow;

  /// The current predicted time of the next phase change, calculated periodically.
  DateTime? calcCurrentPhaseChangeTime;

  /// The predicted current signal phase, calculated periodically.
  Phase? calcCurrentSignalPhase;

  /// The prediction quality in [0.0, 1.0], calculated periodically.
  double? calcPredictionQuality;

  /// The current signal group, calculated periodically.
  Sg? calcCurrentSG;

  /// The signal group that the user wants to see.
  Sg? userSelectedSG;

  /// The current signal group index, calculated periodically.
  int? calcCurrentSGIndex;

  /// The current signal group index, selected by the user.
  int? userSelectedSGIndex;

  /// The calculated distance to the next signal group.
  double? calcDistanceToNextSG;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The predictions received during the ride.
  final List<dynamic> predictions = [];

  /// If the user can select the next signal group.
  bool get userCanSelectNextSG {
    if (route == null) return false;
    if (userSelectedSGIndex != null) {
      return userSelectedSGIndex! < route!.signalGroups.length - 1;
    }
    if (calcCurrentSGIndex == null) {
      return false;
    }
    return calcCurrentSGIndex! < route!.signalGroups.length - 1;
  }

  /// If the user can select the previous signal group.
  bool get userCanSelectPreviousSG {
    if (route == null) return false;
    if (userSelectedSGIndex != null) {
      return userSelectedSGIndex! > 0;
    }
    if (calcCurrentSGIndex == null) {
      return false;
    }
    return calcCurrentSGIndex! > 0;
  }

  /// Select the next signal group.
  void selectNextSG() {
    if (route == null) return;
    if (!userCanSelectNextSG) return;
    if (userSelectedSGIndex == null) {
      userSelectedSGIndex = calcCurrentSGIndex! + 1;
    } else {
      userSelectedSGIndex = userSelectedSGIndex! + 1;
    }
    userSelectedSG = route!.signalGroups[userSelectedSGIndex!];
    onSelectNextSignalGroup?.call(userSelectedSG);
    notifyListeners();
  }

  /// Select the previous signal group.
  void selectPreviousSG() {
    if (route == null) return;
    if (!userCanSelectPreviousSG) return;
    if (userSelectedSGIndex == null) {
      userSelectedSGIndex = calcCurrentSGIndex! - 1;
    } else {
      userSelectedSGIndex = userSelectedSGIndex! - 1;
    }
    userSelectedSG = route!.signalGroups[userSelectedSGIndex!];
    onSelectNextSignalGroup?.call(userSelectedSG);
    notifyListeners();
  }

  /// Unselect the current signal group.
  void unselectSG() {
    if (userSelectedSG == null) return;
    if (userSelectedSGIndex == null) return;
    userSelectedSG = null;
    userSelectedSGIndex = null;
    onSelectNextSignalGroup?.call(calcCurrentSG);
    notifyListeners();
  }

  /// Unsubscribe from a datastream.
  void unsubscribe(String? sgId) {
    if (!navigationIsActive) return;
    if (sgId == null) return;
    if (!subscriptions.contains(sgId)) return;
    final t = sgId; // hamburg/...
    client?.unsubscribe(t);
    subscriptions.remove(t);
    notifyListeners();
  }

  /// Subscribe to a datastream.
  void subscribe(String? sgId) {
    if (!navigationIsActive) return;
    if (sgId == null) return;
    if (subscriptions.contains(sgId)) return;
    final t = sgId; // hamburg/...
    client?.subscribe(t, MqttQos.exactlyOnce);
    subscriptions.add(t);
    notifyListeners();
  }

  /// Select a new route.
  Future<void> selectRoute(BuildContext context, Route route) async {
    this.route = route;
    notifyListeners();
  }

  /// Start the navigation and connect the MQTT client.
  Future<void> startNavigation(BuildContext context) async {
    // Do nothing if the navigation has already been started.
    if (navigationIsActive) return;
    // Get the backend that is currently selected.
    final settings = Provider.of<Settings>(context, listen: false);
    predictionMode = settings.predictionMode;
    final clientId = 'priobike-app-${UniqueKey().toString()}';
    client = MqttServerClient(
      settings.predictionMode == PredictionMode.usePredictionService
          ? settings.backend.predictionServiceMQTTPath
          : settings.backend.predictorMQTTPath,
      clientId,
    );
    client!.logging(on: false);
    client!.keepAlivePeriod = 30;
    client!.secure = false;
    client!.port = settings.predictionMode == PredictionMode.usePredictionService
        ? settings.backend.predictionServiceMQTTPort
        : settings.backend.predictorMQTTPort;
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
    await client!.connect(
      settings.predictionMode == PredictionMode.usePredictionService
          ? settings.backend.predictionServiceMQTTUsername
          : settings.backend.predictorMQTTUsername,
      settings.predictionMode == PredictionMode.usePredictionService
          ? settings.backend.predictionServiceMQTTPassword
          : settings.backend.predictorMQTTPassword,
    );
    client!.updates?.listen(onData);
    // Mark that navigation is now active.
    navigationIsActive = true;
  }

  /// A callback that is executed when data arrives.
  Future<void> onData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      if (predictionMode == PredictionMode.usePredictionService) {
        log.i("Received prediction from prediction service: $json");
        prediction = PredictionServicePrediction.fromJson(json);
        calculateRecommendationFromPredictionService();
      } else {
        log.i("Received prediction from predictor: $json");
        prediction = PredictorPrediction.fromJson(json);
        calculateRecommendationFromPredictor();
      }
      predictions.add(prediction);
    }
  }

  /// Update the position.
  Future<void> updatePosition(BuildContext context) async {
    if (!navigationIsActive) return;

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
    int? nextSgIndex;
    for (int i = 0; i < route!.signalGroups.length; i++) {
      final sg = route!.signalGroups[i];
      if (sg.id == nextNavNode.signalGroupId) {
        nextSg = sg;
        nextSgIndex = i;
        break;
      }
    }
    if (calcCurrentSG != nextSg) {
      log.i("Unsubscribing from signal group ${calcCurrentSG?.id}");
      unsubscribe(calcCurrentSG?.id);
      calcCurrentSG = nextSg;
      calcCurrentSGIndex = nextSgIndex;
      onSelectNextSignalGroup?.call(calcCurrentSG);
      // Reset all values.
      prediction = null;
      calcPhasesFromNow = null;
      calcQualitiesFromNow = null;
      calcCurrentPhaseChangeTime = null;
      calcCurrentSignalPhase = null;
      calcPredictionQuality = null;
      log.i("Subscribing to signal group ${calcCurrentSG?.id}");
      subscribe(calcCurrentSG?.id);
    }
    // Calculate the distance to the next signal group.
    calcDistanceToNextSG = nextNavNode.distanceToNextSignal != null
        ? nextNavNode.distanceToNextSignal! + vincenty.distance(shortestDistancePSnapped, shortestDistanceP2)
        : null;

    notifyListeners();
  }

  Future<void> calculateRecommendationFromPredictor({scheduled = false}) async {
    if (!navigationIsActive) return;

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
      notifyListeners();
    }

    if (this.prediction == null) return onFailure("No prediction available");
    // Check the type of the prediction.
    if (this.prediction! is! PredictorPrediction) return onFailure("Prediction is not of wrong type");
    final prediction = this.prediction as PredictorPrediction;

    final now = prediction.now.map((e) => PhaseColor.fromInt(e)).toList();
    if (now.isEmpty) return onFailure("No prediction available (now.length == 0)");
    final nowQuality = prediction.nowQuality.map((e) => e.toInt() / 100).toList();
    final then = prediction.then.map((e) => PhaseColor.fromInt(e)).toList();
    if (then.isEmpty) return onFailure("No prediction available (then.length == 0)");
    final thenQuality = prediction.thenQuality.map((e) => e.toInt() / 100).toList();
    final diff = DateTime.now().difference(prediction.referenceTime).inSeconds;
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

    notifyListeners();

    // Schedule another execution. If the current execution is scheduled, we take a delay of 1s.
    // Otherwise, we take a delay of 1.25s to await the next recommendation from the server.
    final delay = Duration(milliseconds: scheduled ? 1000 : 1250);
    await Future.delayed(delay, () => calculateRecommendationFromPredictor(scheduled: true));
  }

  Future<void> calculateRecommendationFromPredictionService({scheduled = false}) async {
    if (!navigationIsActive) return;

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
      notifyListeners();
    }

    if (this.prediction == null) return onFailure("No prediction available");
    // Check the type of the prediction.
    if (this.prediction! is! PredictionServicePrediction) return onFailure("Prediction is of wrong type.");
    final prediction = this.prediction as PredictionServicePrediction;

    // Check if we have all necessary information.
    if (prediction.greentimeThreshold == -1) return onFailure("No greentime threshold.");
    if (prediction.predictionQuality == -1) return onFailure("No prediction quality.");
    if (prediction.value.isEmpty) return onFailure("No prediction vector.");
    // Calculate the seconds since the start of the prediction.
    final now = DateTime.now();
    final secondsSinceStart = max(0, now.difference(prediction.startTime).inSeconds);
    // Chop off the seconds that are not in the prediction vector.
    final secondsInVector = prediction.value.length;
    if (secondsSinceStart >= secondsInVector) return onFailure("Prediction vector is too short.");
    // Calculate the current vector.
    final currentVector = prediction.value.sublist(secondsSinceStart);
    if (currentVector.isEmpty) return onFailure("Current vector is empty.");
    // Calculate the seconds to the next phase change.
    int secondsToPhaseChange = 0;
    bool greenNow = currentVector[0] >= prediction.greentimeThreshold;
    for (int i = 1; i < currentVector.length; i++) {
      final greenThen = currentVector[i] >= prediction.greentimeThreshold;
      if ((greenNow && !greenThen) || (!greenNow && greenThen)) break;
      secondsToPhaseChange++;
    }

    calcPhasesFromNow = currentVector.map(
      (value) {
        if (value >= prediction.greentimeThreshold) {
          return Phase.green;
        } else {
          return Phase.red;
        }
      },
    ).toList();
    calcQualitiesFromNow = currentVector.map((_) => (prediction.predictionQuality)).toList();
    calcCurrentPhaseChangeTime = now.add(Duration(seconds: secondsToPhaseChange));
    calcCurrentSignalPhase = greenNow ? Phase.green : Phase.red;
    calcPredictionQuality = prediction.predictionQuality;

    notifyListeners();

    // Schedule another execution. If the current execution is scheduled, we take a delay of 1s.
    // Otherwise, we take a delay of 1.25s to await the next recommendation from the server.
    final delay = Duration(milliseconds: scheduled ? 1000 : 1250);
    await Future.delayed(delay, () => calculateRecommendationFromPredictionService(scheduled: true));
  }

  /// Stop the navigation.
  Future<void> stopNavigation(BuildContext context) async {
    for (final t in subscriptions) {
      client?.unsubscribe(t);
    }
    client?.disconnect();
    client = null;
    subscriptions.clear();
    navigationIsActive = false;
    notifyListeners();
  }

  /// Reset the service.
  Future<void> reset() async {
    route = null;
    navigationIsActive = false;
    client?.disconnect();
    client = null;
    subscriptions.clear();
    calcLastTime = null;
    calcPhasesFromNow = null;
    calcQualitiesFromNow = null;
    calcCurrentPhaseChangeTime = null;
    calcCurrentSignalPhase = null;
    calcPredictionQuality = null;
    calcCurrentSG = null;
    calcCurrentSGIndex = null;
    calcDistanceToNextSG = null;
    predictions.clear();
    needsLayout = {};
    notifyListeners();
  }

  /// Calculate the nearest point on the line between p1 and p2,
  /// with respect to the reference point pos.
  static LatLng snap(LatLng pos, LatLng p1, LatLng p2) {
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

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
