import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/instruction.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/settings/services/settings.dart';

class Audio {
  /// An instance for text-to-speach.
  FlutterTts? ftts;

  /// The positioning service instance.
  Ride? ride;

  /// The settings service instance.
  Settings? settings;

  /// The positioning service instance.
  Positioning? positioning;

  /// Whether the audio service is initialized.
  bool initialized = false;

  /// A map that holds information about the last recommendation to check the difference when a new recommendation is received.
  Map<String, Object> lastRecommendation = {};

  /// The current route.
  Route? currentRoute;

  /// The last signal group id for which a wait for green info was played.
  String? didPlayWaitForGreenInfoForSg;

  /// Constructor.
  Audio() {
    settings = getIt<Settings>();
    settings!.addListener(_processSettingsUpdates);

    if (settings!.audioInstructionsEnabled) {
      initialized = true;
      _init();
    }
  }

  /// Init the audio service.
  Future<void> _init() async {
    ride ??= getIt<Ride>();
    ride!.addListener(_processRideUpdates);
    positioning ??= getIt<Positioning>();
    positioning!.addListener(_processPositioningUpdates);
  }

  /// Clean up the audio instructions feature.
  Future<void> cleanUp() async {
    ride = null;
    positioning?.removeListener(_processPositioningUpdates);
    positioning = null;
    await resetFTTS();
    lastRecommendation.clear();
  }

  /// Reset the complete audio service.
  Future<void> reset() async {
    settings?.removeListener(_processSettingsUpdates);
    settings = null;
    await cleanUp();
  }

  /// Check for rerouting.
  Future<void> _processRideUpdates() async {
    if (ride?.navigationIsActive != true) return;
    if (ride?.route == null) return;
    // If the current route is null, we won't see a rerouting but the first route.
    if (currentRoute == null) {
      currentRoute = ride!.route;
      return;
    }
    // Rerouting
    if (currentRoute != ride!.route && ride?.route != null) {
      currentRoute = ride?.route;
      if (ftts == null) await _initializeTTS();
      ftts?.speak("Neue Route berechnet");
    }

    // check phase change things TODO.
  }

  /// Check if the audio instructions setting has changed.
  Future<void> _processSettingsUpdates() async {
    if (initialized && !settings!.audioInstructionsEnabled) {
      initialized = false;
      cleanUp();
    } else if (!initialized && settings!.audioInstructionsEnabled) {
      initialized = true;
      _init();
    }
  }

  /// Reset the text-to-speach instance.
  Future<void> resetFTTS() async {
    await ftts?.pause();
    await ftts?.stop();
    await ftts?.clearVoice();
    ftts = null;
  }

  /// Process positioning updates to play audio instructions.
  Future<void> _processPositioningUpdates() async {
    if (settings?.audioInstructionsEnabled != true) {
      return;
    }
    if (ride?.navigationIsActive != true) {
      return;
    }
    if (ftts == null) {
      await _initializeTTS();
    }

    if (settings?.audioRoutingInstructionsEnabled == true) {
      await _playAudioRoutingInstruction();
    } else {
      // TODO create speed advisory only instructions.
    }

    _checkPlayCountdownWhenWaitingForGreen();
  }

