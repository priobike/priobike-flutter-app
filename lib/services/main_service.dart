import 'package:bikenow/services/prediction_service.dart';
import 'package:bikenow/services/routing_service.dart';
import 'package:bikenow/services/vorhersage_service.dart';
import 'package:flutter/foundation.dart';

class MainService with ChangeNotifier{
  bool loading = false;

  RoutingService routingService;
  PredictionService predictionService;
  VorhersageService vorhersageService;

  MainService() {
    routingService = new RoutingService();

    predictionService = new PredictionService(
      routeStream: routingService.routeStreamController.stream,
    );

    vorhersageService = new VorhersageService(
      routeStream: routingService.routeStreamController.stream,
      predictionStream: predictionService.predictionStreamController.stream,
    );
  }
}
