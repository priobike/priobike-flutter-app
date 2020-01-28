import 'dart:async';

import 'package:bikenow/config/api.dart';
import 'package:bikenow/models/route_answer.dart';

class RoutingService {
  StreamController<RouteAnswer> routeStreamController =
      new StreamController<RouteAnswer>.broadcast();

  RoutingService();

  updateRoute(fromLat, fromLon, toLat, toLon) async {
    routeStreamController
        .add(await Api.getRoute(fromLat, fromLon, toLat, toLon));
  }

  void dispose() {
    routeStreamController.close();
  }
}
