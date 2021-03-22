import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as HTTP;
import 'package:priobike/config/config.dart';

import 'package:priobike/models/api/api_route.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/route_request.dart';

abstract class Session {
  StreamController<ApiRoute> routeStreamController =
      new StreamController<ApiRoute>();

  StreamController<Recommendation> recommendationStreamController =
      new StreamController<Recommendation>();

  HTTP.Client _httpClient = HTTP.Client();

  void updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    _httpClient
        .post('${Config.GATEWAY_URL}:${Config.GATEWAY_PORT}/routing/getroute',
            body: new RouteRequest(
              fromLat: fromLat,
              fromLon: fromLon,
              toLat: toLat,
              toLon: toLon,
            ).toJson())
        .then((HTTP.Response response) {
      routeStreamController.add(ApiRoute.fromJson(json.decode(response.body)));
    });
  }

  void updatePosition(
    double lat,
    double lon,
    int speed,
  );

  void startRecommendation();

  void stopRecommendation();

  void dispose() {
    routeStreamController.close();
    recommendationStreamController.close();
  }
}
