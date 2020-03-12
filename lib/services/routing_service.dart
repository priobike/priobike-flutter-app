import 'dart:async';

import 'package:bikenow/config/api.dart';
import 'package:bikenow/config/logger.dart';
import 'package:bikenow/models/api/api_route.dart';
import 'package:flutter/foundation.dart';

class RoutingService with ChangeNotifier {
  Logger log = new Logger('RoutingService');

  StreamController<ApiRoute> routeStreamController =
      new StreamController<ApiRoute>.broadcast();

  ApiRoute route;

  RoutingService();

  updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
    String id,
  ) async {
    log.i('Update route');
    route = await Api.getRoute(fromLat, fromLon, toLat, toLon, id);
    routeStreamController.add(route);
    // notifyListeners();
  }

  @override
  void dispose() {
    routeStreamController.close();
    super.dispose();
  }
}
