import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/settings/models/ride_assist.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/models/test.dart';
import 'package:priobike/settings/services/settings.dart';

const audioPath = "sounds/ding.mp3";

/// The minimum speed in km/h.
const minSpeed = 0.0;

class RideAssist with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("RideAssist");

  final positioning = getIt<Positioning>();
  final ride = getIt<Ride>();
  final settings = getIt<Settings>();

  final AudioPlayer audioPlayer1 = AudioPlayer();
  final AudioPlayer audioPlayer2 = AudioPlayer();
  final AudioPlayer audioPlayer3 = AudioPlayer();

  /// Bool that holds the state if the user is in a green phase
  bool? inGreenPhase;

  /// Update the position.
  Future<void> updatePosition() async {
    // TODO prechecks.
    // Check ride active.
    if (settings.rideAssistMode == RideAssistMode.none) return;
    if (!ride.navigationIsActive) return;
    if (ride.predictionComponent?.prediction?.predictionQuality == null) {
      // Set to null if there is no prediction.
      inGreenPhase = null;
      return;
    }
    // Check prediction quality. This is maybe not good.
    if (ride.predictionComponent!.prediction!.predictionQuality! <= 0.0) return;

    final double kmh = (positioning.lastPosition?.speed ?? 0.0) * 3.6;
    final double speed = (kmh - minSpeed) / (settings.speedMode.maxSpeed - minSpeed);
    if (speed <= 0) return;

    final phases = ride.predictionComponent!.recommendation!.calcPhasesFromNow;
    final qualities = ride.predictionComponent!.recommendation!.calcQualitiesFromNow;

    // Switch between modes.
    switch (settings.rideAssistMode) {
      case RideAssistMode.none:
        break;
      case RideAssistMode.easy:
        rideAssistEasy(phases, qualities, speed);
        break;
      case RideAssistMode.continuous:
        break;
      case RideAssistMode.interval:
        break;
    }

    notifyListeners();
  }

  /// Ride assist easy algorithm.
  rideAssistEasy(List<Phase> phases, List<double> qualities, double kmh) {
    // TODO Check currently in window
    // TODO Yes => Success signal?
    // TODO No => Message?

    // Calculate current Phase.
    final int second = ((ride.calcDistanceToNextSG! * 3.6) / kmh).round();

    // Second in array length.
    if (second < phases.length && second < qualities.length) {
      final phase = phases[second];
      final quality = qualities[second];

      // Check if there is a previous info on inGreenPhase.
      if (inGreenPhase != null) {
        if (phase == Phase.green) {
          if (!inGreenPhase!) {
            // Old recommendation and entering green phase window.
            playSuccess();
            inGreenPhase = true;
          }
        } else {
          if (inGreenPhase!) {
            // Old recommendation and leaving green phase window.
            playMessage();
            inGreenPhase = false;
          }
        }
      } else {
        if (phase == Phase.green) {
          // New recommendation and in green window phase.
          playSuccess();
          inGreenPhase = true;
        } else {
          // New recommendation and not in green window phase.
          // TODO Check if there is a green Phase.
          bool greenPhaseAvailable = false;
          for (int i = 0; i < phases.length; i++) {
            if (phases[i] == Phase.green) {
              greenPhaseAvailable = true;
            }
          }
          // Message that there is a green phase available.
          // TODO adjust how good the green phase needs to be.
          if (greenPhaseAvailable) {
            playMessage();
            inGreenPhase = false;
          }
        }
      }
    } else {
      log.e("Second outside of phases array.");
    }
  }

  /// Ride assist easy algorithm.
  rideAssistContinuous(List<Phase> phases, List<double> qualities, double kmh) {
    // TODO Check Green phase available.
    // TODO Check in window? => Yes do not play anything, No => decide faster or slower.

    // Calculate current Phase.
    final int second = ((ride.calcDistanceToNextSG! * 3.6) / kmh).round();

    // Second in array length.
    if (second < phases.length && second < qualities.length) {
      final phase = phases[second];
      final quality = qualities[second];

      if (greenPhaseAvailable(phases)) {
        // Check if in green phase => do nothing.
        if (phase == Phase.green) {
          return;
        }

        // Find suitable green phase.
        // From selected mode.
      }
    } else {
      log.e("Second outside of phases array.");
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
  }

  /// Function which plays the message signal.
  void playMessage() {
    if (settings.modalityMode == ModalityMode.audio) {
      playPhoneAudioMessage();
    }
  }

  /// Function which plays the success signal in audio.
  Future<void> playPhoneAudioSuccess() async {
    // Audio fast.
    audioPlayer1.play(AssetSource(audioPath));
    await Future.delayed(const Duration(milliseconds: 750));
    audioPlayer2.play(AssetSource(audioPath));
  }

  /// Function which plays the message signal in audio.
  Future<void> playPhoneAudioMessage() async {
    // Audio fast.
    audioPlayer1.play(AssetSource(audioPath));
  }

  Future<void> playPhoneAudioContinuous(InputType inputType) async {
    if (inputType == InputType.faster) {
      // Audio fast.
      audioPlayer1.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 750));
      audioPlayer2.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 750));
      audioPlayer3.play(AssetSource(audioPath));
    } else {
      // Audio slow.
      audioPlayer1.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 2000));
      audioPlayer2.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 2000));
      audioPlayer3.play(AssetSource(audioPath));
    }
  }

  Future<void> playPhoneAudioInterval(InputType inputType) async {
    if (inputType == InputType.faster) {
      // Audio fast.
      audioPlayer1.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 1000));
      audioPlayer2.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 500));
      audioPlayer3.play(AssetSource(audioPath));
    } else {
      // Audio slow.
      audioPlayer1.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 1500));
      audioPlayer2.play(AssetSource(audioPath));
      await Future.delayed(const Duration(milliseconds: 2000));
      audioPlayer3.play(AssetSource(audioPath));
    }
  }

  /// Reset the service.
  Future<void> reset() async {
    inGreenPhase = null;
    notifyListeners();
  }
}
