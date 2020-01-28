import 'dart:async';
import 'dart:convert';

import 'package:bikenow/models/prediction.dart';
import 'package:bikenow/models/route_answer.dart';
import 'package:bikenow/services/mqtt_service.dart';

class PredictionService {
  StreamController<Map<String, Prediction>> predictionStreamController =
      new StreamController<Map<String, Prediction>>.broadcast();

  Map<String, Prediction> _predictions = new Map();

  MqttService _mqttService;

  PredictionService({Stream<RouteAnswer> routeStream}) {
    _mqttService = new MqttService();

    _mqttService.messageStreamController.stream.listen((message) {
      Prediction prediction = Prediction.fromJson(json.decode(message));

      //TODO: Use correct topic or ID!
      _predictions['${prediction.lsa}#${prediction.sg}'] = prediction;

      predictionStreamController.add(_predictions);
    });


    routeStream.listen((route) => subscribeToRoute(route));
  }

  subscribeToRoute(route) {
    route.sg.forEach((sg) => _mqttService.subscribe(sg.mqtt));
  }

  // TODO: implement unsubscribeFromRoute!
  // unsubscribeFromRoute() {
  //   predictions?.keys?.forEach((topic) => _mqttService.unsubscribe(topic));
  // }

  void dispose() {
    predictionStreamController.close();
  }
}
