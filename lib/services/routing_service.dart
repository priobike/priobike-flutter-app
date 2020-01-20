import 'package:bikenow/config/api.dart';
import 'package:bikenow/models/route_answer.dart';
import 'package:flutter/foundation.dart';

class RoutingService with ChangeNotifier {
  RouteAnswer answer = new RouteAnswer();
  bool loading = false;

  getRoute(fromLat, fromLon, toLat, toLon) async {
    loading = true;
    notifyListeners();

    answer = await Api.getRoute(fromLat, fromLon, toLat, toLon);
    loading = false;
    notifyListeners();
  }
}
