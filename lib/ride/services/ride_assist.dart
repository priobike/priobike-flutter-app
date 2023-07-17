import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/settings/models/ride_assist.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:wearable_communicator/wearable_communicator.dart';

// TODO better audios.
const audioPath = "sounds/ding.mp3";

/// The threshold for a new phase.
const int newPhaseThreshold = 2;

class RideAssist with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("RideAssist");

  final positioning = getIt<Positioning>();
  final ride = getIt<Ride>();
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

  /// The timer used for the signal loops.
  Timer? timer;

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
  }

  /// Send play output message to device.
  void sendOutput(String type) {
    String outputSignal = "${settings.modalityMode.name}-${settings.rideAssistMode.name}-$type";
    WearableCommunicator.sendMessage({
      "play": outputSignal,
    });
  }

  /// Send stop message to device.
  void sendStop() {
    WearableCommunicator.sendMessage({
      "stopNavigation": true,
    });
  }

  /// Update the position.
  Future<void> updatePosition() async {
    // TODO prechecks.
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

    final phases = ride.predictionComponent!.recommendation!.calcPhasesFromNow;
    final qualities = ride.predictionComponent!.recommendation!.calcQualitiesFromNow;

    // Switch between modes.
    switch (settings.rideAssistMode) {
      case RideAssistMode.easy:
        rideAssistEasy(phases, qualities, kmh);
        break;
      case RideAssistMode.continuous:
        rideAssistContinuous(phases, qualities, kmh);
        break;
      case RideAssistMode.interval:
        break;
      case RideAssistMode.none:
        return;
    }

    notifyListeners();
  }

  /// Ride assist easy algorithm.
  /// TODO Refactor code.
  rideAssistEasy(List<Phase> phases, List<double> qualities, double kmh) {
    // Calculate current Phase.
    final int second = ((ride.calcDistanceToNextSG! * 3.6) / kmh).round();

    // Second in array length.
    // TODO second > phases.length => there can still be a green phase.
    if (second < phases.length && second < qualities.length && second >= 0) {
      final phase = phases[second];
      final quality = qualities[second];

      // Check if there is a previous value of inGreenPhase.
      if (inGreenPhase != null) {
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
        if (phase == Phase.green) {
          // New recommendation and in green window phase.
          playSuccess();
          inGreenPhase = true;
          newPhaseCounter = 0;
        } else {
          // New recommendation and not in green window phase.
          // TODO Check if there is a green Phase.
          if (greenPhaseAvailable(phases)) {
            playInfo();
            inGreenPhase = false;
            newPhaseCounter = 0;
          }
          // Message that there is a green phase available.
          // TODO adjust how good the green phase needs to be.
        }
      }
    } else {
      log.e("Second outside of phases array.");
    }
  }

  /// Ride assist continuous algorithm.
  rideAssistContinuous(List<Phase> phases, List<double> qualities, double kmh) {
    // Calculate current Phase.
    final int second = ((ride.calcDistanceToNextSG! * 3.6) / kmh).round();

    // Second in array length.
    // TODO second > phases.length => there can still be a green phase.
    if (second < phases.length && second < qualities.length && second >= 0) {
      final phase = phases[second];
      final quality = qualities[second];

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
    } else {
      log.e("Second outside of phases array.");
    }
  }

  /// Returns the int of the closest green phase (on same distance faster is returned).
  /// TODO max speed bug.
  int getClosestPhase(phases, second) {
    for (int i = 0; i < phases.length; i++) {
      // Check in direction second - i.
      if (second - i >= 0) {
        if (phases[second - i] == Phase.green) {
          // Return phase faster.
          return second - i;
        }
      }
      // Check in direction second + i.
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

  void startSlowerLoop() {
    if (settings.modalityMode == ModalityMode.vibration) {
      sendOutput("slower");
    } else {
      // Then start timer.
      timer = Timer.periodic(const Duration(milliseconds: 3000), (timer) {
        audioPlayer1.play(AssetSource(audioPath));
      });
    }
  }

  void startFasterLoop() {
    if (settings.modalityMode == ModalityMode.vibration) {
      sendOutput("faster");
    } else {
      // Then start timer.
      timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        audioPlayer1.play(AssetSource(audioPath));
      });
    }
  }

  void stopSignalLoop() {
    if (settings.modalityMode == ModalityMode.vibration) {
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
  }

  /// Returns a bool if a suitable green phase is available for the current recommendation.
  bool greenPhaseAvailable(List<Phase> phases) {
    bool greenPhaseAvailable = false;
    for (int i = 0; i < phases.length; i++) {
      if (phases[i] == Phase.green) {
        greenPhaseAvailable = true;
      }
    }
    return greenPhaseAvailable;
  }

  /// Function which plays the success signal.
  void playSuccess() {
    if (settings.modalityMode == ModalityMode.audio) {
      playPhoneAudioSuccess();
    }
    if (settings.modalityMode == ModalityMode.vibration) {
      // Send message to wear device.
      sendOutput("success");
    }
  }

  /// Function which plays the info signal.
  void playInfo() {
    if (settings.modalityMode == ModalityMode.audio) {
      playPhoneAudioInfo();
    }
    if (settings.modalityMode == ModalityMode.vibration) {
      // Send message to wear device.
      sendOutput("info");
    }
  }

  /// Function which plays the success signal in audio.
  Future<void> playPhoneAudioSuccess() async {
    // Audio fast.
    audioPlayer1.play(AssetSource(audioPath));
    await Future.delayed(const Duration(milliseconds: 500));
    audioPlayer2.play(AssetSource(audioPath));
  }

  /// Function which plays the info signal in audio.
  Future<void> playPhoneAudioInfo() async {
    // Audio fast.
    audioPlayer1.play(AssetSource(audioPath));
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
    notifyListeners();
  }
}
