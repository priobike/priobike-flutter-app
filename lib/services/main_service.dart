import 'package:bikenow/services/gateway_status_service.dart';
import 'package:bikenow/services/geolocation_service.dart';
import 'package:bikenow/services/prediction_service.dart';
import 'package:bikenow/services/routing_service.dart';
import 'package:bikenow/services/recommendation_service.dart';
import 'package:bikenow/services/selection_service.dart';
import 'package:flutter/foundation.dart';

class MainService with ChangeNotifier {
  bool loading = false;

  GatewayStatusService gatewayStatusService;
  RoutingService routingService;
  PredictionService predictionService;
  RecommendationService recommendationService;
  GeolocationService geolocationService = new GeolocationService();
  SelectionService selectionService;

  MainService() {
    gatewayStatusService = new GatewayStatusService();
    routingService = new RoutingService();

    predictionService = new PredictionService(
      routeStream: routingService.routeStreamController.stream,
    );

    selectionService = new SelectionService(
      routeStream: routingService.routeStreamController.stream,
      positionStream: geolocationService.positionStreamController.stream,
    );

    recommendationService = new RecommendationService(
      gatewayStatusService: gatewayStatusService,
      nextSgStream: selectionService.nextSgStreamController.stream,
      predictionStream: predictionService.predictionStreamController.stream,
      positionStream: geolocationService.positionStreamController.stream,
    );
  }
}
