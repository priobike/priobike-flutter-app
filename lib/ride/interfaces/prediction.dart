import 'package:priobike/ride/models/recommendation.dart';

abstract class Prediction {
  /// The current prediction quality in [0.0, 1.0]. Calculated periodically.
  double? get predictionQuality;

  Map<String, dynamic> toJson();

  Future<Recommendation?> calculateRecommendation();
}
