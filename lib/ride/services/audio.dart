import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/interfaces/prediction.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/models/audio.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/instruction.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/tracking/models/speed_advisory_instruction.dart';
import 'package:priobike/tracking/services/tracking.dart';

/// The class that represents a trigger range for speed advisory instructions.
class _SpeedAdvisoryInstructionTriggerRange {
  /// The minimum distance to the next traffic light when a speed advisory can be triggered.
  int minDistance;

  /// The maximum distance to the next traffic light until a speed advisory can be triggered.
  int maxDistance;

  _SpeedAdvisoryInstructionTriggerRange(this.minDistance, this.maxDistance);
}

/// The distances in front of a traffic light when a speed advisory instruction should be played (triggered).
List<_SpeedAdvisoryInstructionTriggerRange> _speedAdvisoryInstructionTriggerDistances = [
  _SpeedAdvisoryInstructionTriggerRange(300, 200),
  _SpeedAdvisoryInstructionTriggerRange(100, 50)
];

/// The threshold of the prediction quality that needs to be covered when giving speed advisory instructions.
const double predictionQualityThreshold = 0.85;

class Audio {
  /// An instance for text-to-speach.
  FlutterTts? ftts;

  /// The tracking service instance.
  Tracking? tracking;

  /// The ride service instance.
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

  /// The last prediction from the prediction service.
  Prediction? lastPrediction;

  /// Constructor.
  Audio() {
    settings = getIt<Settings>();
    settings!.addListener(_processSettingsUpdates);

    if (settings!.audioSpeedAdvisoryInstructionsEnabled) {
      initialized = true;
      _init();
    }
  }

  /// Initializes the audio service.
  Future<void> _init() async {
    ride ??= getIt<Ride>();
    ride!.addListener(_processRideUpdates);
    positioning ??= getIt<Positioning>();
    positioning!.addListener(_processPositioningUpdates);
    _initializeTTS();
  }

