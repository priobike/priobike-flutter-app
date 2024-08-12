import 'dart:math';
import 'dart:ui';

import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/ride/interfaces/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';

enum Phase {
  dark,
  red,
  amber,
  green,
  redAmber,
  amberFlashing,
  greenFlashing,
}

extension PhaseDescription on Phase {
  String get description {
    switch (this) {
      case Phase.dark:
        return "Dunkel";
      case Phase.red:
        return "Rot";
      case Phase.amber:
        return "Gelb";
      case Phase.green:
        return "Grün";
      case Phase.redAmber:
        return "Rot-Gelb";
      case Phase.amberFlashing:
        return "Gelb blinkend";
      case Phase.greenFlashing:
        return "Grün blinkend";
    }
  }
}

extension PhaseColor on Phase {
  static Phase fromInt(int i) {
    switch (i) {
      case 0:
        return Phase.dark;
      case 1:
        return Phase.red;
      case 2:
        return Phase.amber;
      case 3:
        return Phase.green;
      case 4:
        return Phase.redAmber;
      case 5:
        return Phase.amberFlashing;
      case 6:
        return Phase.greenFlashing;
      default:
        return Phase.dark;
    }
  }

  Color get color {
    switch (this) {
      case Phase.dark:
        return const Color(0xFF000000);
      case Phase.red:
        return CI.radkulturRed;
      case Phase.amber:
        return CI.radkulturYellow;
      case Phase.green:
        return const Color.fromARGB(255, 0, 255, 106);
      case Phase.redAmber:
        return CI.radkulturYellow;
      case Phase.amberFlashing:
        return CI.radkulturYellow;
      case Phase.greenFlashing:
        return const Color.fromARGB(255, 0, 255, 106);
    }
  }
}

class PredictionServicePrediction implements Prediction {
  /// Logger for this class.
  final log = Logger("Prediction-Service-Prediction");

  /// Lower threshold for probability to be green (37%-80%).
  final int greentimeThreshold;

  /// A value denoting the quality of a prediction.
  /// The value is given in the interval [0.0, 1.0], where
  /// 0.0 is the worst quality and 1.0 is the best quality.
  @override
  double predictionQuality;

  /// The signal group id for the prediction.
  final String signalGroupId;

  /// The reference time for this prediction.
  final DateTime startTime;

  /// A list of signal values, by second off the `startTime`.
  /// The values are given in probabilities that the signal is green.
  /// Use the `greentimeThreshold` to determine when a signal is green.
  /// That is, if the value is greater than the threshold.
  final List<int> value;

  // Create a prediction from a JSON map.
  PredictionServicePrediction.fromJson(Map<String, dynamic> json)
      : greentimeThreshold = json['greentimeThreshold'] as int,
        predictionQuality = json['predictionQuality'] as double,
        signalGroupId = json['signalGroupId'] as String,
        // Example: 2022-12-23T11:39:35Z[UTC]
        startTime = DateTime.parse((json['startTime'] as String).replaceAll("Z[UTC]", "Z")),
        value = (json['value'] as List<dynamic>).cast<int>();

  /// Write the prediction to a JSON map.
  @override
  Map<String, dynamic> toJson() => {
        'greentimeThreshold': greentimeThreshold,
        'predictionQuality': predictionQuality,
        'signalGroupId': signalGroupId,
        'startTime': startTime.toIso8601String(),
        'value': value,
      };

  @override
  Future<Recommendation?> calculateRecommendation() async {
    List<Phase> calcPhasesFromNow;
    List<double> calcQualitiesFromNow;
    DateTime? calcCurrentPhaseChangeTime;
    Phase calcCurrentSignalPhase;

    // This will be executed if we fail somewhere.
    onFailure(reason) {
      log.w("Failed to calculate prediction service info: $reason");
      return null;
    }

    // Check if we have all necessary information.
    if (greentimeThreshold == -1) return onFailure("No greentime threshold.");
    if (predictionQuality == -1) return onFailure("No prediction quality.");
    if (value.isEmpty) return onFailure("No prediction vector.");
    // Calculate the seconds since the start of the prediction.
    final now = DateTime.now();
    final secondsSinceStart = max(0, now.difference(startTime).inSeconds);
    // Chop off the seconds that are not in the prediction vector.
    final secondsInVector = value.length;
    if (secondsSinceStart >= secondsInVector) return onFailure("Prediction vector is too short.");
    // Calculate the current vector.
    final currentVector = value.sublist(secondsSinceStart);
    if (currentVector.isEmpty) return onFailure("Current vector is empty.");
    // Calculate the seconds to the next phase change.
    int secondsToPhaseChange = 0;
    // Check if the phase changes within the current vector.
    var phaseChangeWithinVector = false;
    bool greenNow = currentVector[0] >= greentimeThreshold;
    for (int i = 1; i < currentVector.length; i++) {
      final greenThen = currentVector[i] >= greentimeThreshold;
      if ((greenNow && !greenThen) || (!greenNow && greenThen)) {
        phaseChangeWithinVector = true;
        break;
      }
      secondsToPhaseChange++;
    }

    calcPhasesFromNow = currentVector.map(
      (value) {
        if (value >= greentimeThreshold) {
          return Phase.green;
        } else {
          return Phase.red;
        }
      },
    ).toList();

    // Calculate the qualities from now. The quality is incorporated in the prediction vector.
    // For example, when the prediction is: [0, 0, 25, 75, 75, 75, 100] and the threshold is 50,
    // then the qualities are: [1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 1.0], scaled between min and max.
    final minQuality = currentVector.reduce(min);
    final maxQuality = currentVector.reduce(max);
    if (minQuality == maxQuality) {
      // All values are the same.
      calcQualitiesFromNow = currentVector.map((_) => (predictionQuality)).toList();
    } else {
      calcQualitiesFromNow = currentVector.map((value) {
        // If the value is below the threshold, scale between min (quality = 1) and threshold (quality = 0).
        if (value < greentimeThreshold) {
          return (1 - (value - minQuality) / (greentimeThreshold - minQuality));
        } else {
          // If the value is above the threshold, scale between threshold (quality = 0) and max (quality = 1).
          return (1 - (maxQuality - value) / (maxQuality - greentimeThreshold));
        }
      }).toList();
    }

    if (phaseChangeWithinVector) {
      // Only calculate the phase change time if the phase changes within the current vector.
      // Otherwise the countdown will be shown, counting down to the end of the prediction (into the "unknown").
      calcCurrentPhaseChangeTime = now.add(Duration(seconds: secondsToPhaseChange));
    }
    calcCurrentSignalPhase = greenNow ? Phase.green : Phase.red;

    return Recommendation(calcPhasesFromNow, calcQualitiesFromNow, calcCurrentPhaseChangeTime, calcCurrentSignalPhase);
  }
}
