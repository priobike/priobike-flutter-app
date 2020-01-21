import 'package:bikenow/config/api.dart';
import 'package:bikenow/models/predictions.dart';
import 'package:bikenow/models/route_answer.dart';
import 'package:flutter/foundation.dart';

import 'mqtt_service.dart';

class MainService with ChangeNotifier {
  MqttService _mqttService = new MqttService();

  bool loading = false;
  RouteAnswer route = new RouteAnswer();

  Map<String, Prediction> predictions;

  MainService() {
    _mqttService.predictionStream.listen((data) {
      predictions = data;
      notifyListeners();
    });
  }

  updateRoute(fromLat, fromLon, toLat, toLon) async {
    // unsubscribe from previous topics
    unsubscribeFromRoute();

    // set loading flag
    loading = true;
    notifyListeners();

    //get route from server
    route = await Api.getRoute(fromLat, fromLon, toLat, toLon);
    loading = false;
    notifyListeners();
  }

  subscribeToRoute() {
    route.sg.forEach((sg) => _mqttService.subscribe(sg.mqtt));
  }

  unsubscribeFromRoute() {
    // predictions ?? predictions.keys.length > 0 ?? predictions?.keys?.forEach((topic) => _mqttService.unsubscribe(topic));
  }
}
