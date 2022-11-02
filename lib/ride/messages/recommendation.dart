import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:priobike/common/models/point.dart';

class Recommendation {
  /// The time in unix millis.
  final int timeUnixMillis;

  /// The label of the next point of interest.
  final String label;

  /// The countdown in seconds until the next signal change.
  final int countdown;

  /// The distance to the signal in meters.
  final double distance;

  /// The speed recommendation to the next signal in km/h.
  final double speedRec;

  /// The difference in speed to reach the speed recommendation in km/h.
  final double speedDiff;

  /// A flag to indicate whether the signal is predicted to be green right now.
  final bool isGreen;

  /// A flag to indicate whether there was an error while calculating the recommendation.
  final bool error;

  /// The error message. Is only set if `error` is `true`.
  final String? errorMessage;

  /// The user position, snapped to the route.
  final Point snapPos;

  /// A quality indicator for the recommendation, between 0 and 1.
  final double? quality;

  /// A text indicating the next navigation event.
  final String? navText;

  /// A sign for the next navigation event.
  final int navSign;

  /// The distance to the next navigation event in meters.
  final double navDist;

  /// The prediction greentime threshold, between 0 and 1.
  final int? predictionGreentimeThreshold;

  /// The prediction start reference time, in ISO_DATE_TIME format.
  /// See: https://docs.oracle.com/javase/8/docs/api/java/time/format/DateTimeFormatter.html#ISO_DATE_TIME
  final String? predictionStartTime;

  /// A list of signal values, by second off the `predictionStartTime`.
  /// The values are given in probabilities that the signal is green.
  /// Use the `predictionGreentimeThreshold` to determine when a signal is green.
  /// That is, if the value is greater than the threshold.
  final List<int>? predictionValue;

  /// The id of the upcoming signal group.
  /// Can be null if there is no upcoming signal group.
  final String? sgId;

  /// The position of the upcoming signal group.
  /// Can be null if there is no upcoming signal group.
  final Point? sgPos;

  const Recommendation({
    required this.timeUnixMillis,
    required this.label,
    required this.countdown,
    required this.distance,
    required this.speedRec,
    required this.speedDiff,
    required this.isGreen,
    required this.error,
    required this.errorMessage,
    required this.snapPos,
    required this.navText,
    required this.navSign,
    required this.navDist,
    required this.quality,
    required this.predictionGreentimeThreshold,
    required this.predictionStartTime,
    required this.predictionValue,
    required this.sgId,
    required this.sgPos,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      // Time is optional and will be created by the client if not provided.
      timeUnixMillis:
          json['timeUnixMillis'] ?? DateTime.now().millisecondsSinceEpoch,
      label: json['label'],
      countdown: json['countdown'],
      distance: json['distance'],
      speedRec: json['speedRec'],
      speedDiff: json['speedDiff'],
      isGreen: json['green'],
      error: json['error'],
      errorMessage: json['errorMessage'],
      snapPos: Point.fromJson(json['snapPos']),
      quality: json['quality'],
      navText: json['navText'],
      navSign: json['navSign'],
      navDist: json['navDist'],
      predictionGreentimeThreshold: json['predictionGreentimeThreshold'],
      predictionStartTime: json['predictionStartTime'],
      predictionValue:
          (json['predictionValue'] as List?)?.map((e) => e as int).toList(),
      sgId: json['sgId'],
      sgPos: json['sgPos'] != null ? Point.fromJson(json['sgPos']) : null,
    );
  }

  factory Recommendation.fromJsonRPC(Parameters params) {
    final map = params.asMap.map((key, value) {
      return MapEntry<String, dynamic>(key, value);
    });

    return Recommendation.fromJson(map);
  }

  Map<String, dynamic> toJson() => {
        'timeUnixMillis': timeUnixMillis,
        'label': label,
        'countdown': countdown,
        'distance': distance,
        'speedRec': speedRec,
        'speedDiff': speedDiff,
        'green': isGreen,
        'error': error,
        'errorMessage': errorMessage,
        'snapPos': snapPos.toJson(),
        'navText': navText,
        'navSign': navSign,
        'navDist': navDist,
        'quality': quality,
        'predictionGreentimeThreshold': predictionGreentimeThreshold,
        'predictionStartTime': predictionStartTime,
        'predictionValue': predictionValue,
        'sgId': sgId,
        'sgPos': sgPos,
      };
}
