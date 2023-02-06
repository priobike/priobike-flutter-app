import 'dart:async';
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

  /// The timer that is used to periodically calculate the prediction.
  Timer? calcTimer;

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

  /// The currently subscribed signal group.
  Sg? subscribedSG;

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

  /// The calculated distance to the next turn.
  double? calcDistanceToNextTurn;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  /// The predictions received during the ride, from the prediction service.
  final List<PredictionServicePrediction> predictionServicePredictions = [];

  /// The predictions received during the ride, from the predictor.
  final List<PredictorPrediction> predictorPredictions = [];

  /// The session id, set randomly by `startNavigation`.
  String? sessionId;

  /// Subscribe to the signal group.
  void selectSG(Sg? sg) {
    if (!navigationIsActive) return;

    if (subscribedSG != null && subscribedSG != sg) {
      log.i("Unsubscribing from signal group ${subscribedSG?.id}");
      client?.unsubscribe(subscribedSG!.id);

      // Reset all values that were calculated for the previous signal group.
      prediction = null;
      calcPhasesFromNow = null;
      calcQualitiesFromNow = null;
      calcCurrentPhaseChangeTime = null;
      calcCurrentSignalPhase = null;
      calcPredictionQuality = null;
      calcDistanceToNextSG = null;
    }

    if (sg != null && sg != subscribedSG) {
      log.i("Subscribing to signal group ${sg.id}");
      client?.subscribe(sg.id, MqttQos.atLeastOnce);
    }

    subscribedSG = sg;

    onSelectNextSignalGroup?.call(calcCurrentSG);
  }

  /// Select the next signal group.
  /// Forward is step = 1, backward is step = -1.
  void jumpToSG({required int step}) {
    if (route == null) return;
    if (route!.signalGroups.isEmpty) return;
    if (userSelectedSGIndex == null && calcCurrentSGIndex == null) {
      // If there is no next signal group, select the first one if moving forward.
      // If moving backward, select the last one.
      userSelectedSGIndex = step > 0 ? 0 : route!.signalGroups.length - 1;
    } else if (userSelectedSGIndex == null) {
      // User did not manually select a signal group yet.
      userSelectedSGIndex = (calcCurrentSGIndex! + step) % route!.signalGroups.length;
    } else {
      // User manually selected a signal group.
      userSelectedSGIndex = (userSelectedSGIndex! + step) % route!.signalGroups.length;
    }
    userSelectedSG = route!.signalGroups[userSelectedSGIndex!];
    selectSG(userSelectedSG);
    notifyListeners();
  }

  /// Unselect the current signal group.
  void unselectSG() {
    if (userSelectedSG == null) return;
    if (userSelectedSGIndex == null) return;
    userSelectedSG = null;
    userSelectedSGIndex = null;
    onSelectNextSignalGroup?.call(calcCurrentSG);
    selectSG(calcCurrentSG);
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
    sessionId = UniqueKey().toString();
    // Start the timer that updates the prediction once per second.
    calcTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (predictionMode == PredictionMode.usePredictionService) {
        calculateRecommendationFromPredictionService();
      } else {
        calculateRecommendationFromPredictor();
      }
    });
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
        predictionServicePredictions.add(prediction);
      } else {
        log.i("Received prediction from predictor: $json");
        prediction = PredictorPrediction.fromJson(json);
        calculateRecommendationFromPredictor();
        predictorPredictions.add(prediction);
      }
    }
  }

  /// Update the position.
  Future<void> updatePosition(BuildContext context) async {
    if (!navigationIsActive) return;

    final snap = Provider.of<Positioning>(context, listen: false).snap;
    if (snap == null || route == null) return;

    // Calculate the distance to the next turn.
    // Traverse the segments and find the next turn, i.e. where the bearing changes > <x>°.
    const bearingThreshold = 15;
    var calcDistanceToNextTurn = 0.0;
    for (int i = snap.metadata.shortestDistanceIndex; i < route!.route.length - 1; i++) {
      final n1 = route!.route[i], n2 = route!.route[i + 1];
      final p1 = LatLng(n1.lat, n1.lon), p2 = LatLng(n2.lat, n2.lon);
      final b = vincenty.bearing(p1, p2); // [-180°, 180°]
      calcDistanceToNextTurn += vincenty.distance(p1, p2);
      if ((b - snap.bearing).abs() > bearingThreshold) break;
    }
    this.calcDistanceToNextTurn = calcDistanceToNextTurn;

    // Find the next signal group.
    Sg? nextSg;
    int? nextSgIndex;
    double routeDistanceOfNextSg = double.infinity;
    for (int i = 0; i < route!.signalGroups.length; i++) {
      if (route!.signalGroupsDistancesOnRoute[i] > snap.distanceOnRoute) {
        nextSg = route!.signalGroups[i];
        nextSgIndex = i;
        routeDistanceOfNextSg = route!.signalGroupsDistancesOnRoute[i];
        break;
      }
    }

    // Find the next crossing that is not connected on the route.
    double routeDistanceOfDisconnectedCrossing = double.infinity;
    for (int i = 0; i < route!.crossings.length; i++) {
      if (route!.crossingsDistancesOnRoute[i] > snap.distanceOnRoute) {
        if (route!.crossings[i].connected) continue;
        // The crossing is not connected, so we can use it.
        routeDistanceOfDisconnectedCrossing = route!.crossingsDistancesOnRoute[i];
        break;
      }
    }
    // If the next disconnected crossing is closer, don't select the next sg just yet.
    if (routeDistanceOfDisconnectedCrossing < routeDistanceOfNextSg) {
      nextSg = null;
      nextSgIndex = null;
    }

    if (calcCurrentSG != nextSg) {
      calcCurrentSG = nextSg;
      calcCurrentSGIndex = nextSgIndex;
      // If the user didn't override the current sg, select it.
      if (userSelectedSG == null) selectSG(nextSg);
    }
    // Calculate the distance to the next signal group.
    if (calcCurrentSGIndex != null) {
      calcDistanceToNextSG = route!.signalGroupsDistancesOnRoute[calcCurrentSGIndex!] - snap.distanceOnRoute;
    } else {
      calcDistanceToNextSG = null;
    }

    notifyListeners();
  }

  Future<void> calculateRecommendationFromPredictor() async {
    if (!navigationIsActive) return;

    // This will be executed if we fail somewhere.
    onFailure(String? reason) {
      if (reason != null) log.w("Failed to calculate predictor info: $reason");
      calcPhasesFromNow = null;
      calcQualitiesFromNow = null;
      calcCurrentPhaseChangeTime = null;
      calcCurrentSignalPhase = null;
      calcPredictionQuality = null;
      notifyListeners();
    }

    if (this.prediction == null) return onFailure(null); // Fail silently.
    // Check the type of the prediction.
    if (this.prediction! is! PredictorPrediction) return onFailure("Prediction is of wrong type");
    final prediction = this.prediction as PredictorPrediction;

    // The prediction is split into two parts: "now" and "then".
    // "now" is the predicted behavior within the current cycle, which can deviate from the average behavior.
    // "then" is the predicted behavior after the cycle, which is the average behavior.
    final now = prediction.now.map((e) => PhaseColor.fromInt(e)).toList();
    if (now.isEmpty) return onFailure("No prediction available (now.length == 0)");
    final nowQuality = prediction.nowQuality.map((e) => e.toInt() / 100).toList();
    final then = prediction.then.map((e) => PhaseColor.fromInt(e)).toList();
    if (then.isEmpty) return onFailure("No prediction available (then.length == 0)");
    final thenQuality = prediction.thenQuality.map((e) => e.toInt() / 100).toList();
    final diff = DateTime.now().difference(prediction.referenceTime).inSeconds;
    if (diff > 300) return onFailure("Prediction is too old: $diff seconds");
    var index = diff;

    calcPhasesFromNow = <Phase>[];
    calcQualitiesFromNow = <double>[];
    // Keep the index of the reference time in the prediction.
    // This is 0 unless the reference time is in the future.
    var refTimeIdx = 0;
    // Check if the prediction is in the future.
    if (index < -then.length) {
      // Small deviations (-2 seconds, -1 seconds) are to be expected due to clock deviations,
      // but if the prediction is too far in the future, something must have gone wrong.
      return onFailure("Prediction is too far in the future: $index seconds");
    } else if (index < 0) {
      log.w("Prediction is in the future: $index seconds");
      // Take the last part of the "then" prediction until we reach the start of "now".
      calcPhasesFromNow = calcPhasesFromNow! + then.sublist(then.length + index, then.length);
      calcQualitiesFromNow = calcQualitiesFromNow! + thenQuality.sublist(then.length + index, then.length);
      refTimeIdx = calcPhasesFromNow!.length; // To calculate the current phase.
      index = max(0, index);
    }
    // Calculate the phases from the start time of "now".
    if (index < now.length) {
      // We are within the "now" part of the prediction.
      calcPhasesFromNow = calcPhasesFromNow! + now.sublist(index);
      calcQualitiesFromNow = calcQualitiesFromNow! + nowQuality.sublist(index);
    } else {
      // We are within the "then" part of the prediction.
      calcPhasesFromNow = calcPhasesFromNow! + then.sublist((index - now.length) % then.length);
      calcQualitiesFromNow = calcQualitiesFromNow! + thenQuality.sublist((index - now.length) % then.length);
    }
    // Fill the phases with "then" (the average behavior) until we have enough values.
    while (calcPhasesFromNow!.length < refTimeIdx + 300) {
      calcPhasesFromNow = calcPhasesFromNow! + then;
      calcQualitiesFromNow = calcQualitiesFromNow! + thenQuality;
    }
    // Calculate the current phase.
    final currentPhase = calcPhasesFromNow![refTimeIdx];
    // Calculate the current phase change time.
    for (int i = refTimeIdx; i < calcPhasesFromNow!.length; i++) {
      if (calcPhasesFromNow![i] != currentPhase) {
        calcCurrentPhaseChangeTime = DateTime.now().add(Duration(seconds: i));
        break;
      }
    }
    calcCurrentSignalPhase = currentPhase;
    calcPredictionQuality = calcQualitiesFromNow![refTimeIdx];

    notifyListeners();
  }

  Future<void> calculateRecommendationFromPredictionService() async {
    if (!navigationIsActive) return;

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
  }

  /// Stop the navigation.
  Future<void> stopNavigation(BuildContext context) async {
    calcTimer?.cancel();
    calcTimer = null;
    client?.disconnect();
    client = null;
    navigationIsActive = false;
    notifyListeners();
  }

  /// Reset the service.
  Future<void> reset() async {
    route = null;
    navigationIsActive = false;
    client?.disconnect();
    client = null;
    calcPhasesFromNow = null;
    calcQualitiesFromNow = null;
    calcCurrentPhaseChangeTime = null;
    calcCurrentSignalPhase = null;
    calcPredictionQuality = null;
    calcCurrentSG = null;
    calcCurrentSGIndex = null;
    calcDistanceToNextSG = null;
    predictionServicePredictions.clear();
    predictorPredictions.clear();
    prediction = null;
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
