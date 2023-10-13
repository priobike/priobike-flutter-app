import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
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
        return CI.radkulturYellow;
      case Phase.amber:
        return const Color.fromARGB(255, 255, 251, 0);
      case Phase.green:
        // Don't use the CI green here.
        return const Color.fromARGB(255, 0, 255, 106);
      case Phase.redAmber:
        return const Color.fromARGB(255, 255, 251, 0);
      case Phase.amberFlashing:
        return const Color.fromARGB(255, 255, 251, 0);
      case Phase.greenFlashing:
        return const Color.fromARGB(255, 0, 255, 106);
    }
  }
}

class PredictorPrediction implements Prediction {
  /// Logger for this class.
  final log = Logger("Predictor-Prediction");

  /// The thing name of the signal.
  final String thingName;

  /// The prediction vector from the reference time ("now").
  final Uint8List now;

  /// The quality of the prediction vector from the reference time ("now").
  final Uint8List nowQuality;

  /// The prediction vector continuing "now".
  final Uint8List then;

  /// The quality of the prediction vector continuing "now".
  final Uint8List thenQuality;

  /// The reference time of the prediction.
  final DateTime referenceTime;

  /// The program ID of the prediction.
  final int? programId;

  /// The current prediction quality in [0.0, 1.0]. Calculated periodically.
  @override
  double? predictionQuality;

  /// Create a prediction from a JSON map.
  PredictorPrediction.fromJson(Map<String, dynamic> json)
      : thingName = json['thingName'] as String,
        now = base64Decode(json['now'] as String),
        nowQuality = base64Decode(json['nowQuality'] as String),
        then = base64Decode(json['then'] as String),
        thenQuality = base64Decode(json['thenQuality'] as String),
        referenceTime = DateTime.parse(json['referenceTime'] as String),
        programId = json['programId'] as int?;

  /// Write the prediction to a JSON map.
  @override
  Map<String, dynamic> toJson() => {
        'thingName': thingName,
        'now': base64Encode(now),
        'nowQuality': base64Encode(nowQuality),
        'then': base64Encode(then),
        'thenQuality': base64Encode(thenQuality),
        'referenceTime': referenceTime.toIso8601String(),
        'programId': programId,
      };

  @override
  Future<Recommendation?> calculateRecommendation() async {
    List<Phase> calcPhasesFromNow;
    List<double> calcQualitiesFromNow;
    DateTime? calcCurrentPhaseChangeTime;
    Phase calcCurrentSignalPhase;

    // This will be executed if we fail somewhere.
    onFailure(String? reason) {
      log.w("Failed to calculate predictor info: $reason");
      return null;
    }

    // The prediction is split into two parts: "now" and "then".
    // "now" is the predicted behavior within the current cycle, which can deviate from the average behavior.
    // "then" is the predicted behavior after the cycle, which is the average behavior.
    final now = this.now.map((e) => PhaseColor.fromInt(e)).toList();
    if (now.isEmpty) return onFailure("No prediction available (now.length == 0)");
    final nowQuality = this.nowQuality.map((e) => e.toInt() / 100).toList();
    final then = this.then.map((e) => PhaseColor.fromInt(e)).toList();
    if (then.isEmpty) return onFailure("No prediction available (then.length == 0)");
    final thenQuality = this.thenQuality.map((e) => e.toInt() / 100).toList();
    final diff = DateTime.now().difference(referenceTime).inSeconds;
    if (diff > 300) return onFailure("Prediction is too old: $diff seconds");
    var index = diff;

    calcPhasesFromNow = <Phase>[];
    calcQualitiesFromNow = <double>[];
    // Keep the index of the reference time in the prediction.
    // This is 0 unless the reference time is in the future.
    var refTimeIdx = 0;
    // Check if the prediction is in the future.
    if (index < -then.length) {
      // Small deviations (-2 seconds, -1 seconds) are to be expected due to clock deviations,
      // but if the prediction is too far in the future, something must have gone wrong.
      return onFailure("Prediction is too far in the future: $index seconds");
    } else if (index < 0) {
      log.w("Prediction is in the future: $index seconds");
      // Take the last part of the "then" prediction until we reach the start of "now".
      calcPhasesFromNow = calcPhasesFromNow + then.sublist(then.length + index, then.length);
      calcQualitiesFromNow = calcQualitiesFromNow + thenQuality.sublist(then.length + index, then.length);
      refTimeIdx = calcPhasesFromNow.length; // To calculate the current phase.
      index = max(0, index);
    }
    // Calculate the phases from the start time of "now".
    if (index < now.length) {
      // We are within the "now" part of the prediction.
      calcPhasesFromNow = calcPhasesFromNow + now.sublist(index);
      calcQualitiesFromNow = calcQualitiesFromNow + nowQuality.sublist(index);
    } else {
      // We are within the "then" part of the prediction.
      calcPhasesFromNow = calcPhasesFromNow + then.sublist((index - now.length) % then.length);
      calcQualitiesFromNow = calcQualitiesFromNow + thenQuality.sublist((index - now.length) % then.length);
    }
    // Fill the phases with "then" (the average behavior) until we have enough values.
    while (calcPhasesFromNow.length < refTimeIdx + 300) {
      calcPhasesFromNow = calcPhasesFromNow + then;
      calcQualitiesFromNow = calcQualitiesFromNow + thenQuality;
    }
    // Calculate the current phase.
    final currentPhase = calcPhasesFromNow[refTimeIdx];
    // Calculate the current phase change time.
    for (int i = refTimeIdx; i < calcPhasesFromNow.length; i++) {
      if (calcPhasesFromNow[i] != currentPhase) {
        calcCurrentPhaseChangeTime = DateTime.now().add(Duration(seconds: i));
        break;
      }
    }
    calcCurrentSignalPhase = currentPhase;
    predictionQuality = calcQualitiesFromNow[refTimeIdx];
    return Recommendation(calcPhasesFromNow, calcQualitiesFromNow, calcCurrentPhaseChangeTime, calcCurrentSignalPhase);
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
      log.w("Failed to calculate predictor info: $reason");
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
