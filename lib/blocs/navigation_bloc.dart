import 'dart:async';
import 'dart:convert';

import 'package:bike_now/server_response/websocket_response.dart';
import 'package:bike_now/server_response/websocket_response_predictions.dart';
import 'package:bike_now/websocket/web_socket_method.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'package:bike_now/models/route.dart' as BikeRoute;
import 'package:bike_now/websocket/web_socket_service.dart';
import 'package:bike_now/models/models.dart' as BikeNow;

import 'package:bike_now/controller/controller.dart';
import 'package:bike_now/websocket/websocket_commands.dart';
import 'package:bike_now/configuration.dart';

class NavigationBloc extends ChangeNotifier implements WebSocketServiceDelegate{
  BikeRoute.Route route;

  SubscriptionController subscriptionController = SubscriptionController();
  RoutingController routingController;
  LocationController locationController = LocationController(true);
  RoutingCoordinator routingCoordinator;
  PredictionController predictionController;

  Timer updateRouteTimer;
  Duration updateInterval = Duration(seconds: 2);


  Stream<BikeRoute.Route> get getRoute => _routeSubject.stream;
  final _routeSubject = BehaviorSubject<BikeRoute.Route>();

  Stream<BikeNow.LatLng> get getCurrentLocation => _currentLocationSubject.stream;
  final _currentLocationSubject = BehaviorSubject<BikeNow.LatLng>();

  void setRoute(BikeRoute.Route route){
    this.route = route;
    _routeSubject.add(route);
  }

  NavigationBloc(){
    routingController = RoutingController(subscriptionController);
    locationController.getCurrentLocation.listen((loc) => _currentLocationSubject.add(loc));
    predictionController = PredictionController(subscriptionController, routingController);
    routingCoordinator = RoutingCoordinator(routingController, predictionController, subscriptionController, locationController);

  }

  void startRouting(){
    WebSocketService.instance.delegate = this;
    routingController.route = route;
    WebSocketService.instance.sendCommand(RouteStart(Configuration.sessionUUID));
    setupRouting();
  }

  void setupRouting(){
    updateRouteTimer = Timer.periodic(updateInterval, updateRouting);
  }

  void updateRouting(Timer timer){
    routingCoordinator.run();
    updateGHNodes(routingController.route);
    updateTrafficLights(routingController.route);
    //sendRideStatistics();

  }

  void updateTrafficLights(BikeNow.Route route){
//    var trafficLights = route.getSGs().where((gs) => gs.shouldUpdateAnnotation);
//    if (trafficLights.length == 0){
//      return;
//    }
//    if (trafficLights.firstWhere((sg)=> sg.isCrossed) != null){
//
//    }
  }

  void updateGHNodes(BikeNow.Route route){

  }

  @override
  void websocketDidReceiveMessage(String msg) {
    print(msg);
    WebsocketResponse response = WebsocketResponse.fromJson(jsonDecode(msg));
    if(response.method == WebSocketMethod.pushPredictions){
      var response = WebSocketResponsePredictions.fromJson(jsonDecode(msg));
      predictionController.predictions = response.predictions;
    }
    if(response.method == WebSocketMethod.updateSubscriptions){
      var response = WebSocketResponsePredictions.fromJson(jsonDecode(msg));
      predictionController.predictions = response.predictions;
    }
  }

}