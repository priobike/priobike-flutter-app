import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'package:bike_now/models/route.dart' as BikeRoute;
import 'package:bike_now/websocket/web_socket_service.dart';
import 'package:bike_now/models/models.dart' as BikeNow;

import 'package:bike_now/controller/controller.dart';

class NavigationBloc extends ChangeNotifier implements WebSocketServiceDelegate{

  SubscriptionController subscriptionController = SubscriptionController();
  RoutingController routingController;
  BikeRoute.Route route;
  LocationController locationController = LocationController(true);

  Stream<BikeRoute.Route> get getRoute => _routeSubject.stream;
  final _routeSubject = BehaviorSubject<BikeRoute.Route>();

  Stream<BikeNow.LatLng> get getCurrentLocation => _currentLocationSubject.stream;
  final _currentLocationSubject = BehaviorSubject<BikeNow.LatLng>();

  void setRoute(BikeRoute.Route route){
    WebSocketService.instance.delegate = this;
    this.route = route;
    _routeSubject.add(route);
    routingController.setRoute(route);

  }

  NavigationBloc(){
    routingController = RoutingController(subscriptionController);
    locationController.getCurrentLocation.listen((loc) => _currentLocationSubject.add(loc));
  }

  @override
  void websocketDidReceiveMessage(String msg) {
    print(msg);
  }

}