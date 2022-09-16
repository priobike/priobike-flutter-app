import 'package:priobike/common/models/point.dart';
import 'package:priobike/ride/messages/recommendation.dart';
import 'package:priobike/ride/services/ride/ride.dart';

class MockRide extends Ride {
  MockRide() : super(
    currentRecommendation: Recommendation(
      label: "SG 1", 
      countdown: 8, 
      distance: 30, 
      speedRec: 18, 
      speedDiff: 2, 
      isGreen: true, 
      error: false, 
      errorMessage: "", 
      snapPos: const Point(lat: 53.564292, lon: 9.902202), 
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
      ],
      sgId: "SG 1",
      sgPos: const Point(lat: 53.564292, lon: 9.902202),
    ),
  );
}
