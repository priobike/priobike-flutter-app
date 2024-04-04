import 'dart:async';
import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route, Shortcuts;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/interfaces/prediction_component.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/hybrid_predictor.dart';
import 'package:priobike/ride/services/prediction_service.dart';
import 'package:priobike/ride/services/predictor.dart';
import 'package:priobike/routing/models/instruction.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// The currently selected route.
  Route? route;

  /// The current signal group, calculated periodically.
  Sg? calcCurrentSG;

  /// The signal group that the user wants to see.
  Sg? userSelectedSG;

  /// The current signal group index, calculated periodically.
  int? calcCurrentSGIndex;

  /// The next connected signal group index, calculated periodically.
  int? calcNextConnectedSGIndex;

  /// The current signal group index, selected by the user.
  int? userSelectedSGIndex;

  /// The calculated distance to the next signal group.
  double? calcDistanceToNextSG;

  /// The calculated distance to the next turn.
  double? calcDistanceToNextTurn;

  /// The session id, set randomly by `startNavigation`.
  String? sessionId;

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  void Function(SGStatusData)? onNewPredictionStatusDuringRide;

  /// The wrapper-service for the used prediction mode.
  PredictionComponent? predictionComponent;

  /// List of Waypoints if the last ride got killed by the os.
  List<Waypoint>? lastRoute;

  /// Selected Route id if the last ride got killed by the os.
  int lastRouteID = 0;

  /// An instance for text-to-speach.
  FlutterTts ftts = FlutterTts();

  static const lastRouteKey = "priobike.ride.lastRoute";
  static const lastRouteIDKey = "priobike.ride.lastRouteID";

  /// Set the last route in shared preferences.
  Future<bool> setLastRoute(List<Waypoint> lastRoute, int lastRouteID, [SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    final prevLastRoute = this.lastRoute;
    final prevLastRouteID = this.lastRouteID;
    this.lastRoute = lastRoute;
    this.lastRouteID = lastRouteID;
    List<String> jsonList = lastRoute.map((Waypoint waypoint) => jsonEncode(waypoint.toJSON())).toList();
    bool success = await storage.setStringList(lastRouteKey, jsonList);
    success = success && await storage.setInt(lastRouteIDKey, lastRouteID);
    if (!success) {
      log.e("Failed to set lastRoute to $lastRoute");
      this.lastRoute = prevLastRoute;
      this.lastRouteID = prevLastRouteID;
    } else {
      notifyListeners();
    }
    return success;
  }

  /// Remove the last route from shared preferences.
  Future<bool> removeLastRoute([SharedPreferences? storage]) async {
    storage ??= await SharedPreferences.getInstance();
    lastRoute = null;
    lastRouteID = 0;
    bool success = await storage.remove(lastRouteKey);
    success = success && await storage.remove(lastRouteIDKey);
    if (!success) {
      log.e("Failed to remove lastRoute");
    } else {
      notifyListeners();
    }
    return success;
  }

  /// Load the last route from shared preferences.
  Future<void> loadLastRoute() async {
    final storage = await SharedPreferences.getInstance();
    try {
      List<String>? jsonList = storage.getStringList(lastRouteKey);
      int? lastRouteID = storage.getInt(lastRouteIDKey);
      if (jsonList != null && lastRouteID != null) {
        lastRoute = jsonList.map((e) => Waypoint.fromJson(jsonDecode(e))).toList();
        this.lastRouteID = lastRouteID;
      }
    } catch (e) {
      /* Do nothing. */
    }
  }

  /// Subscribe to the signal group.
  void selectSG(Sg? sg) {
    if (!navigationIsActive) return;
    bool? unsubscribed = predictionComponent?.selectSG(sg);

    if (unsubscribed ?? false) calcDistanceToNextSG = null;

    onSelectNextSignalGroup?.call(calcCurrentSG);
  }

  /// Callback that gets called when the prediction component client established a connection.
  void onPredictionComponentClientConnected() {
    predictionComponent!.selectSG(userSelectedSG ?? calcCurrentSG);
  }

  /// Select the next signal group.
  /// Forward is step = 1, backward is step = -1.
  void jumpToSG({required int step}) {
    if (route == null) return;
    if (route!.signalGroups.isEmpty) return;
    if (userSelectedSGIndex == null && calcNextConnectedSGIndex == null) {
      // If there is no next signal group, select the first one if moving forward.
      // If moving backward, select the last one.
      userSelectedSGIndex = step > 0 ? 0 : route!.signalGroups.length - 1;
    } else if (userSelectedSGIndex == null) {
      // User did not manually select a signal group yet.
      userSelectedSGIndex = (calcNextConnectedSGIndex! + step) % route!.signalGroups.length;
    } else {
      // User manually selected a signal group.
      userSelectedSGIndex = (userSelectedSGIndex! + step) % route!.signalGroups.length;
    }
    userSelectedSG = route!.signalGroups[userSelectedSGIndex!];
    selectSG(userSelectedSG);
    notifyListeners();
  }

  /// Select SG with specific index in the list of SGs.
  void userSelectSG(int sgIndex) {
    if (route == null) return;
    if (route!.signalGroups.isEmpty) return;
    userSelectedSGIndex = sgIndex;
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
  Future<void> selectRoute(Route route) async {
    this.route = route;
    notifyListeners();
  }

  /// Start the navigation and connect the MQTT client.
  Future<void> startNavigation(Function(SGStatusData)? onNewPredictionStatusDuringRide) async {
    // Do nothing if the navigation has already been started.
    if (navigationIsActive) return;

    final settings = getIt<Settings>();
    final predictionMode = settings.predictionMode;
    if (predictionMode == PredictionMode.usePredictionService) {
      // Connect the prediction service MQTT client.
      predictionComponent = PredictionService(
          onConnected: onPredictionComponentClientConnected,
          notifyListeners: notifyListeners,
          onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide);
      predictionComponent!.connectMQTTClient();
    } else if (predictionMode == PredictionMode.usePredictor) {
      // Connect the predictor MQTT client.
      predictionComponent = Predictor(
          onConnected: onPredictionComponentClientConnected,
          notifyListeners: notifyListeners,
          onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide);
      predictionComponent!.connectMQTTClient();
    } else {
      // Hybrid mode -> connect both clients.
      predictionComponent = HybridPredictor(
          notifyListeners: notifyListeners, onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide);
      predictionComponent!.connectMQTTClient();
    }

    // Mark that navigation is now active.
    sessionId = UniqueKey().toString();
    navigationIsActive = true;
    // Notify listeners of a new sg status update.
    this.onNewPredictionStatusDuringRide = onNewPredictionStatusDuringRide;
  }

  /// Update the position.
  Future<void> updatePosition() async {
    if (!navigationIsActive) return;

    final snap = getIt<Positioning>().snap;
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
    Sg? previousSg;
    int? previousSgIndex;
    double routeDistanceOfPreviousSg = 0;
    // Sometimes the GPS position may unintendedly jump after the signal group. If the user
    // is slow (< 2 m/s) and the previous signal group is < 10m away, we use the signal group
    // that is closer to the user. Otherwise we just use the next upcoming signal group on the route.
    final speed = getIt<Positioning>().lastPosition?.speed ?? 0;
    for (int i = 0; i < route!.signalGroups.length; i++) {
      final routeDistanceSg = route!.signalGroupsDistancesOnRoute[i];
      if (speed < 2) {
        // Get the previous signal group closest to the user if it exists.
        if (routeDistanceSg < snap.distanceOnRoute) {
          if (routeDistanceSg > routeDistanceOfPreviousSg) {
            previousSg = route!.signalGroups[i];
            previousSgIndex = i;
            routeDistanceOfPreviousSg = routeDistanceSg;
          }
        }
      }
      // Get the next upcoming signal group on the route.
      if (routeDistanceSg > snap.distanceOnRoute) {
        nextSg = route!.signalGroups[i];
        nextSgIndex = i;
        calcNextConnectedSGIndex = i;
        routeDistanceOfNextSg = route!.signalGroupsDistancesOnRoute[i];
        break;
      }
    }
    if (previousSg != null &&
        (routeDistanceOfPreviousSg - snap.distanceOnRoute).abs() < 10 &&
        (routeDistanceOfPreviousSg - snap.distanceOnRoute).abs() <
            (routeDistanceOfNextSg - snap.distanceOnRoute).abs()) {
      nextSg = previousSg;
      nextSgIndex = previousSgIndex;
      routeDistanceOfNextSg = routeDistanceOfPreviousSg;
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

  /// Check if instruction contains sg information and if so add countdown
  InstructionText? generateTextToPlay(InstructionText instructionText) {
    // Check if Not supported crossing
    // or we do not have all auxiliary data that the app calculated
    // or prediction quality is not good enough.
    if (calcCurrentSG == null ||
        predictionComponent?.recommendation == null ||
        (predictionComponent?.prediction?.predictionQuality ?? 0) < Ride.qualityThreshold) {
      // No sg countdown information can be added and thus instruction part must not be played.
      return null;
    }

    final recommendation = predictionComponent!.recommendation!;

    if (recommendation.calcCurrentPhaseChangeTime == null) {
      // If the phase change time is null, instruction part must not be played.
      return null;
    }

    // Calculate the countdown.
    final countdown = recommendation.calcCurrentPhaseChangeTime!.difference(DateTime.now()).inSeconds;

    // TODO: check this (should wait for next cycle?)
    // If the countdown is less or equal to 5, instruction part must not be played.
    if (countdown <= 5) {
      return null;
    }

    // TODO: check this
    final currentPhase = recommendation.calcCurrentSignalPhase;
    String nextColor = "";
    if (currentPhase == Phase.red) {
      nextColor = "grün";
    } else if (currentPhase == Phase.green) {
      nextColor = "rot";
    } else {
      // If the next color cannot be determined, instruction part must not be played.
      return null;
    }

    // Add countdown information and timestamp.
    instructionText.addCountdown(countdown);
    // Add information about nextColor of the sg;
    instructionText.text = "${instructionText.text} $nextColor in";
    if (nextColor.isNotEmpty) {
      return instructionText;
    }
    // If information about nextColor is not available, instruction part must not be played.
    return null;
  }

  /// Configure the TTS.
  Future<void> initializeTTS() async {
    await ftts.setSpeechRate(0.8); //speed of speech
    await ftts.setVolume(1); //volume of speech
    await ftts.setPitch(1); //pitch of sound
    await ftts.awaitSpeakCompletion(true);
  }

  /// Play audio instruction.
  Future<void> playAudioInstruction() async {
    // Register the audio session.
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.assistanceNavigationGuidance,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientExclusive,
        androidWillPauseWhenDucked: false, // Verhindert, dass Spotify automatisch pausiert
      ),
    );
    // await ftts.awaitSpeakCompletion(true);

    final snap = getIt<Positioning>().snap;
    if (snap == null || route == null) return;

    // TODO: check how much inaccuracy between current point and instruction point is ok (20m?)
    Instruction? currentInstruction = route!.instructions.firstWhereOrNull((element) => !element.executed &&
        vincenty.distance(LatLng(element.lat, element.lon), snap.position) < 20);

    if (currentInstruction != null){
      currentInstruction.executed = true;

      Iterator it = currentInstruction.text.iterator;
      while(it.moveNext()) {
        // Put this here to avoid music interruption in case that there is no instruction to play.
        await session.setActive(true);
        if (it.current.type == InstructionTextType.direction) {
          // No countdown information needs to be added.
          await ftts.speak(it.current.text);
        } else {
          // Check for countdown information.
          var instructionTextToPlay = generateTextToPlay(it.current);
          if (instructionTextToPlay == null) {
            continue;
          }
          await ftts.speak(instructionTextToPlay!.text);
          // Calc updatedCountdown since initial creation and time that has passed while speaking
          // (to avoid countdown inaccuracy)
          // Also take into account 1s delay for actually speaking the countdown.
          int updatedCountdown = instructionTextToPlay.countdown! - (DateTime.now().difference(instructionTextToPlay.countdownTimeStamp!).inSeconds) - 1;
          await ftts.speak(updatedCountdown.toString());
        }
      }
      await session.setActive(false);
    }
  }

  /// Stop the navigation.
  Future<void> stopNavigation() async {
    if (predictionComponent != null) predictionComponent!.stopNavigation();
    navigationIsActive = false;
    onNewPredictionStatusDuringRide = null; // Don't call the callback anymore.
    notifyListeners();
  }

  /// Reset the service.
  Future<void> reset() async {
    route = null;
    navigationIsActive = false;
    await predictionComponent?.reset();
    predictionComponent = null;
    userSelectedSG = null;
    userSelectedSGIndex = null;
    calcCurrentSG = null;
    calcCurrentSGIndex = null;
    calcNextConnectedSGIndex = null;
    calcDistanceToNextSG = null;
    notifyListeners();
  }
}
