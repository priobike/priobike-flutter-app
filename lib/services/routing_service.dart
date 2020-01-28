import 'dart:async';

import 'package:bikenow/config/api.dart';
import 'package:bikenow/models/api/api_route.dart';

class RoutingService {
  StreamController<ApiRoute> routeStreamController =
      new StreamController<ApiRoute>.broadcast();

  RoutingService();

  updateRoute(fromLat, fromLon, toLat, toLon) async {
    print('update route');
    routeStreamController
        .add(await Api.getRoute(fromLat, fromLon, toLat, toLon));
  }

  void dispose() {
    routeStreamController.close();
  }
}