  /// Check if instruction contains sg information and if so add countdown
  InstructionText? _generateTextToPlay(InstructionText instructionText, double speed) {
    // Check if Not supported crossing
    // or we do not have all auxiliary data that the app calculated
    // or prediction quality is not good enough.
    ride ??= getIt<Ride>();

    if (ride!.calcCurrentSG == null ||
        ride!.predictionProvider?.recommendation == null ||
        (ride!.predictionProvider?.prediction?.predictionQuality ?? 0) < Ride.qualityThreshold) {
      // No sg countdown information can be added and thus instruction part must not be played.
      return null;
    }

    final recommendation = ride!.predictionProvider!.recommendation!;
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
          instructionText.distanceToNextSg * 3.6 / (countdown + durationNextPhase) >= 7 &&
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

  /// Checks if the user is at slow speed or standing still close to a traffic light and plays a countdown for the next traffic light when waiting for green.
  void _checkPlayCountdownWhenWaitingForGreen() async {
    ride ??= getIt<Ride>();

    final speed = getIt<Positioning>().lastPosition?.speed ?? 0;
    if (speed > 7) {
      // All speed over 7 km/h is considered normal driving.
      return;
    }

    if (ftts == null) return;
    // Check if Not supported crossing
    // or we do not have all auxiliary data that the app calculated
    // or prediction quality is not good enough.
    if (ride!.calcCurrentSG == null ||
        ride!.predictionProvider?.recommendation == null ||
        (ride!.predictionProvider?.prediction?.predictionQuality ?? 0) < Ride.qualityThreshold) {
      // No sg countdown information can be added and thus instruction part must not be played.
      return;
    }

    // Check if the prediction is a recommendation for the next traffic light on the route
    // and do not play instruction if this is not the case.
    final thingName = ride!.predictionProvider?.status?.thingName;
    bool isRecommendation = thingName != null ? ride!.calcCurrentSG!.id == thingName : false;
    if (!isRecommendation) return;

    // If the phase change time is null, instruction part must not be played.
    final recommendation = ride!.predictionProvider!.recommendation!;
    if (recommendation.calcCurrentPhaseChangeTime == null) return;

    // Find out if the current phase is not green and the next phase is green.
    if (recommendation.calcPhasesFromNow[0] != Phase.green) return;

    // If there is only one color, instruction part must not be played.
    final uniqueColors = recommendation.calcPhasesFromNow.map((e) => e.color).toSet();
    if (uniqueColors.length == 1) return;

    // Get the countdown.
    int countdown = recommendation.calcCurrentPhaseChangeTime!.difference(DateTime.now()).inSeconds;

    // Do not play instruction if countdown < 5.
    if (countdown < 5) return;

    final snap = getIt<Positioning>().snap;
    if (snap == null) return;
    var distOnRoute = snap.distanceOnRoute;
    var idx = currentRoute!.signalGroups.indexWhere((element) => element.id == ride!.calcCurrentSG!.id);
    var distSgOnRoute = 0.0;
    if (idx != -1) {
      distSgOnRoute = currentRoute!.signalGroupsDistancesOnRoute[idx];
    } else {
      // Do not play instruction if the sg is not on the route.
      return;
    }
    var distanceToSg = distSgOnRoute - distOnRoute;
    if (distanceToSg > 25) {
      // Do not play instruction if the distance to the sg is more than 25m.
      return;
    }

    await ftts!.speak("Grün in ");
    // Calc updatedCountdown since initial creation and time that has passed while speaking
    // (to avoid countdown inaccuracy)
    // Also take into account 1s delay for actually speaking the countdown.
    countdown = recommendation.calcCurrentPhaseChangeTime!.difference(DateTime.now()).inSeconds;

    await ftts!.speak(countdown.toString());

    // TODO start the timer and cancel it, if phase changes.

    didPlayWaitForGreenInfoForSg = ride!.calcCurrentSG!.id;
  }

  /// Check distance between current position and next sg.
  double? calcDistanceBetweenPositionAndNextSg(LatLng currentPosition) {
    var currentPosOnRoute = currentRoute!.route.firstWhereOrNull(
        (element) => element.lat == currentPosition.latitude && element.lon == currentPosition.longitude);

    if (currentPosOnRoute == null) {
      return currentPosOnRoute?.distanceToNextSignal;
    }
    return null;
  }

  /// Configure the TTS.
  Future<void> _initializeTTS() async {
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

  /// Play audio routing instruction.
  Future<void> _playAudioRoutingInstruction() async {
    ride ??= getIt<Ride>();
    positioning ??= getIt<Positioning>();
    if (positioning!.snap == null || ride!.route == null) return;
    if (ftts == null) return;

    Instruction? currentInstruction = ride!.route!.instructions.firstWhereOrNull((element) =>
        !element.executed && vincenty.distance(LatLng(element.lat, element.lon), positioning!.snap!.position) < 20);

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

  /// Play new prediction audio instruction.
  // Currently not used. Will be checked in later optimizations.
  // ignore: unused_element
  void _playNewPredictionStatusInformation() async {
    ride ??= getIt<Ride>();
    if (ftts == null) return;
    // Check if Not supported crossing
    // or we do not have all auxiliary data that the app calculated
    // or prediction quality is not good enough.
    if (ride!.calcCurrentSG == null ||
        ride!.predictionProvider?.recommendation == null ||
        (ride!.predictionProvider?.prediction?.predictionQuality ?? 0) < Ride.qualityThreshold) {
      // No sg countdown information can be added and thus instruction part must not be played.
      return;
    }

    // Check if the prediction is a recommendation for the next traffic light on the route
    // and do not play instruction if this is not the case.
    final thingName = ride!.predictionProvider?.status?.thingName;
    bool isRecommendation = thingName != null ? ride!.calcCurrentSG!.id == thingName : false;
    if (!isRecommendation) return;

    // If the phase change time is null, instruction part must not be played.
    final recommendation = ride!.predictionProvider!.recommendation!;
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
      var distOnRoute = snap.distanceOnRoute;
      var idx = currentRoute!.signalGroups.indexWhere((element) => element.id == ride!.calcCurrentSG!.id);
      var distSgOnRoute = 0.0;
      if (idx != -1) {
        distSgOnRoute = currentRoute!.signalGroupsDistancesOnRoute[idx];
      } else {
        // Do not play instruction if the sg is not on the route.
        return;
      }
      var distanceToSg = distSgOnRoute - distOnRoute;
      if (distanceToSg > 300) {
        // Do not play instruction if the distance to the sg is more than 300m.
        return;
      }

      var nextInstruction = currentRoute!.instructions.firstWhereOrNull((element) => element.executed == false);
      int nextInstructionIdx = currentRoute!.instructions.indexOf(nextInstruction!);
      var lastInstruction = currentRoute!.instructions[nextInstructionIdx - 1];

      if (lastInstruction.signalGroupId != thingName) {
        // Do not play instruction if the sg is not in the last instruction.
        return;
      }

      // Check if the current position is in a radius of 50m of an instruction that contains sg information.
      var nextSgInstruction = currentRoute!.instructions.firstWhereOrNull((element) =>
          (element.instructionType != InstructionType.directionOnly) &&
          vincenty.distance(LatLng(element.lat, element.lon), snap.position) < 50);
      closeToInstruction = nextSgInstruction != null;
    }

    if (!closeToInstruction && (hasPhaseChanged || hasSignificantTimeChange)) {
      var instructionTimeStamp = DateTime.now();

      // Save the current recommendation information for comparison with updates later BEFORE playing the instruction.
      lastRecommendation.clear();
      lastRecommendation = {'phase': currentPhase, 'countdown': countdown, 'timestamp': instructionTimeStamp};

      // Cannot make a recommendation if the next phase is not known.
      if (nextPhase == null) return;

      String sgType = (ride!.calcCurrentSG!.laneType == "Radfahrer") ? "Radampel" : "Ampel";
      InstructionText instructionText =
          InstructionText(text: "Nächste $sgType", type: InstructionTextType.signalGroup, distanceToNextSg: 0);
      final speed = getIt<Positioning>().lastPosition?.speed ?? 0;
      var textToPlay = _generateTextToPlay(instructionText, speed);
      if (textToPlay == null) return;
      await ftts!.speak(textToPlay.text);
      // Calc updatedCountdown since initial creation and time that has passed while speaking
      // (to avoid countdown inaccuracy)
      // Also take into account 1s delay for actually speaking the countdown.
      int updatedCountdown = textToPlay.countdown! -
          (DateTime.now().difference(textToPlay.countdownTimeStamp!).inSeconds) +
          1; // -1s delay and +2s yellow
      await ftts!.speak(updatedCountdown.toString());
    } else {
      // Nevertheless save the current recommendation information for comparison with updates later.
      lastRecommendation.clear();
      lastRecommendation = {'phase': currentPhase, 'countdown': countdown, 'timestamp': DateTime.timestamp()};
    }
  }

  /// Calculates the time to the next phase after the given index.
  int? _calcTimeToNextPhaseAfterIndex(int index) {
    ride ??= getIt<Ride>();
    final recommendation = ride!.predictionProvider!.recommendation!;

    final phases = recommendation.calcPhasesFromNow.sublist(index, recommendation.calcPhasesFromNow.length - 1);
    final nextPhaseColor = phases.first;
    final indexNextPhaseEnd = phases.indexWhere((element) => element != nextPhaseColor);

    return indexNextPhaseEnd;
  }
}