  /// Initializes the text-to-speech instance.
  Future<void> _initializeTTS() async {
    ftts = FlutterTts();

    await _initAudioService();

    if (Platform.isIOS) {
      // Use siri voice if available.
      List<dynamic> voices = await ftts!.getVoices;
      if (voices.any((element) => element["name"] == "Helena" && element["locale"] == "de-DE")) {
        await ftts!.setVoice({
          "name": "Helena",
          "locale": "de-DE",
        });
      }

      await ftts!.setSpeechRate(settings!.speechRate == SpeechRate.fast ? 0.54 : 0.5); //speed of speech
      await ftts!.setVolume(1.0); //volume of speech
      await ftts!.setPitch(1.1); //pitch of sound
      await ftts!.autoStopSharedSession(false);
      await ftts!.awaitSpeakCompletion(true);

      await ftts!.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.allowBluetooth, IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP]);
    } else {
      // Use android voice if available.
      List<dynamic> engines = await ftts!.getEngines;
      if (engines.any((element) => element == "com.google.android.tts")) {
        await ftts!.setEngine("com.google.android.tts");
      }

      List<dynamic> voices = await ftts!.getVoices;

      if (voices.any((element) => element["name"] == "de-DE-language" && element["locale"] == "de-DE")) {
        await ftts!.setVoice({
          "name": "de-DE-language",
          "locale": "de-DE",
        });
      }

      await ftts!.setQueueMode(0);
      await ftts!.awaitSpeakCompletion(true);
      await ftts!.setSpeechRate(settings!.speechRate == SpeechRate.fast ? 0.7 : 0.6); //speed of speech
      await ftts!.setVolume(1.0); //volume of speech
      await ftts!.setPitch(1.1); //pitch of sound
    }

    // Trigger the speak function with an empty text to prevent wait time when the first instruction should be played.
    // In the current implementation of the tts package there is always an error that causes a delay when first using the speak method.
    // The delay at this point doesn't effect the user.
    ftts!.speak(" ");
  }

  /// Initializes the audio service (package).
  Future _initAudioService() async {
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

  /// Resets the text-to-speech instance.
  Future<void> _resetFTTS() async {
    await ftts?.pause();
    await ftts?.stop();
    await ftts?.clearVoice();
    ftts = null;
  }

  /// Cleans up the audio service when deactivated.
  /// Can be called internally when the audio settings changes.
  Future<void> _cleanUp() async {
    ride = null;
    positioning?.removeListener(_processPositioningUpdates);
    positioning = null;
    await _resetFTTS();
    // Deactivate the audio session to allow other audio to play.
    audioSession?.setActive(false);
    audioSession = null;
    lastRecommendation.clear();
    waitForGreenTimer?.cancel();
    waitForGreenTimer = null;
    didStartWaitForGreenInfoTimerForSg = null;
  }

  /// Resets the complete audio service.
  /// Should be called when the audio service instance can be discarded.
  Future<void> reset() async {
    settings?.removeListener(_processSettingsUpdates);
    settings = null;
    await _cleanUp();
  }

  /// Process updates by the ride service to detect rerouting and prediction invalidation.
  Future<void> _processRideUpdates() async {
    if (ride?.navigationIsActive != true) return;
    if (ride?.route == null) return;
    // If the current route is null, we won't see a rerouting but the first route.
    if (currentRoute == null) {
      currentRoute = ride!.route;
      return;
    }
    // Notify user if a rerouting was triggered.
    if (currentRoute != ride!.route && ride?.route != null) {
      currentRoute = ride?.route;
      if (ftts == null) await _initializeTTS();
      ftts?.speak("Neue Route berechnet");
    }

    if (ride!.userSelectedSG != null) return;
    if (ride!.calcCurrentSG == null) return;

    // Check if the prediction is not valid anymore.
    if (lastSignalGroupId == ride!.calcCurrentSGIndex?.toInt()) {
      // Check if the current prediction is still valid.
      // If the prediction quality is not good enough and the last prediction was good enough, inform the user.
      if (lastPrediction?.predictionQuality != null &&
          lastPrediction!.predictionQuality! > predictionQualityThreshold &&
          (ride!.predictionProvider?.prediction?.predictionQuality == null ||
              ride!.predictionProvider!.prediction!.predictionQuality! < predictionQualityThreshold) &&
          currentSpeedAdvisoryInstructionState > 0) {
        // Inform the user that the prediction is not valid any more.
        _playPredictionNotValidAnymore();
      }
    }

    lastPrediction = ride!.predictionProvider?.prediction;
  }

  /// Check if the audio instructions setting has changed.
  Future<void> _processSettingsUpdates() async {
    if (initialized && !settings!.audioSpeedAdvisoryInstructionsEnabled) {
      initialized = false;
      _cleanUp();
    } else if (!initialized && settings!.audioSpeedAdvisoryInstructionsEnabled) {
      initialized = true;
      _init();
    }
  }

  /// Process positioning updates to play audio instructions.
  Future<void> _processPositioningUpdates() async {
    if (settings?.audioSpeedAdvisoryInstructionsEnabled != true) {
      return;
    }

    if (ride?.navigationIsActive != true) {
      return;
    }

    if (ftts == null) {
      await _initializeTTS();
    }

    _addSpeedValueToLastSpeedValues();

    // The next two functions check if an instruction should be triggered.
    await _playSpeedAdvisoryInstruction();

    // Check if sg was passed.
    if (lastSignalGroupId != ride!.calcCurrentSGIndex?.toInt()) {
      // Reset the state if the signal group has changed.
      lastSignalGroupId = ride!.calcCurrentSGIndex?.toInt() ?? -1;
      lastPrediction = null;
      currentSpeedAdvisoryInstructionState = _getNextSpeedAdvisoryInstructionState();
      didStartWaitForGreenInfoTimerForSg = null;
      waitForGreenTimer?.cancel();
      waitForGreenTimer = null;
    }
  }

  /// Returns the next speed advisory instruction state regarding the distance to the sg.
  int _getNextSpeedAdvisoryInstructionState() {
    // If there is no information on the distance, we start with state end.
    if (ride!.calcDistanceToNextSG == null) return 0;

    // If the distance is to close, we skip to the last state.
    if (ride!.calcDistanceToNextSG! <
        _speedAdvisoryInstructionTriggerDistances[_speedAdvisoryInstructionTriggerDistances.length - 1].minDistance) {
      return _speedAdvisoryInstructionTriggerDistances.length;
    }

    // Search for the next state according to the distance.
    for (int i = 0; i < _speedAdvisoryInstructionTriggerDistances.length; i++) {
      if (ride!.calcDistanceToNextSG! > _speedAdvisoryInstructionTriggerDistances[i].maxDistance) {
        return i;
      }
    }

    // Default state.
    return 0;
  }

  /// Add the current speed value to the last speed values list.
  _addSpeedValueToLastSpeedValues() {
    if (positioning!.lastPosition == null) {
      return;
    }
    // Only store values greater the 1.5 m/s since the can be considered start or stop motions.
    if (positioning!.lastPosition!.speed < 1.5) {
      return;
    }

    // Store the last 20 seconds of speed values.
    if (lastSpeedValues.length > 20) {
      lastSpeedValues.removeAt(0);
    }
    lastSpeedValues.add(positioning!.lastPosition?.speed ?? 0);
  }

  /// Returns the median speed of the last speed values.
  double getAverageOfLastSpeedValues() {
    if (lastSpeedValues.isEmpty) {
      // Default is 5m/s (18km/h) since this is considered average driving speed for cyclists.
      return 5;
    }
    return lastSpeedValues.reduce((speedSum, speed) => speedSum + speed) / lastSpeedValues.length;
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

    double lastAverageSpeed = getAverageOfLastSpeedValues();

    // Calculate the arrival time at the sg.
    int arrivalTime = (instructionText.distanceToNextSg / lastAverageSpeed).round();

    int countdownOffset = (DateTime.now().difference(recommendation.timestamp).inMilliseconds / 1000).round();

    // Check if the arrival is at red or to far away.
    if (recommendation.calcPhasesFromNow.length <= arrivalTime ||
        recommendation.calcPhasesFromNow[arrivalTime] == Phase.red) {
      // If the arrival is at red, we use the max of 5m/s and median speed for the arrival time.
      arrivalTime = (instructionText.distanceToNextSg / max(5, lastAverageSpeed)).round();
    }

    // Get the closest change time to the arrival time that is in reach.
    int closestChangeTimeInReach = _getClosestChangeTimeInReach(
        arrivalTime, changeTimes, settings?.speedMode ?? SpeedMode.max30kmh, instructionText.distanceToNextSg);

    // Check if closest change time switches to red or green.
    if (recommendation.calcPhasesFromNow[closestChangeTimeInReach] == Phase.red) {
      // If the closest change time switches to red, add countdown to red.
      // Subtract 2 for starting at second 0 and 1 for the second before change.
      int countdown = closestChangeTimeInReach - countdownOffset - 2;
      instructionText.addCountdown(countdown);
      instructionText.text = "${instructionText.text} rot in";
      return instructionText;
    } else if (recommendation.calcPhasesFromNow[closestChangeTimeInReach] == Phase.green) {
      // If the closest change time switches to green, add countdown to green.
      // Subtract 2 for starting at second 0 and 1 for the second before change.
      int countdown = closestChangeTimeInReach - countdownOffset - 2;
      instructionText.addCountdown(countdown);
      instructionText.text = "${instructionText.text} grün in";
      return instructionText;
    }

    // No recommendation can be made.
    return null;
  }

  /// Checks if the user is at slow speed or standing still close to a traffic light and plays a countdown for the next traffic light when waiting for green.
  void _checkPlayCountdownWhenWaitingForGreen() {
    ride ??= getIt<Ride>();
    positioning ??= getIt<Positioning>();

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
      if (ftts == null) return;
      if (audioSession == null) return;

      await audioSession!.setActive(true);
      await Future.delayed(const Duration(milliseconds: 500));

      await ftts!.speak("Grün in");
      await ftts!.speak("5");

      // Add some buffer because the end of speak can not be detected.
      await Future.delayed(const Duration(milliseconds: 500));

      // Needs to be checked because function is async.
      if (audioSession == null) return;
      // Deactivate the audio session to allow other audio to play.
      await audioSession!.setActive(false);

      didStartWaitForGreenInfoTimerForSg = null;
      timer.cancel();
      waitForGreenTimer = null;

      // Add the speed advisory instruction to the current track.
      if (tracking != null && positioning?.snap != null) {
        tracking!.addSpeedAdvisoryInstruction(
          SpeedAdvisoryInstruction(
              text: "Grün in",
              countdown: 5,
              lat: positioning!.snap!.position.latitude,
              lon: positioning!.snap!.position.longitude),
        );
      }
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

  /// Play speed advisory instruction only.
  Future<void> _playSpeedAdvisoryInstruction() async {
    ride ??= getIt<Ride>();
    tracking ??= getIt<Tracking>();
    positioning ??= getIt<Positioning>();
    if (positioning!.snap == null || ride!.route == null) return;

    if (ftts == null) return;

    _checkPlayCountdownWhenWaitingForGreen();

    // If the state is higher than the length of the speed advisory distances, do not play any more instructions.
    if (currentSpeedAdvisoryInstructionState > _speedAdvisoryInstructionTriggerDistances.length - 1) {
      return;
    }

    if (!_canCreateInstructionForRecommendation()) return;

    // Check if the activation distance of the current state is reached.
    if (ride?.calcDistanceToNextSG == null ||
        ride!.calcDistanceToNextSG! >=
            _speedAdvisoryInstructionTriggerDistances[currentSpeedAdvisoryInstructionState].minDistance) {
      return;
    }

    // Create the audio advisory instruction.
    String sgType = (ride!.calcCurrentSG!.laneType == "Radfahrer") ? "Radampel" : "Ampel";
    int roundedDistance = (ride!.calcDistanceToNextSG! / 25).ceil() * 25;
    InstructionText instructionText = InstructionText(
      text: "In $roundedDistance meter $sgType",
      type: InstructionTextType.signalGroup,
      distanceToNextSg: ride!.calcDistanceToNextSG!,
    );

    var textToPlay = generateTextToPlay(instructionText);

    if (textToPlay == null) return;

    currentSpeedAdvisoryInstructionState++;

    // Activate the audio session to duck others in case of music or other audio playing.
    // Needs to be checked because function is async.
    if (audioSession == null) return;
    await audioSession!.setActive(true);
    await Future.delayed(const Duration(milliseconds: 500));

    // Needs to be checked because function is async.
    if (ftts == null) return;
    await ftts!.speak(textToPlay.text);

    // Calc updatedCountdown since initial creation and time that has passed while speaking
    // (to avoid countdown inaccuracy)
    int updatedCountdown = textToPlay.countdown! -
        ((DateTime.now().difference(textToPlay.countdownTimeStamp).inMilliseconds) / 1000).round();

    // Needs to be checked because function is async.
    if (ftts == null) return;

    // Add the speed advisory instruction to the current track.
    if (tracking != null) {
      tracking!.addSpeedAdvisoryInstruction(
        SpeedAdvisoryInstruction(
            text: instructionText.text,
            countdown: updatedCountdown,
            lat: positioning!.snap!.position.latitude,
            lon: positioning!.snap!.position.longitude),
      );
    }

    await ftts!.speak(updatedCountdown.toString());

    // Add some buffer because the end of speak can not be detected.
    await Future.delayed(const Duration(milliseconds: 500));

    // Needs to be checked because function is async.
    if (audioSession == null) return;
    // Deactivate the audio session to allow other audio to play.
    await audioSession!.setActive(false);
  }

  Future<void> _playPredictionNotValidAnymore() async {
    if (ftts == null) return;
    if (audioSession == null) return;

    audioSession!.setActive(true);
    await Future.delayed(const Duration(milliseconds: 500));
    ftts!.speak("Achtung, aktuelle Prognose nicht mehr gültig");

    if (positioning?.snap != null) {
      tracking!.addSpeedAdvisoryInstruction(
        SpeedAdvisoryInstruction(
            text: "Achtung, aktuelle Prognose nicht mehr gültig",
            countdown: 0,
            lat: positioning!.snap!.position.latitude,
            lon: positioning!.snap!.position.longitude),
      );
    }

    await audioSession!.setActive(false);
  }
}
