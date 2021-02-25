import 'dart:async';

import 'package:priobike/models/api/api_route.dart';
import 'package:priobike/models/recommendation.dart';

abstract class Session {
  StreamController<ApiRoute> routeStreamController;
  StreamController<Recommendation> recommendationStreamController;

  void updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  );

  void updatePosition(
    double lat,
    double lon,
    int speed,
  );

  void stopRecommendation() {
    routeStreamController.close();
    recommendationStreamController.close();
  }
}
