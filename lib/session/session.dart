import 'dart:async';

import 'package:priobike/models/api/api_route.dart';
import 'package:priobike/models/recommendation.dart';

abstract class Session {
  StreamController<ApiRoute> routeStreamController =
      new StreamController<ApiRoute>();

  StreamController<Recommendation> recommendationStreamController =
      new StreamController<Recommendation>();

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

  void startRecommendation() {}

  void stopRecommendation() {}

  void dispose() {
    routeStreamController.close();
    recommendationStreamController.close();
  }
}
