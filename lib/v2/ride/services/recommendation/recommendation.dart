import 'package:flutter/material.dart';
import 'package:priobike/v2/common/logger.dart';
import 'package:priobike/v2/ride/models/recommendation.dart';

class RecommendationService with ChangeNotifier {
  Logger log = Logger("RecommendationService");

  /// The current recommendation from the server.
  Recommendation? currentRecommendation;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  RecommendationService({this.currentRecommendation}) {
    log.i("RecommendationService started.");
  }

  /// Update the current user position and send it to the server.
  void updatePosition(
    double lat,
    double lon,
    double speed,
    double accuracy,
    double heading,
    DateTime? timestamp,
  ) {
    // TODO: Send the position update to the server.
  }

  @override 
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}