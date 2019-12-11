import 'dart:async';
import 'dart:convert';

import 'package:bike_now_flutter/blocs/helper/routing_dashboard_info.dart';
import 'package:bike_now_flutter/server_response/websocket_response.dart';
import 'package:bike_now_flutter/server_response/websocket_response_predictions.dart';
import 'package:bike_now_flutter/websocket/web_socket_method.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'package:bike_now_flutter/models/route.dart' as BikeRoute;
import 'package:bike_now_flutter/websocket/web_socket_service.dart';
import 'package:bike_now_flutter/models/models.dart' as BikeNow;

import 'package:bike_now_flutter/controller/controller.dart';
import 'package:bike_now_flutter/websocket/websocket_commands.dart';
import 'package:bike_now_flutter/helper/configuration.dart';




class NavigationBloc extends ChangeNotifier
    implements WebSocketServiceDelegate {
  BikeRoute.Route route;

  SubscriptionController subscriptionController = SubscriptionController();
  RoutingController routingController;
  LocationController locationController;
  RoutingCoordinator routingCoordinator;
  PredictionController predictionController;

  Timer updateRouteTimer;
  Duration updateInterval = Duration(seconds: 1);
  RoutingDashboardInfo dashboardInfo;

  Stream<RoutingDashboardInfo> get getDashboardInfo =>
      _dashboardInfoSubject.stream;
  final _dashboardInfoSubject = PublishSubject<RoutingDashboardInfo>();

  Stream<BikeRoute.Route> get getRoute => _routeSubject.stream;
  final _routeSubject = BehaviorSubject<BikeRoute.Route>();

  void setRoute(BikeRoute.Route route) {
    this.route = route;
    _routeSubject.add(route);
  }

  //FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project


  NavigationBloc(LocationController locationController) {
    this.locationController = locationController;

    routingController = RoutingController(subscriptionController);

    predictionController =
        PredictionController(subscriptionController, routingController);
    routingCoordinator = RoutingCoordinator(routingController,
        predictionController, subscriptionController, locationController);

  }

  Future onSelectNotification(String payload) async {

  }
  Future onDidReceiveLocalNotification(int a, String payload, String b, String c) async {


  }

  void startRouting() {
    WebSocketService.instance.delegate = this;
    routingController.route = route;
    WebSocketService.instance
        .sendCommand(RouteStart(Configuration.sessionUUID));
    setupRouting();
    //initBackgroundLocationTracking();


  }

  void setupRouting() {
    updateRouteTimer = Timer.periodic(updateInterval, updateRouting);
  }

  void didPop(){
    updateRouteTimer.cancel();

  }

  void updateRouting(Timer timer) {
    routingCoordinator.run();
    //sendRideStatistics();
    _routeSubject.add(routingController.route);
    dashboardInfo = RoutingDashboardInfo(
        locationController.currentLocation.speed,
        predictionController.nextValidPhase?.getRecommendedSpeed(),
        predictionController.currentPhase?.durationLeft,
        predictionController.currentPhase?.distance,
        predictionController?.nextInstruction,
        predictionController.nextSG);

    _dashboardInfoSubject.add(dashboardInfo);
  }

  @override
  void websocketDidReceiveMessage(String msg) {
    WebsocketResponse response = WebsocketResponse.fromJson(jsonDecode(msg));
    if (response.method == WebSocketMethod.pushPredictions) {
      var response = WebSocketResponsePredictions.fromJson(jsonDecode(msg));
      predictionController.predictions = response.predictions;
    }
    if (response.method == WebSocketMethod.updateSubscriptions) {
      var response = WebSocketResponsePredictions.fromJson(jsonDecode(msg));
      predictionController.predictions = response.predictions;
    }
  }
}
