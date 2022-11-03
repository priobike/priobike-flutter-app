import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/ride/messages/recommendation.dart';
import 'package:priobike/ride/messages/ride.dart';
import 'package:priobike/ride/messages/userposition.dart';
import 'package:priobike/ride/messages/navigation.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class Ride with ChangeNotifier {
  final log = Logger("Ride");

  /// A boolean indicating if the navigation is active.
  var navigationIsActive = false;

  /// The web socket channel to the backend.
  WebSocketChannel? socket;

  /// The peer used to communicate JSON RPC messages to the backend.
  Peer? jsonRPCPeer;

  /// The current recommendation from the server.
  Recommendation? currentRecommendation;

  /// The current predicted time of the next phase change, calculated periodically.
  /// Note: This is currently calculated in the recommendation as well, but
  /// may lag behind depending on the network latency / server time.
  DateTime? calcCurrentPhaseChangeTime;

  /// If the signal is currently predicted to be green, calculated periodically.
  /// Note: This is currently calculated in the recommendation as well, but
  /// may lag behind depending on the network latency / server time.
  bool? calcCurrentSignalIsGreen;

  /// A timer to periodically update the auxiliary recommendation info.
  /// The recommendation should arrive once a second. However, sometimes
  /// the network latency may be high, so we need to periodically update
  /// the auxiliary info.
  Timer? calcTimer;

  /// A timestamp when the last calculation was performed.
  /// This is used to prevent fast recurring calculations.
  DateTime? calcLastTime;

  /// The recorded recommendations of the ride.
  final recommendations = List<Recommendation>.empty(growable: true);

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  Ride({this.currentRecommendation});

  /// Reset the recommendation service.
  Future<void> reset() async {
    await stopNavigation();
    socket = null;
    jsonRPCPeer = null;
    currentRecommendation = null;
    recommendations.clear();
    needsLayout = {};
    calcTimer = null;
    notifyListeners();
  }

  /// A callback that is executed when the websocket closes.
  Future<void> onCloseWebsocket(BuildContext context) async {
    // If this is on purpose, we don't do anything.
    if (!navigationIsActive) return;
    // Otherwise, we attempt to reconnect.
    log.w("Reconnecting websocket after disconnect: ${socket?.closeCode} ${socket?.closeReason}");
    // Connect to the websocket channel.
    await Future.delayed(const Duration(milliseconds: 500), () => connectWebsocket(context));
  }

  /// A callback that is executed when a new recommendation arrives.
  Future<void> onNewRecommendation(Parameters params) async {
    if (!navigationIsActive) {
      log.w("Received recommendation while navigation is not active.");
      return;
    }
    try {
      currentRecommendation = Recommendation.fromJsonRPC(params);
      recommendations.add(currentRecommendation!);
      calculateRecommendationInfo();
      if (currentRecommendation!.error) {
        log.w("Recommendation arrived with set error: ${currentRecommendation!.toJson()}");
      } else {
        log.i("Got recommendation via websocket: ${currentRecommendation!.toJson()}");
      }
    } catch (error, stacktrace) {
      final hint = "Recommendation could not be decoded: $error";
      log.e(hint);
      if (!kDebugMode) {
        await Sentry.captureException(error, stackTrace: stacktrace, hint: hint);
      }
    }
  }

  /// Calculate auxiliary values for the current recommendation.
  Future<void> calculateRecommendationInfo() async {
    // Don't do a computation if the last one was recently done. Since we expect the countdown every 1s to change,
    // we can apply the shannon nyquist theorem here and only do a calculation every <0.5s.
    if (calcLastTime != null && calcLastTime!.difference(DateTime.now()).inMilliseconds.abs() < 499) return;
    calcLastTime = DateTime.now();

    // This will be executed if we fail somewhere.
    onFailure(reason) {
      log.w("Failed to calculate recommendation info: $reason");
      calcCurrentPhaseChangeTime = null;
      calcCurrentSignalIsGreen = null;
      notifyListeners();
    }

    // Check if we have all necessary information.
    if (currentRecommendation == null) return onFailure("No recommendation.");
    if (currentRecommendation!.error) return onFailure("Recommendation has error.");
    final greentimeThreshold = currentRecommendation!.predictionGreentimeThreshold;
    if (greentimeThreshold == null) return onFailure("No greentime threshold.");
    final vector = currentRecommendation!.predictionValue;
    if (vector == null || vector.isEmpty) return onFailure("No prediction vector.");
    final startTimeStr = currentRecommendation!.predictionStartTime;
    if (startTimeStr == null) return onFailure("No prediction start time.");

    // Decode the ISO 8601 timestamp.
    // Use this specific format: 2022-11-03T10:48:47Z[UTC]
    final startTime = DateTime.tryParse(startTimeStr.replaceAll("Z[UTC]", "Z"));
    if (startTime == null) return onFailure("Could not parse start time: $startTimeStr");
    // Calculate the seconds since the start of the prediction.
    final now = DateTime.now();
    final secondsSinceStart = now.difference(startTime).inSeconds;
    // Chop off the seconds that are not in the prediction vector.
    final secondsInVector = vector.length;
    if (secondsSinceStart >= secondsInVector) return onFailure("Prediction vector is too short.");
    // Calculate the current vector.
    final currentVector = vector.sublist(secondsSinceStart);
    if (currentVector.isEmpty) return onFailure("Current vector is empty.");
    // Calculate the seconds to the next phase change.
    int secondsToPhaseChange = 0;
    bool greenNow = currentVector[0] >= greentimeThreshold;
    for (int i = 1; i < currentVector.length; i++) {
      final greenThen = currentVector[i] >= greentimeThreshold;
      if ((greenNow && !greenThen) || (!greenNow && greenThen)) break;
      secondsToPhaseChange++;
    }
    // Calculate the predicted time of the next phase change.
    calcCurrentPhaseChangeTime = now.add(Duration(seconds: secondsToPhaseChange));
    calcCurrentSignalIsGreen = greenNow;

    notifyListeners();
  }

  /// Connect the websocket.
  Future<void> connectWebsocket(BuildContext context) async {
    // Get the session from the context and verify that it is active.
    final session = Provider.of<Session>(context, listen: false);
    if (!session.isActive()) return;
    // Connect the websocket.
    log.i("Connecting to session websocket.");
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    final wsUrl = "wss://$baseUrl/session-wrapper/websocket/sessions/${session.sessionId!}";
    socket = Http.connectWebSocket(Uri.parse(wsUrl));
    jsonRPCPeer = Peer(socket!.cast<String>());
    jsonRPCPeer!.listen().then((_) => onCloseWebsocket(context));
    jsonRPCPeer!.registerMethod("RecommendationUpdate", onNewRecommendation);
    log.i("Connected to session websocket.");
  }

  /// Select a new ride.
  Future<void> selectRide(BuildContext context, r.Route selectedRoute) async {
    // Get the session from the context and verify that it is active.
    final session = Provider.of<Session>(context, listen: false);
    if (!session.isActive()) return;

    // Select the ride.
    log.i("Selecting ride at the session service.");
    final selectRideRequest = SelectRideRequest(
        sessionId: session.sessionId!,
        route: selectedRoute.route,
        navigationPath: selectedRoute.path,
        signalGroups: {for (final signalGroup in selectedRoute.signalGroups) signalGroup.id: signalGroup});
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    final selectRideEndpoint = Uri.parse('https://$baseUrl/session-wrapper/ride');
    http.Response response =
        await Http.post(selectRideEndpoint, body: json.encode(selectRideRequest.toJson())).onError((error, stackTrace) {
      log.e("Error during select ride: $error");
      ToastMessage.showError(error.toString());
      throw Exception();
    });

    if (response.statusCode != 200) {
      final err = "Error during select ride with endpoint $selectRideEndpoint: ${response.body}";
      log.e(err);
      ToastMessage.showError(err);
      throw Exception(err);
    }

    try {
      final selectRideResponse = SelectRideResponse.fromJson(json.decode(response.body));
      if (!selectRideResponse.success) {
        throw Exception("Returned with success=false.");
      }
      log.i("Successfully selected ride with endpoint $selectRideEndpoint: ${response.body}");
    } catch (error, stack) {
      final hint = "Error during select ride: $error";
      if (!kDebugMode) {
        await Sentry.captureException(error, stackTrace: stack, hint: hint);
      }
      log.e(hint);
      ToastMessage.showError(hint);
      throw Exception(hint);
    }
  }

  /// Connect the websocket and start the navigation.
  Future<void> startNavigation(BuildContext context) async {
    // Do nothing if the navigation has already been started.
    if (navigationIsActive) return;
    // Mark that navigation is now active.
    navigationIsActive = true;
    // Connect to the websocket channel.
    await connectWebsocket(context);
    // Send a navigation request.
    final req = const NavigationRequest(active: true).toJson();
    log.i("Sending navigation request via websocket: $req");
    await jsonRPCPeer?.sendRequest("Navigation", req);
    // Start the timer that updates the current phase change time.
    // We check every 100 ms. If a recommendation gets missing, the countdown etc. will still be updated.
    // The method itself will check again if we do too many computations.
    calcTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => calculateRecommendationInfo());
  }

  /// Update the current user position and send it to the server.
  Future<void> updatePosition(BuildContext context) async {
    // Get the session from the context and verify that it is active.
    final session = Provider.of<Session>(context, listen: false);
    if (!session.isActive()) return;
    // Start the navigation if it isn't active.
    if (!navigationIsActive) await startNavigation(context);
    final positioning = Provider.of<Positioning>(context, listen: false);
    if (positioning.lastPosition == null) return;
    final position = positioning.lastPosition!;
    // Send the position update.
    final req = UserPosition(
      lat: position.latitude,
      lon: position.longitude,
      speed: position.speed,
      accuracy: position.accuracy,
      heading: position.heading,
      timestamp: position.timestamp,
    ).toJson();
    log.i("Sending user position via websocket: $req");
    jsonRPCPeer?.sendNotification('PositionUpdate', req);
  }

  /// End the navigation and disconnect the websocket.
  Future<void> stopNavigation() async {
    // Do nothing if the navigation has already been ended.
    if (!navigationIsActive) return;
    // Mark that navigation is inactive.
    navigationIsActive = false;
    // Send a navigation request.
    final req = const NavigationRequest(active: false).toJson();
    log.i("Sending navigation request via websocket: $req");
    await jsonRPCPeer?.sendRequest('Navigation', req);
    await jsonRPCPeer?.close();
    // Stop the calculation timer.
    calcTimer?.cancel();
  }

  @override
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}
