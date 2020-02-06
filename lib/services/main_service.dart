import 'package:bikenow/services/gateway_status_service.dart';
import 'package:bikenow/services/geolocator_service.dart';
import 'package:bikenow/services/prediction_service.dart';
import 'package:bikenow/services/routing_service.dart';
import 'package:bikenow/services/vorhersage_service.dart';
import 'package:flutter/foundation.dart';

class MainService with ChangeNotifier {
  bool loading = false;

  GatewayStatusService gatewayStatusService;
  RoutingService routingService;
  PredictionService predictionService;
  VorhersageService vorhersageService;
  GeolocatorService geolocatorService;

  MainService() {
    gatewayStatusService = new GatewayStatusService();

    routingService = new RoutingService();

    predictionService = new PredictionService(
      routeStream: routingService.routeStreamController.stream,
    );

    geolocatorService = new GeolocatorService();

    vorhersageService = new VorhersageService(
      gatewayStatusService: gatewayStatusService,
      routeStream: routingService.routeStreamController.stream,
      predictionStream: predictionService.predictionStreamController.stream,
      locationStream: geolocatorService.locationStreamController.stream,
    );
  }
}
