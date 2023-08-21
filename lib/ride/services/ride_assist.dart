import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:permission_handler/permission_handler.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/ride_assist.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/models/test.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:wearable_communicator/wearable_communicator.dart';

// Audios.
const audioIntervalFaster = "sounds/interval_faster.mp3";
const audioIntervalSlower = "sounds/interval_slower.mp3";
const audioInfo = "sounds/info.mp3";
const audioSuccess = "sounds/success.mp3";

/// The threshold for a new phase.
const int newPhaseThreshold = 1;

/// The Points where a message should be played if not in window.
const List<int> messagePoints = [1000, 500, 200, 100, 50];

/// The Margins for the message points.
const List<int> messagePointMargins = [600, 275, 150, 60];

/// The buffer where messages should not be played before and in turns.
const int bufferDistTurn = 35;

class RideAssist with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("RideAssist");

  final positioning = getIt<Positioning>();
  final ride = getIt<Ride>();
  final routing = getIt<Routing>();
  final settings = getIt<Settings>();

  final AudioPlayer audioPlayer1 = AudioPlayer();
  final AudioPlayer audioPlayer2 = AudioPlayer();

  /// Bool that holds the state if the wear device is active.
  bool wearDeviceReady = false;

  /// Bool that holds the state if the user is in a green phase
  bool? inGreenPhase;

  /// Counter that holds the number of seconds in another phase.
  int newPhaseCounter = 0;

  /// Bool that holds the state if the fast loop has to be played.
  bool fastLoopRunning = false;

  /// Bool that holds the state if the slow loop has to be played.
  bool slowLoopRunning = false;

  /// Int that counts how many messages got played by interval method.
  int messagesPlayedCounter = -1;

  /// SG that is currently selected.
  Sg? currentSG;

  /// The timer used for the signal loops.
  Timer? timer;

  List<TestData> testData = [];

  /// Start communication to wear device.
  Future<void> startListening() async {
    WearableListener.listenForMessage((msg) {
      Map<String, dynamic> data = jsonDecode(msg);

      // Status message received.
      if (data["status"] != null && data["status"] == "ready") {
        wearDeviceReady = true;
        notifyListeners();
      }
    });
  }

  /// Send start signal to device.
  void sendStart() {
    WearableCommunicator.sendMessage({
      "startNavigation": true,
    });
    testData = [];
  }

  /// Send start signal to device in standalone mode.
  void sendStartStandalone() {
    if (routing.selectedRoute != null) {
      WearableCommunicator.sendMessage({
        "startNavigationStandalone": routing.selectedRoute!.route.map((e) => [e.lon, e.lat]).toList(),
      });
      testData = [];
    }
  }

  /// Send play output message to device.
  void sendOutput(String type) {
    String outputSignal = "${settings.modalityMode.name}-${settings.rideAssistMode.name}-$type";
    WearableCommunicator.sendMessage({
      "play": outputSignal,
    });
  }

  /// Send play output message to device.
  void sendPosition(double lat, double lon, double bearing, double zoom, double kmh) {
    WearableCommunicator.sendMessage({
      "updatePosition": {
        "lat": lat,
        "lon": lon,
        "bearing": bearing,
        "zoom": zoom > 2 ? zoom - 2 : zoom,
        "kmh": kmh,
      },
    });
  }

  /// Send stop message to device.
  void sendStop() {
    WearableCommunicator.sendMessage({
      "stopNavigation": true,
    });
    // Save testData.
    saveTestData();
  }

  Future<void> saveTestData() async {
    // Save data in File on phone.
    final date = DateTime.now().toIso8601String();
    final test = {
      "date": date,
      "data": testData,
    };

    await writeJson(json.encode(test), date);
  }

  Future<File> writeJson(String json, String date) async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      await Permission.storage.request();
    }

    Directory directory = Directory("/storage/emulated/0/Download/results");

    final exPath = directory.path;
    await Directory(exPath).create(recursive: true);
    var dateSplit = date.split("T");
    var time = dateSplit[1].split(".")[0].replaceAll(":", "_");

    File file = File('$exPath/result_${dateSplit[0]}$time.txt');

    // Write the data in the file.
    return await file.writeAsString(json);
  }

  /// Send Gauge data to watch.
  void sendGaugeData(List<Color> gaugeColors, List<double> gaugeStops) {
    List<double> gaugeStopsCopy = [...gaugeStops];
    if (gaugeStopsCopy.contains(double.infinity)) {
      gaugeStopsCopy.remove(double.infinity);
    }

    // Size to 0 - 0.5 range.
    for (int i = 0; i < gaugeStopsCopy.length; i++) {
      gaugeStopsCopy[i] = gaugeStopsCopy[i] * 0.5;
    }

    WearableCommunicator.sendMessage({
      "gaugeData": {
        "gaugeColors": gaugeColors.map((e) => [e.red, e.green, e.blue]).toList(),
        "gaugeStops": gaugeStopsCopy
      }
    });
  }

  /// Update the position.
  Future<void> updatePosition() async {
    // Check ride active.
    if (settings.rideAssistMode == RideAssistMode.none) return;
    if (!ride.navigationIsActive) return;
    if (ride.predictionComponent?.prediction?.predictionQuality == null) {
      // Set to null if there is no prediction (ride assist easy).
      inGreenPhase = null;
      newPhaseCounter = 0;

      // Check if loops running and stop if so (ride assist continuous).
      if (slowLoopRunning || fastLoopRunning) {
        stopSignalLoop();
        slowLoopRunning = false;
        fastLoopRunning = false;
      }
      return;
    }

    // Check prediction quality. This is maybe not good.
    // if (ride.predictionComponent!.prediction!.predictionQuality! <= 0.0) return;

    final double kmh = (positioning.lastPosition?.speed ?? 0.0) * 3.6;

    // Too less speed.
    if (kmh < 7) {
      reset();
      return;
    }

    final phases = ride.predictionComponent!.recommendation?.calcPhasesFromNow ?? [];
    final qualities = ride.predictionComponent!.recommendation?.calcQualitiesFromNow ?? [];

    // Switch between modes.
    switch (settings.rideAssistMode) {
      case RideAssistMode.easy:
        rideAssistEasy(phases, qualities, kmh);
        break;
      case RideAssistMode.continuous:
        rideAssistContinuous(phases, qualities, kmh);
        break;
      case RideAssistMode.interval:
        rideAssistInterval(phases, qualities, kmh);
        break;
      case RideAssistMode.none:
        return;
    }

    notifyListeners();
  }

  /// Ride assist easy algorithm.
  rideAssistEasy(List<Phase> phases, List<double> qualities, double kmh) {
    // Calculate current Phase.
    final int second = ((ride.calcDistanceToNextSG! * 3.6) / kmh).round();

    // Second in array length.
    Phase phase = Phase.dark;

    // Replace phase if possible.
    if (second < phases.length && second >= 0) {
      phase = phases[second];
    }

    // Check if there is a previous value of inGreenPhase.
    if (ride.calcDistanceToNextTurn! > bufferDistTurn) {
      if (inGreenPhase != null) {
        // Either in green phase or not.
        // Check if there is still a green phase available.
        if (greenPhaseAvailable(phases)) {
          // If the phase is green.
          if (phase == Phase.green) {
            // If the previous phase was not green.
            if (!inGreenPhase!) {
              // Check if the phase is left long enough.
              if (newPhaseCounter >= newPhaseThreshold) {
                // Old recommendation and entering green phase window.
                playSuccess();
                inGreenPhase = true;
                newPhaseCounter = 0;
              } else {
                // Increment counter.
                newPhaseCounter += 1;
              }
            } else {
              // Hit the old phase again and therefore reset the counter.
              newPhaseCounter = 0;
            }
          } else {
            // If the previous phase was green.
            if (inGreenPhase!) {
              // Check if the phase is left long enough.
              if (newPhaseCounter >= newPhaseThreshold) {
                // Old recommendation and entering green phase window.
                playInfo();
                inGreenPhase = false;
                newPhaseCounter = 0;
              } else {
                // Increment counter.
                newPhaseCounter += 1;
              }
            } else {
              // Hit the old phase again and therefore reset the counter.
              newPhaseCounter = 0;
            }
          }
        } else {
          inGreenPhase = null;
          newPhaseCounter = 0;
        }
      } else {
        // Only play signal after turns.
        // Not in any phase yet. Therefore play signal.
        if (phase == Phase.green) {
          // New recommendation and in green window phase.
          playSuccess();
          inGreenPhase = true;
          newPhaseCounter = 0;
        } else {
          // New recommendation and not in green window phase.
          if (greenPhaseAvailable(phases)) {
            playInfo();
            inGreenPhase = false;
            newPhaseCounter = 0;
          }
          // Message that there is a green phase available.
        }
      }
    }
  }

  /// Ride assist continuous algorithm.
  rideAssistContinuous(List<Phase> phases, List<double> qualities, double kmh) {
    // Calculate current Phase.
    final int second = ((ride.calcDistanceToNextSG! * 3.6) / kmh).round();

    // Second in array length.
    Phase phase = Phase.dark;

    // Replace phase if possible.
    if (second < phases.length && second >= 0) {
      phase = phases[second];
    }

    // If there is no green phase, there is nothing to adjust to.
    if (greenPhaseAvailable(phases)) {
      // Check if in green phase reached => do nothing.
      if (phase == Phase.green) {
        if (slowLoopRunning || fastLoopRunning) {
          stopSignalLoop();
          slowLoopRunning = false;
          fastLoopRunning = false;
        }
        return;
      } else {
        // Decide which phase is closer.
        int closestPhase = getClosestPhase(phases, second);
        if (second - closestPhase >= 0) {
          // Less time needed => drive faster.
          // Check if slowLoopRunning.
          if (slowLoopRunning) {
            stopSignalLoop();
            slowLoopRunning = false;
          }
          // Start fast loop if not running.
          if (!fastLoopRunning) {
            startFasterLoop();
            fastLoopRunning = true;
          }
        } else {
          // More time needed => drive slower.
          // Check if fastLoopRunning.
          if (fastLoopRunning) {
            stopSignalLoop();
            fastLoopRunning = false;
          }
          // Start slow loop if not running.
          if (!slowLoopRunning) {
            startSlowerLoop();
            slowLoopRunning = true;
          }
        }
      }
    }
  }

  /// Ride assist continuous algorithm.
  rideAssistInterval(List<Phase> phases, List<double> qualities, double kmh) {
    // Calculate current Phase.
    // Too less speed.
    if (!greenPhaseAvailableInGoodRange(phases) ||
        ride.calcDistanceToNextSG == null ||
        ride.calcDistanceToNextTurn == null ||
        ride.calcCurrentSG == null) {
      reset();
      return;
    }

    if (currentSG == null || currentSG != ride.calcCurrentSG) {
      currentSG = ride.calcCurrentSG;
      messagesPlayedCounter = 0;
    }

    final int second = ((ride.calcDistanceToNextSG! * 3.6) / kmh).round();

    // Second in array length.
    Phase phase = Phase.dark;

    // Replace phase if possible.
    if (second < phases.length && second >= 0) {
      phase = phases[second];
    }

    void playControlSequence() {
      if (phase == Phase.green) {
        playSuccess();
        inGreenPhase = true;
        return;
      }
      int closestPhase = getClosestPhaseToIdeal(phases);
      if (second - closestPhase >= 0) {
        // Less time needed => drive faster.
        playFaster();
        inGreenPhase = false;
        return;
      } else {
        // More time needed => drive slower.
        playSlower();
        inGreenPhase = false;
        return;
      }
    }

    // Initial phase. Play message once.
    if (messagesPlayedCounter == -1 &&
        ride.calcDistanceToNextTurn! >= bufferDistTurn &&
        ride.calcDistanceToNextSG! >= messagePoints[0]) {
      messagesPlayedCounter = 0;
      playControlSequence();
      return;
    }

    // Second phase less then 50m. Play control sequence.
    if (messagesPlayedCounter <= 4 &&
        ride.calcDistanceToNextSG! <= messagePoints[4] &&
        ride.calcDistanceToNextTurn! >= bufferDistTurn) {
      messagesPlayedCounter = 5;
      playControlSequence();
      return;
    }

    // Second phase less then 100m. Play control sequence.
    if (messagesPlayedCounter <= 3 &&
        ride.calcDistanceToNextSG! <= messagePoints[3] &&
        ride.calcDistanceToNextSG! >= messagePointMargins[3] &&
        ride.calcDistanceToNextTurn! >= bufferDistTurn) {
      messagesPlayedCounter = 4;
      playControlSequence();
      return;
    }

    // Second phase less then 500m. Play control sequence.
    if (messagesPlayedCounter <= 2 &&
        ride.calcDistanceToNextSG! <= messagePoints[2] &&
        ride.calcDistanceToNextSG! >= messagePointMargins[2] &&
        ride.calcDistanceToNextTurn! >= bufferDistTurn) {
      messagesPlayedCounter = 3;
      playControlSequence();
      return;
    }

    // Second phase less then 200m. Play control sequence.
    if (messagesPlayedCounter <= 1 &&
        ride.calcDistanceToNextSG! <= messagePoints[1] &&
        ride.calcDistanceToNextSG! >= messagePointMargins[1] &&
        ride.calcDistanceToNextTurn! >= bufferDistTurn) {
      messagesPlayedCounter = 2;
      playControlSequence();
      return;
    }

    // Second phase less then 1000m. Play control sequence.
    if (messagesPlayedCounter == 0 &&
        ride.calcDistanceToNextSG! <= messagePoints[0] &&
        ride.calcDistanceToNextSG! >= messagePointMargins[0] &&
        ride.calcDistanceToNextTurn! >= bufferDistTurn) {
      messagesPlayedCounter = 1;
      playControlSequence();
      return;
    }
  }

  /// Returns the int of the closest green phase (on same distance faster is returned).
  /// TODO find a more suitable solution. Maybe start from 15kmh.
  int getClosestPhase(List<Phase> phases, int second) {
    // Second (speed) minus i must be above this value to be visible. Else its too fast.
    final int maxSecond = ((ride.calcDistanceToNextSG!) / (settings.speedMode.maxSpeed / 3.6)).round();
    for (int i = 0; i < phases.length; i++) {
      // Check in direction second - i.
      if (second - i >= 0 && second - i < phases.length && (second - i) > maxSecond) {
        if (phases[second - i] == Phase.green) {
          // Return phase faster.
          return second - i;
        }
      }
      // Check in direction second + i. To prevent going for phases outside the maxSpeed.
      if (second + i < phases.length) {
        if (phases[second + i] == Phase.green) {
          // Return phase slower.
          return second + i;
        }
      }
    }
    // No phase found.
    return -1;
  }

  /// Returns the int of the closest green phase (on same distance faster is returned).
  int getClosestPhaseToIdeal(List<Phase> phases) {
    // Second (speed) minus i must be above this value to be visible. Else its too fast.
    final int maxSecond = ((ride.calcDistanceToNextSG!) / (settings.speedMode.maxSpeed / 3.6)).round();
    final int idealSecond = ((ride.calcDistanceToNextSG!) / (18 / 3.6)).round();
    for (int i = 0; i < phases.length; i++) {
      // Check in direction second - i.
      if (idealSecond - i >= 0 && idealSecond - i < phases.length && (idealSecond - i) > maxSecond) {
        if (phases[idealSecond - i] == Phase.green) {
          // Return phase faster.
          return idealSecond - i;
        }
      }
      // Check in direction second + i. To prevent going for phases outside the maxSpeed.
      if (idealSecond + i < phases.length) {
        if (phases[idealSecond + i] == Phase.green) {
          // Return phase slower.
          return idealSecond + i;
        }
      }
    }
    // No phase found.
    return -1;
  }

  void startSlowerLoop() {
    if (settings.modalityMode == ModalityMode.vibration || settings.watchStandalone) {
      sendOutput("slower");
    } else {
      // Then start timer.
      audioPlayer1.play(AssetSource(audioInfo));
      timer = Timer.periodic(const Duration(milliseconds: 4000), (timer) {
        audioPlayer2.play(AssetSource(audioInfo));
      });
    }

    if (positioning.lastPosition != null) {
      testData.add(TestData(
          inputType: InputType.slowerLoop,
          timestamp: DateTime.now().toIso8601String(),
          lat: positioning.lastPosition!.latitude,
          lon: positioning.lastPosition!.longitude));
    }
  }

  void startFasterLoop() {
    if (settings.modalityMode == ModalityMode.vibration || settings.watchStandalone) {
      sendOutput("faster");
    } else {
      // Then start timer.
      audioPlayer1.play(AssetSource(audioInfo));
      timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        audioPlayer2.play(AssetSource(audioInfo));
      });
    }

    if (positioning.lastPosition != null) {
      testData.add(TestData(
          inputType: InputType.fasterLoop,
          timestamp: DateTime.now().toIso8601String(),
          lat: positioning.lastPosition!.latitude,
          lon: positioning.lastPosition!.longitude));
    }
  }

  void playSlower() {
    if (settings.modalityMode == ModalityMode.vibration || settings.watchStandalone) {
      sendOutput("slower");
    } else {
      // Then start timer.
      audioPlayer1.play(AssetSource(audioIntervalSlower));
    }

    if (positioning.lastPosition != null) {
      testData.add(TestData(
          inputType: InputType.slower,
          timestamp: DateTime.now().toIso8601String(),
          lat: positioning.lastPosition!.latitude,
          lon: positioning.lastPosition!.longitude));
    }
  }

  void playFaster() {
    if (settings.modalityMode == ModalityMode.vibration || settings.watchStandalone) {
      sendOutput("faster");
    } else {
      // Then start timer.
      audioPlayer1.play(AssetSource(audioIntervalFaster));
    }

    if (positioning.lastPosition != null) {
      testData.add(TestData(
          inputType: InputType.faster,
          timestamp: DateTime.now().toIso8601String(),
          lat: positioning.lastPosition!.latitude,
          lon: positioning.lastPosition!.longitude));
    }
  }

  void stopSignalLoop() {
    if (settings.modalityMode == ModalityMode.vibration || settings.watchStandalone) {
      sendOutput("stop_loop");
    } else {
      if (timer != null) {
        timer!.cancel();
        // To stop the signal immediately.
        audioPlayer1.stop();
        audioPlayer2.stop();
        timer = null;
      }
    }
    if (positioning.lastPosition != null) {
      testData.add(TestData(
          inputType: InputType.stop,
          timestamp: DateTime.now().toIso8601String(),
          lat: positioning.lastPosition!.latitude,
          lon: positioning.lastPosition!.longitude));
    }
  }

  /// Returns a bool if a suitable green phase is available for the current recommendation.
  bool greenPhaseAvailable(List<Phase> phases) {
    bool greenPhaseAvailable = false;
    final int maxSecond = ((ride.calcDistanceToNextSG! * 3.6) / settings.speedMode.maxSpeed).round();
    for (int i = maxSecond; i < phases.length; i++) {
      if (phases[i] == Phase.green) {
        greenPhaseAvailable = true;
      }
    }
    return greenPhaseAvailable;
  }

  /// Returns a bool if a suitable green phase is available for the current recommendation.
  bool greenPhaseAvailableInGoodRange(List<Phase> phases) {
    bool greenPhaseAvailable = false;
    final int maxSecond = ((ride.calcDistanceToNextSG! * 3.6) / (settings.speedMode.maxSpeed - 4)).round();
    final int minSecond = ((ride.calcDistanceToNextSG! * 3.6) / (8)).round();
    for (int i = maxSecond; i < phases.length && i < minSecond; i++) {
      if (phases[i] == Phase.green) {
        greenPhaseAvailable = true;
      }
    }
    return greenPhaseAvailable;
  }

  /// Function which plays the success signal.
  void playSuccess() {
    if (settings.modalityMode == ModalityMode.vibration || settings.watchStandalone) {
      // Send message to wear device.
      sendOutput("success");
    } else {
      playPhoneAudioSuccess();
    }

    if (positioning.lastPosition != null) {
      testData.add(TestData(
          inputType: InputType.success,
          timestamp: DateTime.now().toIso8601String(),
          lat: positioning.lastPosition!.latitude,
          lon: positioning.lastPosition!.longitude));
    }
  }

  /// Function which plays the info signal.
  void playInfo() {
    if (settings.modalityMode == ModalityMode.vibration || settings.watchStandalone) {
      // Send message to wear device.
      sendOutput("info");
    } else {
      playPhoneAudioInfo();
    }

    if (positioning.lastPosition != null) {
      testData.add(TestData(
          inputType: InputType.info,
          timestamp: DateTime.now().toIso8601String(),
          lat: positioning.lastPosition!.latitude,
          lon: positioning.lastPosition!.longitude));
    }
  }

  /// Function which plays the success signal in audio.
  Future<void> playPhoneAudioSuccess() async {
    // Audio fast.
    audioPlayer1.play(AssetSource(audioSuccess));
  }

  /// Function which plays the info signal in audio.
  Future<void> playPhoneAudioInfo() async {
    // Audio fast.
    audioPlayer1.play(AssetSource(audioInfo));
  }

  /// Function which plays the success signal in audio.
  Future<void> playWearVibrationSuccess() async {
    sendOutput("success");
  }

  /// Reset the service.
  Future<void> reset() async {
    inGreenPhase = null;
    slowLoopRunning = false;
    fastLoopRunning = false;
    stopSignalLoop();
    audioPlayer1.stop();
    audioPlayer2.stop();
    newPhaseCounter = 0;
    messagesPlayedCounter = -1;
    currentSG = null;
    notifyListeners();
  }

  /// Reset the service.
  Future<void> resetAll() async {
    inGreenPhase = null;
    slowLoopRunning = false;
    fastLoopRunning = false;
    stopSignalLoop();
    audioPlayer1.stop();
    audioPlayer2.stop();
    newPhaseCounter = 0;
    messagesPlayedCounter = -1;
    currentSG = null;
    notifyListeners();
  }
}
