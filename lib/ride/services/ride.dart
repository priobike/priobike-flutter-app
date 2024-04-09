import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audio_session/audio_session.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route, Shortcuts;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/routing/models/instruction.dart';
import 'package:priobike/ride/services/prediction.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
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

  /// The prediction provider.
  PredictionProvider? predictionProvider;

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
  Future<void> selectSG(Sg? sg) async {
    if (!navigationIsActive) return;
    bool? unsubscribed = await predictionProvider?.selectSG(sg);

    if (unsubscribed ?? false) calcDistanceToNextSG = null;

    onSelectNextSignalGroup?.call(calcCurrentSG);
  }

  /// Callback that gets called when the prediction component client established a connection.
  Future<void> onPredictionComponentClientConnected() async {
    await predictionProvider!.selectSG(userSelectedSG ?? calcCurrentSG);
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

    // Connect the prediction service MQTT client.
    predictionProvider = PredictionProvider(
        onConnected: onPredictionComponentClientConnected,
        notifyListeners: notifyListeners,
        onNewPredictionStatusDuringRide: onNewPredictionStatusDuringRide);
    predictionProvider!.connectMQTTClient();

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

    // Also update the recommendation
    predictionProvider?.recalculateRecommendation();

    notifyListeners();
  }

  /// Check if instruction contains sg information and if so add countdown
  InstructionText? generateTextToPlay(InstructionText instructionText, double speed) {
    // Check if Not supported crossing
    // or we do not have all auxiliary data that the app calculated
    // or prediction quality is not good enough.
    if (calcCurrentSG == null ||
        predictionProvider?.recommendation == null ||
        (predictionProvider?.prediction?.predictionQuality ?? 0) < Ride.qualityThreshold) {
      // No sg countdown information can be added and thus instruction part must not be played.
      return null;
    }

    final recommendation = predictionProvider!.recommendation!;
    if (recommendation.calcCurrentPhaseChangeTime == null) {
      // If the phase change time is null, instruction part must not be played.
      return null;
    }

    Phase? currentColor = recommendation.calcCurrentSignalPhase;
    // Calculate the countdown.
    int countdown = recommendation.calcCurrentPhaseChangeTime!.difference(DateTime.now()).inSeconds;
    if (countdown < 0) {
      countdown = 0; // Must not be negative for later calculations.
    }
    Phase? nextColor;
    int durationNextPhase = -1;
    Phase? secondNextColor;
    int durationSecondNextPhase = -1;
    Phase? thirdNextColor;

    // The current phase ends at index countdown + 2.
    if (recommendation.calcPhasesFromNow.length > countdown + 2) {
      // Calculate the time and color of the next phase after the current phase.
      durationNextPhase = calcTimeToNextPhaseAfterIndex(countdown + 2) ?? -1;
      nextColor = recommendation.calcPhasesFromNow[countdown + 2];

      if (recommendation.calcPhasesFromNow.length > countdown + durationNextPhase + 2) {
        // Calculate the time and color of the second next phase after the current phase.
        durationSecondNextPhase = calcTimeToNextPhaseAfterIndex(countdown + durationNextPhase + 2) ?? -1;
        secondNextColor = recommendation.calcPhasesFromNow[countdown + durationNextPhase + 2];

        if (recommendation.calcPhasesFromNow.length > countdown + durationNextPhase + durationSecondNextPhase + 2) {
          // Calculate the color of the third next phase after the current phase.
          thirdNextColor =
              recommendation.calcPhasesFromNow[countdown + durationNextPhase + durationSecondNextPhase + 2];
        }
      }
    }

    // If the traffic light will turn to green
    // and can be arrived with current speed
    // the countdown will be announced.
    if (nextColor == Phase.green &&
        countdown + durationNextPhase >= instructionText.distanceToNextSg / speed &&
        countdown > 3) {
      // Add countdown information and timestamp.
      instructionText.addCountdown(countdown);
      instructionText.text = "${instructionText.text} grün in";
      return instructionText;
    }
    // If the traffic light will turn to green
    // and can be arrived with max speed of 25 km/h or current speed (if higher)
    // the countdown for turning red will be announced.
    else if (nextColor == Phase.green &&
        countdown + durationNextPhase >= instructionText.distanceToNextSg * 3.6 / max(25, speed) &&
        countdown + durationNextPhase > 3) {
      // Add countdown information and timestamp.
      instructionText.addCountdown(countdown + durationNextPhase);
      instructionText.text = "${instructionText.text} rot in";
      return instructionText;
    }
    // If the traffic light is green
    // and the countdown is higher than the time needed to arrive at the traffic light with 25 km/h or current speed (if higher)
    // it will be announced.
    else if (currentColor == Phase.green &&
        nextColor == Phase.red &&
        countdown >= instructionText.distanceToNextSg * 3.6 / max(25, speed) &&
        countdown > 3) {
      // Add countdown information and timestamp.
      instructionText.addCountdown(countdown);
      instructionText.text = "${instructionText.text} rot in";
      return instructionText;
    }
    // Otherwise check if the second cycle can be reached with a max speed of 25 km/h or current speed (if higher).
    else if (countdown + durationNextPhase >= instructionText.distanceToNextSg * 3.6 / max(25, speed)) {
      instructionText.addCountdown(countdown + durationNextPhase);
      switch (secondNextColor) {
        case Phase.red:
          instructionText.text = "${instructionText.text} rot in";
          return instructionText;
        case Phase.green:
          instructionText.text = "${instructionText.text} grün in";
          return instructionText;
        default:
          return null;
      }
    }
    // Otherwise check if the third cycle can be reached.
    else if (countdown + durationNextPhase + durationSecondNextPhase >=
        instructionText.distanceToNextSg * 3.6 / max(25, speed)) {
      instructionText.addCountdown(countdown + durationNextPhase + durationSecondNextPhase);
      switch (thirdNextColor) {
        case Phase.red:
          instructionText.text = "${instructionText.text} rot in";
          return instructionText;
        case Phase.green:
          instructionText.text = "${instructionText.text} grün in";
          return instructionText;
        default:
          return null;
      }
    }

    // No recommendation can be made, instruction part must not be played.
    return null;
  }

  /// Calculates the time to the next phase after the given index.
  int? calcTimeToNextPhaseAfterIndex(int index) {
    final recommendation = predictionProvider!.recommendation!;

    final phases = recommendation.calcPhasesFromNow.sublist(index, recommendation.calcPhasesFromNow.length - 1);
    final nextPhaseColor = phases.first;
    final indexNextPhaseEnd = phases.indexWhere((element) => element != nextPhaseColor);

    return indexNextPhaseEnd;
  }

  /// Configure the TTS.
  Future<void> initializeTTS() async {
    await ftts.setLanguage("de-DE");

    if (Platform.isIOS) {
      // Use siri voice if available.
      List<dynamic> voices = await ftts.getVoices;
      if (voices.any((element) => element["name"] == "Helena" && element["locale"] == "de-DE")) {
        await ftts.setVoice({
          "name": "Helena",
          "locale": "de-DE",
        });
      }

      await ftts.setSpeechRate(0.55); //speed of speech
      await ftts.setVolume(1); //volume of speech
      await ftts.setPitch(1); //pitch of sound
      await ftts.awaitSpeakCompletion(true);
      await ftts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.voicePrompt);
    } else {
      // Use siri voice if available.
      List<dynamic> voices = await ftts.getVoices;
      if (voices.any((element) => element["name"] == "de-DE-language" && element["locale"] == "de-DE")) {
        await ftts.setVoice({
          "name": "de-DE-language",
          "locale": "de-DE",
        });
      }

      await ftts.setSpeechRate(0.7); //speed of speech
      await ftts.setVolume(1); //volume of speech
      await ftts.setPitch(1); //pitch of sound
      await ftts.awaitSpeakCompletion(true);
    }
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

    final snap = getIt<Positioning>().snap;
    if (snap == null || route == null) return;

    // TODO: check how much inaccuracy between current point and instruction point is ok (20m?)
    Instruction? currentInstruction = route!.instructions.firstWhereOrNull(
        (element) => !element.executed && vincenty.distance(LatLng(element.lat, element.lon), snap.position) < 20);

    if (currentInstruction != null) {
      currentInstruction.executed = true;

      Iterator it = currentInstruction.text.iterator;
      while (it.moveNext()) {
        // Put this here to avoid music interruption in case that there is no instruction to play.
        await session.setActive(true);
        if (it.current.type == InstructionTextType.direction) {
          // No countdown information needs to be added.
          print(it.current.text);
          await ftts.speak(it.current.text);
        } else {
          final speed = getIt<Positioning>().lastPosition?.speed ?? 0;
          // Check for countdown information.
          var instructionTextToPlay = generateTextToPlay(it.current, speed);
          if (instructionTextToPlay == null) {
            continue;
          }
          print(instructionTextToPlay.text);
          await ftts.speak(instructionTextToPlay.text);
          // Calc updatedCountdown since initial creation and time that has passed while speaking
          // (to avoid countdown inaccuracy)
          // Also take into account 1s delay for actually speaking the countdown.
          int updatedCountdown = instructionTextToPlay.countdown! -
              (DateTime.now().difference(instructionTextToPlay.countdownTimeStamp!).inSeconds) -
              1;
          print(updatedCountdown.toString());
          await ftts.speak(updatedCountdown.toString());
        }
      }
      await session.setActive(false);
    }
  }

  /// Stop the navigation.
  Future<void> stopNavigation() async {
    if (predictionProvider != null) predictionProvider!.stopNavigation();
    navigationIsActive = false;
    onNewPredictionStatusDuringRide = null; // Don't call the callback anymore.
    notifyListeners();
  }

  /// Reset the service.
  Future<void> reset() async {
    route = null;
    navigationIsActive = false;
    await predictionProvider?.reset();
    predictionProvider = null;
    userSelectedSG = null;
    userSelectedSGIndex = null;
    calcCurrentSG = null;
    calcCurrentSGIndex = null;
    calcNextConnectedSGIndex = null;
    calcDistanceToNextSG = null;
    notifyListeners();
  }
}
