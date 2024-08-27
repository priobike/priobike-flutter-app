import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:collection/collection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/instruction.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/services/settings.dart';

const String redInText = "rot in";
const String greenInText = "grün in";

/// The distances before the crossings when a speed advisory instruction should be played.
const List<int> speedAdvisoryDistances = [300, 100];

/// The distances until an instruction is played even if the distance is smaller than the speedAdvisoryDistances.
const List<int> speedAdvisoryMinDistances = [200, 50];

/// The minimal distance before the crossing when a speed advisory instruction should be played. (Except wait for green)
const int speedAdvisoryMinDistance = 50;

const double predictionQualityThreshold = 0.85;

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
  String? didStartWaitForGreenInfoTimerForSg;

  /// The wait for green timer that is used to time the wait for green instruction.
  Timer? waitForGreenTimer;

  /// The current state of the speed advisory instruction.
  int currentSpeedAdvisoryInstructionState = 0;

  /// The last signal group id.
  int lastSignalGroupId = -1;

  /// The last 11 values of the user speed.
  List<double> lastSpeedValues = [];

  /// An instance of the audio session.
  AudioSession? audioSession;

  /// Constructor.
  Audio() {
    settings = getIt<Settings>();
    settings!.addListener(_processSettingsUpdates);

    if (settings!.audioSpeedAdvisoryInstructionsEnabled) {
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
    audioSession = null;
    lastRecommendation.clear();
  }

  /// Reset the complete audio service.
  Future<void> reset() async {
    settings?.removeListener(_processSettingsUpdates);
    settings = null;
    waitForGreenTimer?.cancel();
    waitForGreenTimer = null;
    didStartWaitForGreenInfoTimerForSg = null;
    await cleanUp();
  }

  /// Returns the next speed advisory instruction state.
  int _getNextSpeedAdvisoryInstructionState() {
    // If there is no information on the distance, we start with state 0.
    if (ride!.calcDistanceToNextSG == null) return 0;

    // If the distance is to close, we skip to the last state.
    if (ride!.calcDistanceToNextSG! < speedAdvisoryMinDistance) {
      return speedAdvisoryDistances.length;
    }

    // Search for the next state according to the distance.
    for (int i = 0; i < speedAdvisoryDistances.length; i++) {
      if (ride!.calcDistanceToNextSG! > speedAdvisoryMinDistances[i]) {
        return i;
      }
    }

    // Default state.
    return speedAdvisoryDistances.length;
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

    if (lastSignalGroupId != ride!.calcCurrentSGIndex?.toInt()) {
      lastSignalGroupId = ride!.calcCurrentSGIndex?.toInt() ?? -1;
      currentSpeedAdvisoryInstructionState = _getNextSpeedAdvisoryInstructionState();
      didStartWaitForGreenInfoTimerForSg = null;
      waitForGreenTimer?.cancel();
      waitForGreenTimer = null;
    }

    // check phase change things TODO.
  }

  /// Check if the audio instructions setting has changed.
  Future<void> _processSettingsUpdates() async {
    if (initialized && !settings!.audioSpeedAdvisoryInstructionsEnabled) {
      initialized = false;
      cleanUp();
    } else if (!initialized && settings!.audioSpeedAdvisoryInstructionsEnabled) {
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
    if (settings?.audioSpeedAdvisoryInstructionsEnabled != true && settings?.audioRoutingInstructionsEnabled != true) {
      return;
    }

    if (ride?.navigationIsActive != true) {
      return;
    }

    if (ftts == null) {
      await _initializeTTS();
    }

    _addSpeedValueToLastSpeedValues();

    if (settings?.audioRoutingInstructionsEnabled == true) {
      // Create navigation and speed advisory instructions.
      await _playAudioRoutingInstruction();
    } else if (settings?.audioSpeedAdvisoryInstructionsEnabled == true) {
      // Create only speed advisory instructions.
      await _playSpeedAdvisoryInstruction();
    }

    _checkPlayCountdownWhenWaitingForGreen();
  }

  /// Add the current speed value to the last speed values list.
  _addSpeedValueToLastSpeedValues() {
    if (positioning!.lastPosition == null) {
      return;
    }
    if (positioning!.lastPosition!.speed < 5) {
      return;
    }

    if (lastSpeedValues.length >= 11) {
      lastSpeedValues.removeAt(0);
    }
    lastSpeedValues.add(positioning!.lastPosition?.speed ?? 0);
  }

  double _getMedianSpeedOfLastSpeedValues() {
    if (lastSpeedValues.isEmpty) {
      return 0;
    }
    lastSpeedValues.sort();
    if (lastSpeedValues.length % 2 == 0) {
      return (lastSpeedValues[lastSpeedValues.length ~/ 2 - 1] + lastSpeedValues[lastSpeedValues.length ~/ 2]) / 2;
    } else {
      return lastSpeedValues[lastSpeedValues.length ~/ 2];
    }
  }

  /// Returns a list with the change times of the recommendation.
  List<int> _calculateChangesTimesOfRecommendation(Recommendation recommendation) {
    List<int> changeTimes = [];
    Phase lastPhase = recommendation.calcCurrentSignalPhase;
    for (int i = 0; i < recommendation.calcPhasesFromNow.length; i++) {
      // Only consider red and green.
      if (!(recommendation.calcPhasesFromNow[i] == Phase.red || recommendation.calcPhasesFromNow[i] == Phase.green)) {
        continue;
      }

      if (recommendation.calcPhasesFromNow[i] != lastPhase) {
        changeTimes.add(i);
        lastPhase = recommendation.calcPhasesFromNow[i];
      }
    }
    return changeTimes;
  }

  /// Returns the closest change time in reach.
  int _getClosestChangeTimeInReach(
      int arrivalTime, List<int> changeTimes, SpeedMode speedMode, double distanceToNextSg) {
    double maxSpeed = (speedMode.maxSpeed - 3) / 3.6; // Convert to m/s.

    return changeTimes
        .reduce((a, b) => (a - arrivalTime).abs() < (b - arrivalTime).abs() && distanceToNextSg / a < maxSpeed ? a : b);
  }

  /// Check if instruction contains sg information and if so add countdown.
  /// Speed in m/s.
  InstructionText? generateTextToPlay(InstructionText instructionText) {
    ride ??= getIt<Ride>();

    // Check if prediction quality is not good enough.
    if (ride!.calcCurrentSG == null ||
        ride!.predictionProvider?.recommendation == null ||
        (ride!.predictionProvider?.prediction?.predictionQuality ?? 0) < predictionQualityThreshold) {
      // No sg countdown information can be added and thus instruction part must not be played.
      return null;
    }

    final recommendation = ride!.predictionProvider!.recommendation!;

    List<int> changeTimes = _calculateChangesTimesOfRecommendation(recommendation);

    if (changeTimes.isEmpty) return null;

    double lastMedianSpeed = _getMedianSpeedOfLastSpeedValues();

    // Calculate the arrival time at the sg.
    int arrivalTime = (instructionText.distanceToNextSg / lastMedianSpeed).round();

    int countdownOffset = DateTime.now().difference(recommendation.timestamp).inSeconds;

    // Check if the arrival is at red or to far away.
    if (recommendation.calcPhasesFromNow.length <= arrivalTime ||
        recommendation.calcPhasesFromNow[arrivalTime] == Phase.red) {
      // If the arrival is at red, we use the max of 5m/s and median speed for the arrival time.
      arrivalTime = (instructionText.distanceToNextSg / max(5, lastMedianSpeed)).round();
    }

    // Get the closest change time to the arrival time that is in reach.
    int closestChangeTimeInReach = _getClosestChangeTimeInReach(
        arrivalTime, changeTimes, settings?.speedMode ?? SpeedMode.max30kmh, instructionText.distanceToNextSg);

    // Check if closest change time switches to red or green.
    if (recommendation.calcPhasesFromNow[closestChangeTimeInReach] == Phase.red) {
      // If the closest change time switches to red, add countdown to red.
      int countdown = closestChangeTimeInReach - countdownOffset;
      instructionText.addCountdown(countdown);
      instructionText.text = "${instructionText.text} $redInText";
      return instructionText;
    } else if (recommendation.calcPhasesFromNow[closestChangeTimeInReach] == Phase.green) {
      // If the closest change time switches to green, add countdown to green.
      int countdown = closestChangeTimeInReach - countdownOffset;
      instructionText.addCountdown(countdown);
      instructionText.text = "${instructionText.text} $greenInText";
      return instructionText;
    }

    // No recommendation can be made.
    return null;
  }

  /// Checks if the user is at slow speed or standing still close to a traffic light and plays a countdown for the next traffic light when waiting for green.
  void _checkPlayCountdownWhenWaitingForGreen() async {
    ride ??= getIt<Ride>();

    if (didStartWaitForGreenInfoTimerForSg != null && didStartWaitForGreenInfoTimerForSg != ride!.calcCurrentSG?.id) {
      // Do not play instruction if the sg is the same as the last played sg.
      waitForGreenTimer?.cancel();
      waitForGreenTimer = null;
      didStartWaitForGreenInfoTimerForSg = null;
      return;
    }

    final speed = getIt<Positioning>().lastPosition?.speed ?? 0;
    if (speed * 3.6 > 7) {
      // All speed over 7 km/h is considered normal driving.
      waitForGreenTimer?.cancel();
      waitForGreenTimer = null;
      didStartWaitForGreenInfoTimerForSg = null;
      return;
    }

    // If the timer is already running, do not start a new one.
    if (waitForGreenTimer != null) {
      return;
    }

    if (ftts == null) return;

    if (!_canCreateInstructionForRecommendation()) return;

    final recommendation = ride!.predictionProvider!.recommendation!;

    // If the current phase is green, we do not start a timer.
    if (recommendation.calcPhasesFromNow[0] == Phase.green) return;

    // Get the countdown.
    int countdown = recommendation.calcCurrentPhaseChangeTime!.difference(DateTime.now()).inSeconds;

    // Do not play instruction if countdown < 6.
    if (countdown < 6) return;

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

    didStartWaitForGreenInfoTimerForSg = ride!.calcCurrentSG!.id;

    // Start a timer that executes the audio instruction 5 seconds before the traffic light turns green.
    // Subtracting 5 seconds for the countdown and 1 second for the speaking delay.
    waitForGreenTimer = Timer.periodic(Duration(seconds: countdown - 6), (timer) async {
      await ftts!.speak("Grün in");
      await ftts!.speak("5");
      didStartWaitForGreenInfoTimerForSg = null;
      timer.cancel();
      waitForGreenTimer = null;
    });
  }

  bool _canCreateInstructionForRecommendation() {
    ride ??= getIt<Ride>();

    // Check if Not supported crossing
    // or we do not have all auxiliary data that the app calculated
    // or prediction quality is not good enough.
    if (ride!.calcCurrentSG == null ||
        ride!.predictionProvider?.recommendation == null ||
        (ride!.predictionProvider?.prediction?.predictionQuality ?? 0) < predictionQualityThreshold) {
      // No sg countdown information can be added and thus instruction part must not be played.
      return false;
    }

    // Check if the prediction is a recommendation for the next traffic light on the route
    // and do not play instruction if this is not the case.
    final thingName = ride!.predictionProvider?.status?.thingName;
    bool isRecommendation = thingName != null ? ride!.calcCurrentSG!.id == thingName : false;
    if (!isRecommendation) return false;

    // If the phase change time is null, instruction part must not be played.
    final recommendation = ride!.predictionProvider!.recommendation!;
    if (recommendation.calcCurrentPhaseChangeTime == null) return false;

    // If there is only one color, instruction part must not be played.
    final uniqueColors = recommendation.calcPhasesFromNow.map((e) => e.color).toSet();
    if (uniqueColors.length == 1) return false;

    return true;
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

    await initAudioService();

    if (Platform.isIOS) {
      // Use siri voice if available.
      List<dynamic> voices = await ftts!.getVoices;
      if (voices.any((element) => element["name"] == "Helena" && element["locale"] == "de-DE")) {
        await ftts!.setVoice({
          "name": "Helena",
          "locale": "de-DE",
        });
      }

      await ftts!.setSpeechRate(settings!.speechRateFast ? 0.4 : 0.55); //speed of speech
      await ftts!.setVolume(1.0); //volume of speech
      await ftts!.setPitch(1.0); //pitch of sound
      await ftts!.autoStopSharedSession(false);
      await ftts!.awaitSpeakCompletion(true);

      await ftts!.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.allowBluetooth, IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP]);
    } else {
      // Use android voice if available.
      List<dynamic> voices = await ftts!.getVoices;

      if (voices.any((element) => element["name"] == "de-DE-language" && element["locale"] == "de-DE")) {
        await ftts!.setVoice({
          "name": "de-DE-language",
          "locale": "de-DE",
        });
      }

      List<dynamic> engines = await ftts!.getEngines;
      if (engines.any((element) => element == "com.google.android.tts")) {
        await ftts!.setEngine("com.google.android.tts");
      }

      await ftts!.awaitSpeakCompletion(true);
      await ftts!.setQueueMode(0);

      await ftts!.setSpeechRate(settings!.speechRateFast ? 0.6 : 0.5); //speed of speech
      await ftts!.setVolume(1.0); //volume of speech
      await ftts!.setPitch(1.0); //pitch of sound
    }
  }

  Future initAudioService() async {
    audioSession = await AudioSession.instance;
    await audioSession!.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: true,
    ));
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
          // Check for countdown information.
          var instructionTextToPlay = generateTextToPlay(it.current);
          if (instructionTextToPlay == null) {
            continue;
          }
          await ftts!.speak(instructionTextToPlay.text);
          // Calc updatedCountdown since initial creation and time that has passed while speaking
          // (to avoid countdown inaccuracy)
          // Also take into account 1s delay for actually speaking the countdown.
          int updatedCountdown = instructionTextToPlay.countdown! -
              (DateTime.now().difference(instructionTextToPlay.countdownTimeStamp).inSeconds) -
              1;
          await ftts!.speak(updatedCountdown.toString());
        }
      }
    }
  }

  /// Play speed advisory instruction only.
  Future<void> _playSpeedAdvisoryInstruction() async {
    ride ??= getIt<Ride>();
    positioning ??= getIt<Positioning>();
    if (positioning!.snap == null || ride!.route == null) return;

    if (ftts == null) return;

    // If the state is higher than the length of the speed advisory distances, do not play any more instructions.
    if (currentSpeedAdvisoryInstructionState > speedAdvisoryDistances.length - 1) {
      return;
    }

    if (!_canCreateInstructionForRecommendation()) return;

    // Check if the distance of the current state is reached.
    if (ride?.calcDistanceToNextSG != null &&
        ride!.calcDistanceToNextSG! < speedAdvisoryDistances[currentSpeedAdvisoryInstructionState]) {
      // Create the audio advisory instruction.
      String sgType = (ride!.calcCurrentSG!.laneType == "Radfahrer") ? "Radampel" : "Ampel";
      int roundedDistance = (ride!.calcDistanceToNextSG! / 25).ceil() * 25;
      InstructionText instructionText = InstructionText(
        text: "In $roundedDistance meter $sgType",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: ride!.calcDistanceToNextSG!,
      );

      var textToPlay = generateTextToPlay(instructionText);

      if (textToPlay == null) {
        return;
      }

      currentSpeedAdvisoryInstructionState++;
      await audioSession!.setActive(true);
      await Future.delayed(const Duration(milliseconds: 500));

      await ftts!.speak(textToPlay.text);

      // Calc updatedCountdown since initial creation and time that has passed while speaking
      // (to avoid countdown inaccuracy)
      int updatedCountdown =
          textToPlay.countdown! - (DateTime.now().difference(textToPlay.countdownTimeStamp).inSeconds) - 1;
      if (Platform.isIOS) updatedCountdown -= 2;

      await ftts!.speak(updatedCountdown.toString());

      await audioSession!.setActive(false);
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

      var textToPlay = generateTextToPlay(instructionText);
      if (textToPlay == null) return;
      await ftts!.speak(textToPlay.text);
      // Calc updatedCountdown since initial creation and time that has passed while speaking
      // (to avoid countdown inaccuracy)
      // Also take into account 1s delay for actually speaking the countdown.
      int updatedCountdown = textToPlay.countdown! -
          (DateTime.now().difference(textToPlay.countdownTimeStamp).inSeconds) +
          1; // -1s delay and +2s yellow
      await ftts!.speak(updatedCountdown.toString());
    } else {
      // Nevertheless save the current recommendation information for comparison with updates later.
      lastRecommendation.clear();
      lastRecommendation = {'phase': currentPhase, 'countdown': countdown, 'timestamp': DateTime.timestamp()};
    }
  }
}
