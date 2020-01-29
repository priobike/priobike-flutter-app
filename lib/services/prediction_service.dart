import 'dart:async';
import 'dart:convert';

import 'package:bikenow/models/api/api_prediction.dart';
import 'package:bikenow/models/api/api_route.dart';
import 'package:bikenow/services/mqtt_service.dart';

class PredictionService {
  StreamController<Map<String, ApiPrediction>> predictionStreamController =
      new StreamController<Map<String, ApiPrediction>>.broadcast();

  Map<String, ApiPrediction> _predictions = new Map();

  ApiRoute _route;

  MqttService _mqttService;

  PredictionService({Stream<ApiRoute> routeStream}) {
    _mqttService = new MqttService();

    _mqttService.messageStreamController.stream.listen((message) {
      ApiPrediction prediction = ApiPrediction.fromJson(json.decode(message));

      //TODO: Use correct topic or ID!
      _predictions['prediction/${prediction.lsa}/${prediction.sg}'] = prediction;

      predictionStreamController.add(_predictions);
    });

    routeStream.listen((newRoute) {
      _route = newRoute;
    });
  }

  subscribeToRoute() {
    print('subbscribe to route?');
    _route.sg.forEach((sg) => _mqttService.subscribe(sg.mqtt));
  }

  unsubscribeFromRoute() {
    print('unubscribe from route?');
    _route.sg.forEach((sg) => _mqttService.unsubscribe(sg.mqtt));
  }


  void dispose() {
    predictionStreamController.close();
  }
}
