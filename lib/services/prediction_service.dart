import 'dart:async';
import 'dart:convert';

import 'package:bikenow/config/logger.dart';
import 'package:bikenow/models/api/api_prediction.dart';
import 'package:bikenow/models/api/api_route.dart';
import 'package:bikenow/services/mqtt_service.dart';

class PredictionService {
  Logger log = new Logger('PredictionService');

  StreamController<Map<String, ApiPrediction>> predictionStreamController =
      new StreamController<Map<String, ApiPrediction>>.broadcast();

  Map<String, ApiPrediction> _predictions = new Map();

  ApiRoute _route;

  MqttService _mqttService;

  PredictionService({
    Stream<ApiRoute> routeStream,
  }) {
    _mqttService = new MqttService();

    _mqttService.messageStreamController.stream.listen((message) {
      ApiPrediction prediction = ApiPrediction.fromJson(json.decode(message));

      //TODO: Use correct topic or ID!
      _predictions['prediction/${prediction.lsaId}/${prediction.sgName}'] =
          prediction;

      predictionStreamController.add(_predictions);
    });

    routeStream.listen((newRoute) {
      _route = newRoute;
    });
  }

  subscribeToRoute() {
    log.i('Subscribe to route');
    _route.sg.forEach((sg) => _mqttService.subscribe(sg.mqtt));
  }

  unsubscribeFromRoute() {
    log.i('Unsubscribe from route');
    _route.sg.forEach((sg) => _mqttService.unsubscribe(sg.mqtt));
  }

  void dispose() {
    predictionStreamController.close();
  }
}
