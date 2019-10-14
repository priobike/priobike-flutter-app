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
import 'package:bike_now_flutter/configuration.dart';




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

  Stream<BikeNow.LatLng> get getCurrentLocation =>
      _currentLocationSubject.stream;
  final _currentLocationSubject = BehaviorSubject<BikeNow.LatLng>();

  void setRoute(BikeRoute.Route route) {
    this.route = route;
    _routeSubject.add(route);
  }

  //FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project


  NavigationBloc(LocationController locationController) {
    this.locationController = locationController;

    routingController = RoutingController(subscriptionController);
    locationController.getCurrentLocation
        .listen((loc) => _currentLocationSubject.add(loc));
    predictionController =
        PredictionController(subscriptionController, routingController);
    routingCoordinator = RoutingCoordinator(routingController,
        predictionController, subscriptionController, locationController);

//    var initializationSettingsAndroid =
//    new AndroidInitializationSettings('app_icon');
//    var initializationSettingsIOS = new IOSInitializationSettings(
//        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
//    var initializationSettings = new InitializationSettings(
//        initializationSettingsAndroid, initializationSettingsIOS);
//    flutterLocalNotificationsPlugin.initialize(initializationSettings,
//        onSelectNotification: onSelectNotification);
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

//  void pushLocalNotification(String title, String msg){
//    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
//        'your channel id', 'your channel name', 'your channel description',
//        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
//    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
//    var platformChannelSpecifics = NotificationDetails(
//        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
//    flutterLocalNotificationsPlugin.show(
//        0, title, msg, platformChannelSpecifics,
//        payload: 'item x');
//  }

//  void initBackgroundLocationTracking(){
//    // Fired whenever a location is recorded
//    bg.BackgroundGeolocation.onLocation((bg.Location location) {
//      pushLocalNotification("Neue Location getracket", "$location");
//    });
//
//    // Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
//    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
//      pushLocalNotification("Neuer MotionState", "$location");
//
//    });
//
//    // Fired whenever the state of location-services changes.  Always fired at boot
//    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
//      pushLocalNotification("Neuer ProviderChange", "$event");
//    });
//
//    ////
//    // 2.  Configure the plugin
//    //
//    bg.BackgroundGeolocation.ready(bg.Config(
//        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
//        distanceFilter: 10.0,
//        stopOnTerminate: false,
//        startOnBoot: true,
//        debug: true,
//        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
//        reset: true
//    )).then((bg.State state) {
//      if (!state.enabled) {
//        ////
//        // 3.  Start the plugin.
//        //
//        bg.BackgroundGeolocation.start();
//      }
//    });
//  }

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
