import 'dart:async';

import 'package:bikenow/config/api.dart';
import 'package:bikenow/models/api/api_route.dart';
import 'package:flutter/foundation.dart';

class RoutingService with ChangeNotifier {
  StreamController<ApiRoute> routeStreamController =
      new StreamController<ApiRoute>.broadcast();

  ApiRoute route;

  RoutingService();

  updateRoute(fromLat, fromLon, toLat, toLon) async {
    print('update route');
    route = await Api.getRoute(fromLat, fromLon, toLat, toLon);
    routeStreamController.add(route);
    // notifyListeners();
  }

  @override
  void dispose() {
    routeStreamController.close();
    super.dispose();
  }
}
