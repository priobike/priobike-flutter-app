enum SGPredictionState {
  /// The prediction is fine.
  ok,

  /// The traffic light is offline.
  offline,

  /// The prediction has a bad quality.
  bad,
}

class SGStatusData {
  /// The time of the status update in unix seconds.
  final int statusUpdateTime;

  /// The name of the thing.
  final String thingName;

  /// The current prediction quality, if there is a prediction.
  final double? predictionQuality;

  /// The unix time of the last predictio in seconds, if there is a prediction.
  final int? predictionTime;

  /// The current prediction state.
  SGPredictionState get predictionState {
    if (predictionQuality == null || predictionTime == null) {
      return SGPredictionState.offline;
    }
    if (Duration(seconds: statusUpdateTime - predictionTime!).inMinutes > 5) {
      return SGPredictionState.offline;
    }
    if (predictionQuality! < 0.9) {
      return SGPredictionState.bad;
    }
    if (predictionQuality! < 0.5) {
      return SGPredictionState.offline;
    }
    return SGPredictionState.ok;
  }

  const SGStatusData({
    required this.statusUpdateTime,
    required this.thingName,
    this.predictionQuality,
    this.predictionTime,
  });

  factory SGStatusData.fromJson(Map<String, dynamic> json) => SGStatusData(
        statusUpdateTime: json['status_update_time'],
        thingName: json['thing_name'],
        predictionQuality: json['prediction_quality'] is int
            ? json['prediction_quality'].toDouble()
            : json['prediction_quality'],
        predictionTime: json['prediction_time'],
      );
}
