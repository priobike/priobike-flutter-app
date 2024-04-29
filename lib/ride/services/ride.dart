import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route, Shortcuts;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/prediction.dart';
import 'package:priobike/routing/models/instruction.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
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

  /// The prediction provider.
  PredictionProvider? predictionProvider;

  /// List of Waypoints if the last ride got killed by the os.
  List<Waypoint>? lastRoute;

  /// Selected Route id if the last ride got killed by the os.
  int lastRouteID = 0;

  /// An instance for text-to-speach.
  FlutterTts? ftts;

  /// A map that holds information about the last recommendation to check the difference when a new recommendation is received.
  Map<String, Object> lastRecommendation = {};

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
  Future<void> startNavigation() async {
    // Do nothing if the navigation has already been started.
    if (navigationIsActive) return;

    // Connect the prediction service MQTT client.
    predictionProvider = PredictionProvider(
      onConnected: onPredictionComponentClientConnected,
      notifyListeners: notifyListeners,
    );
    predictionProvider!.connectMQTTClient();

    // Mark that navigation is now active.
    sessionId = UniqueKey().toString();
    navigationIsActive = true;
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
  InstructionText? _generateTextToPlay(InstructionText instructionText, double speed) {
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

    Phase? currentPhase = recommendation.calcCurrentSignalPhase;
    // Calculate the countdown.
    int countdown = recommendation.calcCurrentPhaseChangeTime!.difference(DateTime.now()).inSeconds;
    if (countdown < 0) {
      countdown = 0; // Must not be negative for later calculations.
    }

    // Save the current recommendation information for comparison with updates later.
    lastRecommendation.clear();
    lastRecommendation = {'phase': currentPhase, 'countdown': countdown, 'timestamp': DateTime.now()};

    Phase? nextPhase;
    int durationNextPhase = -1;
    Phase? secondNextPhase;

    // The current phase ends at index countdown + 2.
    if (recommendation.calcPhasesFromNow.length > countdown + 2) {
      // Calculate the time and color of the next phase after the current phase.
      durationNextPhase = _calcTimeToNextPhaseAfterIndex(countdown + 2) ?? -1;
      nextPhase = recommendation.calcPhasesFromNow[countdown + 2];

      if (recommendation.calcPhasesFromNow.length > countdown + durationNextPhase + 2) {
        // Calculate the color of the second next phase after the current phase.
        secondNextPhase = recommendation.calcPhasesFromNow[countdown + durationNextPhase + 2];
      }
    }

    if (currentPhase == Phase.green && nextPhase == Phase.red) {
      if (countdown >= instructionText.distanceToNextSg / max(25, speed) && countdown > 3) {
        // The traffic light is green and can be crossed with the max of current speed or 25km/h.
        // before turning red.
        instructionText.addCountdown(countdown);
        instructionText.text = "${instructionText.text} rot in";
        return instructionText;
      } else if ((secondNextPhase == Phase.green &&
          instructionText.distanceToNextSg * 3.6 / (countdown + durationNextPhase) >= 8 &&
          countdown + durationNextPhase > 3)) {
        // The traffic light will turn red and then green again
        // and can be crossed with a minimum speed of 8km/h without stopping.
        instructionText.addCountdown(countdown + durationNextPhase);
        instructionText.text = "${instructionText.text} grün in";
        return instructionText;
      } else if (countdown > 3) {
        // Let the user know when the traffic light is going to turn red.
        instructionText.addCountdown(countdown);
        instructionText.text = "${instructionText.text} rot in";
        return instructionText;
      } else if (countdown + durationNextPhase > 3) {
        // Let the user know when the traffic light is going to turn green again.
        instructionText.addCountdown(countdown + durationNextPhase);
        instructionText.text = "${instructionText.text} grün in";
        return instructionText;
      }
    } else if (nextPhase == Phase.green) {
      if (countdown + durationNextPhase >= instructionText.distanceToNextSg / speed && countdown > 3) {
        // The traffic light will turn green and can be crossed with the current speed.
        instructionText.addCountdown(countdown);
        instructionText.text = "${instructionText.text} grün in";
        return instructionText;
      } else if (secondNextPhase == Phase.red && countdown + durationNextPhase > 3) {
        // Let the user know when the traffic light is going to turn red.
        instructionText.addCountdown(countdown + durationNextPhase);
        instructionText.text = "${instructionText.text} rot in";
        return instructionText;
      }
    }

    // No recommendation can be made.
    return null;
  }

  /// Calculates the time to the next phase after the given index.
  int? _calcTimeToNextPhaseAfterIndex(int index) {
    final recommendation = predictionProvider!.recommendation!;

    final phases = recommendation.calcPhasesFromNow.sublist(index, recommendation.calcPhasesFromNow.length - 1);
    final nextPhaseColor = phases.first;
    final indexNextPhaseEnd = phases.indexWhere((element) => element != nextPhaseColor);

    return indexNextPhaseEnd;
  }

  /// Configure the TTS.
  Future<void> initializeTTS() async {
    ftts = FlutterTts();

    if (Platform.isIOS) {
      // Use siri voice if available.
      List<dynamic> voices = await ftts!.getVoices;
      if (voices.any((element) => element["name"] == "Helena" && element["locale"] == "de-DE")) {
        await ftts!.setVoice({
          "name": "Helena",
          "locale": "de-DE",
        });
      }

      await ftts!.setSpeechRate(0.55); //speed of speech
      await ftts!.setVolume(1); //volume of speech
      await ftts!.setPitch(1); //pitch of sound
      await ftts!.awaitSpeakCompletion(true);
      await ftts!.autoStopSharedSession(false);

      await ftts!.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.duckOthers,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP
      ]);
    } else {
      // Use android voice if available.
      List<dynamic> voices = await ftts!.getVoices;
      if (voices.any((element) => element["name"] == "de-DE-language" && element["locale"] == "de-DE")) {
        await ftts!.setVoice({
          "name": "de-DE-language",
          "locale": "de-DE",
        });
      }

      await ftts!.setSpeechRate(0.7); //speed of speech
      await ftts!.setVolume(1); //volume of speech
      await ftts!.setPitch(1); //pitch of sound
      await ftts!.awaitSpeakCompletion(true);
    }
  }

  /// Play audio instruction.
  Future<void> playAudioInstruction() async {
    final snap = getIt<Positioning>().snap;
    if (snap == null || route == null) return;
    if (ftts == null) return;

    Instruction? currentInstruction = route!.instructions.firstWhereOrNull(
        (element) => !element.executed && vincenty.distance(LatLng(element.lat, element.lon), snap.position) < 20);

    if (currentInstruction != null) {
      currentInstruction.executed = true;

      Iterator it = currentInstruction.text.iterator;
      while (it.moveNext()) {
        // Put this here to avoid music interruption in case that there is no instruction to play.
        if (it.current.type == InstructionTextType.direction) {
          // No countdown information needs to be added.
          await ftts!.speak(it.current.text);
        } else {
          final speed = getIt<Positioning>().lastPosition?.speed ?? 0;
          // Check for countdown information.
          var instructionTextToPlay = _generateTextToPlay(it.current, speed);
          if (instructionTextToPlay == null) {
            continue;
          }
          await ftts!.speak(instructionTextToPlay.text);
          // Calc updatedCountdown since initial creation and time that has passed while speaking
          // (to avoid countdown inaccuracy)
          // Also take into account 1s delay for actually speaking the countdown.
          int updatedCountdown = instructionTextToPlay.countdown! -
              (DateTime.now().difference(instructionTextToPlay.countdownTimeStamp!).inSeconds) -
              1;
          await ftts!.speak(updatedCountdown.toString());
        }
      }
    }
  }

  void playNewPredictionStatusInformation() async {
    if (ftts == null) return;
    // Check if Not supported crossing
    // or we do not have all auxiliary data that the app calculated
    // or prediction quality is not good enough.
    if (calcCurrentSG == null ||
        predictionProvider?.recommendation == null ||
        (predictionProvider?.prediction?.predictionQuality ?? 0) < Ride.qualityThreshold) {
      // No sg countdown information can be added and thus instruction part must not be played.
      return;
    }

    // Check if the prediction is a recommendation for the next traffic light on the route
    // and do not play instruction if this is not the case.
    final thingName = predictionProvider?.status?.thingName;
    bool isRecommendation = thingName != null ? calcCurrentSG!.id == thingName : false;
    if (!isRecommendation) return;

    // If the phase change time is null, instruction part must not be played.
    final recommendation = predictionProvider!.recommendation!;
    if (recommendation.calcCurrentPhaseChangeTime == null) return;

    // If there is only one color, instruction part must not be played.
    final uniqueColors = recommendation.calcPhasesFromNow.map((e) => e.color).toSet();
    if (uniqueColors.length == 1) return;

    // Do not play instruction part for amber or redamber.
    if (recommendation.calcCurrentSignalPhase == Phase.amber) return;
    if (recommendation.calcCurrentSignalPhase == Phase.redAmber) return;

    Phase? currentPhase = recommendation.calcCurrentSignalPhase;
    // Calculate the countdown.
    int countdown = recommendation.calcCurrentPhaseChangeTime!.difference(DateTime.now()).inSeconds;
    // Do not play instruction if countdown < 5.
    if (countdown < 5) return;
    Phase? nextPhase;

    // The current phase ends at index countdown + 2.
    if (recommendation.calcPhasesFromNow.length > countdown + 2) {
      // Calculate the color of the next phase after the current phase.
      nextPhase = recommendation.calcPhasesFromNow[countdown + 2];
    }

    // Check if the recommendation phase has changed.
    bool hasPhaseChanged =
        lastRecommendation['phase'] == null ? true : lastRecommendation['phase'] as Phase != currentPhase;
    // Check if the countdown has changed more than 3 seconds.
    bool hasSignificantTimeChange;
    int? lastCountdown = lastRecommendation['countdown'] as int?;
    if (lastCountdown != null) {
      int lastTimeDifference = DateTime.now().difference(lastRecommendation['timestamp'] as DateTime).inSeconds;
      hasSignificantTimeChange = ((lastCountdown - lastTimeDifference) - countdown).abs() > 3;
    } else {
      hasSignificantTimeChange = true;
    }

    bool closeToInstruction;
    final snap = getIt<Positioning>().snap;
    if (snap == null) {
      closeToInstruction = false;
    } else {
      var distanceToSg =
          vincenty.distance(snap.position, LatLng(calcCurrentSG!.position.lat, calcCurrentSG!.position.lon));
      if (distanceToSg > 500) {
        // Do not play instruction if the distance to the sg is more than 500m.
        return;
      }

      // Check if the current position is in a radius of 50m of an instruction that contains sg information.
      var nextInstruction = route!.instructions.firstWhereOrNull((element) =>
          (element.instructionType != InstructionType.directionOnly) &&
          vincenty.distance(LatLng(element.lat, element.lon), snap.position) < 50);
      closeToInstruction = nextInstruction != null;
    }

    if (!closeToInstruction && (hasPhaseChanged || hasSignificantTimeChange)) {
      var instructionTimeStamp = DateTime.now();

      // Save the current recommendation information for comparison with updates later BEFORE playing the instruction.
      lastRecommendation.clear();
      lastRecommendation = {'phase': currentPhase, 'countdown': countdown, 'timestamp': instructionTimeStamp};

      // Cannot make a recommendation if the next phase is not known.
      if (nextPhase == null) return;

      String sgType = (calcCurrentSG!.laneType == "Radfahrer") ? "Radampel" : "Ampel";
      InstructionText instructionText =
          InstructionText(text: "Nächste $sgType", type: InstructionTextType.signalGroup, distanceToNextSg: 0);
      final speed = getIt<Positioning>().lastPosition?.speed ?? 0;
      var textToPlay = _generateTextToPlay(instructionText, speed);
      if (textToPlay == null) return;
      await ftts!.speak(textToPlay.text);
      // Calc updatedCountdown since initial creation and time that has passed while speaking
      // (to avoid countdown inaccuracy)
      // Also take into account 1s delay for actually speaking the countdown.
      int updatedCountdown =
          textToPlay.countdown! - (DateTime.now().difference(textToPlay.countdownTimeStamp!).inSeconds) - 1;
      await ftts!.speak(updatedCountdown.toString());
    } else {
      // Nevertheless save the current recommendation information for comparison with updates later.
      lastRecommendation.clear();
      lastRecommendation = {'phase': currentPhase, 'countdown': countdown, 'timestamp': DateTime.timestamp()};
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
