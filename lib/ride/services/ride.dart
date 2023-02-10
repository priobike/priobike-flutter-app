import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
import 'package:priobike/status/messages/sg.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  void Function(SGStatusData)? onNewPredictionStatusDuringRide;

  /// Subscribe to the signal group.
  void selectSG(Sg? sg) {
    if (!navigationIsActive && client == null) return;

    if (subscribedSG != null && subscribedSG != sg) {
      log.i("Unsubscribing from signal group ${subscribedSG?.id}");
      client?.unsubscribe(subscribedSG!.id);

      // Reset all values that were calculated for the previous signal group.
      prediction = null;
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

  /// Establish a connection with the MQTT client.
  Future<void> connectMQTTClient(BuildContext context) async {
    // Get the backend that is currently selected.
    final settings = Provider.of<Settings>(context, listen: false);
    predictionMode = settings.predictionMode;
    final clientId = 'priobike-app-${UniqueKey().toString()}';
    try {
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
      await client!
          .connect(
            settings.predictionMode == PredictionMode.usePredictionService
                ? settings.backend.predictionServiceMQTTUsername
                : settings.backend.predictorMQTTUsername,
            settings.predictionMode == PredictionMode.usePredictionService
                ? settings.backend.predictionServiceMQTTPassword
                : settings.backend.predictorMQTTPassword,
          )
          .timeout(const Duration(seconds: 5));
      client!.updates?.listen(onData);
      selectSG(calcCurrentSG);
      // Start the timer that updates the prediction once per second.
      calcTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (predictionMode == PredictionMode.usePredictionService) {
          calculateRecommendationFromPredictionService();
        } else {
          calculateRecommendationFromPredictor();
        }
      });
    } catch (e, stackTrace) {
      client = null;
      final hint = "Failed to connect the prediction MQTT client: $e";
      log.e(hint);
      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: stackTrace, hint: hint);
      }
      if (navigationIsActive) {
        await Future.delayed(const Duration(seconds: 10));
        connectMQTTClient(context);
      }
    }
  }

  /// Start the navigation and connect the MQTT client.
  Future<void> startNavigation(BuildContext context, Function(SGStatusData)? onNewPredictionStatusDuringRide) async {
    // Do nothing if the navigation has already been started.
    if (navigationIsActive) return;
    connectMQTTClient(context);

    // Mark that navigation is now active.
    sessionId = UniqueKey().toString();
    navigationIsActive = true;
    // Notify listeners of a new sg status update.
    this.onNewPredictionStatusDuringRide = onNewPredictionStatusDuringRide;
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
        // Notify that a new prediction status was obtained.
        onNewPredictionStatusDuringRide?.call(SGStatusData(
          statusUpdateTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          thingName:
              "hamburg/${prediction.signalGroupId}", // Same as thing name. The prefix "hamburg/" is needed to match the naming schema of the status cache.
          predictionQuality: prediction.predictionQuality,
          predictionTime: prediction.startTime.millisecondsSinceEpoch ~/ 1000,
        ));
      } else {
        log.i("Received prediction from predictor: $json");
        prediction = PredictorPrediction.fromJson(json);
        calculateRecommendationFromPredictor();
        predictorPredictions.add(prediction);
        // Notify that a new prediction status was obtained.
        onNewPredictionStatusDuringRide?.call(SGStatusData(
          statusUpdateTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          thingName:
              "hamburg/${prediction.thingName}", // The prefix "hamburg/" is needed to match the naming schema of the status cache.
          predictionQuality: prediction.predictionQuality,
          predictionTime: prediction.referenceTime.millisecondsSinceEpoch ~/ 1000,
        ));
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
      notifyListeners();
    }

    if (prediction == null) return onFailure(null); // Fail silently.
    // Check the type of the prediction.
    if (prediction! is! PredictorPrediction) return onFailure("Prediction is of wrong type");

    prediction.calculateRecommendation();

    notifyListeners();
  }

  Future<void> calculateRecommendationFromPredictionService() async {
    if (!navigationIsActive) return;

    // This will be executed if we fail somewhere.
    onFailure(reason) {
      log.w("Failed to calculate predictor info: $reason");
      notifyListeners();
    }

    if (prediction == null) return onFailure("No prediction available");
    // Check the type of the prediction.
    if (prediction! is! PredictionServicePrediction) return onFailure("Prediction is of wrong type.");

    prediction.calculateRecommendation();

    notifyListeners();
  }

  /// Stop the navigation.
  Future<void> stopNavigation(BuildContext context) async {
    calcTimer?.cancel();
    calcTimer = null;
    client?.disconnect();
    client = null;
    navigationIsActive = false;
    onNewPredictionStatusDuringRide = null; // Don't call the callback anymore.
    notifyListeners();
  }

  /// Reset the service.
  Future<void> reset() async {
    route = null;
    navigationIsActive = false;
    if (client != null) {
      client?.disconnect();
      client = null;
    }
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
