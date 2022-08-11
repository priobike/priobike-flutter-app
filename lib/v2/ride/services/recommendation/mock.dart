import 'package:priobike/v2/common/models/point.dart';
import 'package:priobike/v2/ride/models/recommendation.dart';
import 'package:priobike/v2/ride/services/recommendation/recommendation.dart';

class MockRecommendationService extends RecommendationService {
  MockRecommendationService() : super(
    currentRecommendation: Recommendation(
      label: "SG 1", 
      countdown: 8, 
      distance: 30, 
      speedRec: 18, 
      speedDiff: 2, 
      green: true, 
      error: false, 
      errorMessage: "", 
      snapPos: Point(lat: 53.564292, lon: 9.902202), 
      navText: "Weiter auf Friedensallee", 
      navSign: 1, 
      navDist: 10, 
      quality: 1, 
      predictionGreentimeThreshold: 50, 
      predictionStartTime: DateTime.now().toUtc().toIso8601String(), 
      predictionValue: [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100,
      ]
    ),
  );
}
