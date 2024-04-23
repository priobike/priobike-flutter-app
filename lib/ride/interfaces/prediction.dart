import 'package:priobike/ride/models/recommendation.dart';

abstract class Prediction {
  /// The current prediction quality in [0.0, 1.0]. Calculated periodically.
  double? get predictionQuality;

  String get signalGroupId;

  /// A toJson method to convert the prediction to a json object. The implementation depends on the specific properties
  /// of the prediction type.
  Map<String, dynamic> toJson();

  /// A method to calculate the recommendation properties. The implementation depends on the specific properties
  /// of the prediction type.
  Future<Recommendation?> calculateRecommendation();
}
