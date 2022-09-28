class StatusSummaryData {
  /// The unix time of the last status update.
  final int statusUpdateTime;

  /// The number of things fetched.
  final int numThings;

  /// The number of predictions made.
  final int numPredictions;

  /// The number of bad predictions (quality < 0.5) made.
  final int numBadPredictions;

  /// The unix time of the most recent prediction.
  final int? mostRecentPredictionTime;

  /// The unix time of the oldest prediction.
  final int? oldestPredictionTime;

  /// The average prediction quality.
  final double? averagePredictionQuality;

  const StatusSummaryData({
    required this.statusUpdateTime,
    required this.numThings,
    required this.numPredictions,
    required this.numBadPredictions,
    this.mostRecentPredictionTime,
    this.oldestPredictionTime,
    this.averagePredictionQuality,
  });

  factory StatusSummaryData.fromJson(Map<String, dynamic> json) => StatusSummaryData(
    statusUpdateTime: json['status_update_time'],
    numThings: json['num_things'],
    numPredictions: json['num_predictions'],
    numBadPredictions: json['num_bad_predictions'],
    mostRecentPredictionTime: json['most_recent_prediction_time'],
    oldestPredictionTime: json['oldest_prediction_time'],
    averagePredictionQuality: json['average_prediction_quality'] is int
        ? json['average_prediction_quality'].toDouble()
        : json['average_prediction_quality'],
  );

  Map<String, dynamic> toJsonCamelCase() => {
    'statusUpdateTime': statusUpdateTime,
    'numThings': numThings,
    'numPredictions': numPredictions,
    'numBadPredictions': numBadPredictions,
    'mostRecentPredictionTime': mostRecentPredictionTime,
    'oldestPredictionTime': oldestPredictionTime,
    'averagePredictionQuality': averagePredictionQuality,
  };
}