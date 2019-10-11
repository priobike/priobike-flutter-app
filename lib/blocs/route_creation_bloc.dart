import 'package:bike_now_flutter/controller/location_controller.dart';
import 'package:bike_now_flutter/database/database_rides.dart';
import 'package:bike_now_flutter/models/ride.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_now_flutter/database/database_helper.dart';
import 'package:bike_now_flutter/websocket/web_socket_service.dart';
import 'package:bike_now_flutter/geo_coding/address_to_location_response.dart';
import 'package:bike_now_flutter/server_response/websocket_response.dart';
import 'dart:convert';
import 'package:bike_now_flutter/websocket/web_socket_method.dart';
import 'package:bike_now_flutter/websocket/websocket_commands.dart';
import 'package:bike_now_flutter/configuration.dart';

import 'package:bike_now_flutter/models/route.dart' as BikeRoute;

enum CreationState {
  waitingForLocation,
  waitingForWebsocketResponse,
  routeCreation,
  navigateToInformationPage,
  navigateToNavigationPage
}

class RouteCreationBloc extends ChangeNotifier
    implements WebSocketServiceDelegate {
  Place start;
  Place end;
  CreationState state;

  BikeRoute.Route route;
  LocationController locationController;

  DatabaseRides databaseRides = DatabaseRides();

  Stream<BikeRoute.Route> get getRoute => _routeSubject.stream;
  final _routeSubject = BehaviorSubject<BikeRoute.Route>();

  Stream<String> get getStartLabel => _startLabelSubject.stream;
  final _startLabelSubject = BehaviorSubject<String>();

  Stream<String> get getEndLabel => _endLabelSubject.stream;
  final _endLabelSubject = BehaviorSubject<String>();

  Stream<CreationState> get getState => _stateSubject.stream;
  final _stateSubject = BehaviorSubject<CreationState>();

  Stream<List<Ride>> get rides => _ridesSubject.stream;
  final _ridesSubject = BehaviorSubject<List<Ride>>();
  Sink<int> get deleteRides => _deleteRidesController.sink;
  final _deleteRidesController = StreamController<int>();

  bool simulationPref;

  Stream<bool> get getSimulationPref => _simulationPrefSubject.stream;
  final _simulationPrefSubject = BehaviorSubject<bool>();

  RouteCreationBloc(LocationController locationController) {
    this.locationController = locationController;
    setState(CreationState.waitingForLocation);

    _deleteRidesController.stream.listen(_deleteRides);
    WebSocketService.instance.delegate = this;
    fetchRides();

    SharedPreferences.getInstance().then((result) {
      this.simulationPref = result.getBool(SettingKeys.isSimulator) ?? false;
      _simulationPrefSubject.add(simulationPref);
      if (!simulationPref){
        locationController.getCurrentLocation.first.then((location){
          WebSocketService.instance.sendCommand(GetAddressFromLocation(location.lat, location.lng, Configuration.sessionUUID));
          setState(CreationState.routeCreation);
        });


      }else{
        setState(CreationState.routeCreation);
      }
    });
  }

  void setStart(Place place) {
    if(place != null){
      if(simulationPref != null && simulationPref){
        start = place;
        _startLabelSubject.add(place.displayName);
      }
    }
  }

  void setEnd(Place place) {
    if(place != null){
      end = place;
      _endLabelSubject.add(place.displayName);
    }
  }

  void setRoute(BikeRoute.Route route) {
    this.route = route;
    _routeSubject.add(route);
  }

  void toggleLocations() {
    Place swap = start;
    setStart(end);
    setEnd(swap);
  }

  void setState(CreationState state) {
    this.state = state;
    _stateSubject.add(state);

    if (state == CreationState.waitingForWebsocketResponse) {
      if (!simulationPref) {
        WebSocketService.instance.sendCommand(CalcRoute(
            locationController.currentLocation.latitude,
            locationController.currentLocation.longitude,
            double.parse(end.lat),
            double.parse(end.lon),
            Configuration.sessionUUID));
      } else {
        WebSocketService.instance.sendCommand(CalcRoute(
            double.parse(start.lat),
            double.parse(start.lon),
            double.parse(end.lat),
            double.parse(end.lon),
            Configuration.sessionUUID));
      }
    }
  }

  void _deleteRides(int index) async {
    await databaseRides.deleteRide(index);
  }

  void addRides() async {
    if (start != null && end != null) {
      await databaseRides
          .insertRide(Ride(start, end, DateTime.now().millisecondsSinceEpoch));
      fetchRides();
    }
  }

  fetchRides() async {
    _ridesSubject.add(await databaseRides.queryAllRides());
  }

  @override
  void websocketDidReceiveMessage(String msg) {
    WebsocketResponse response = WebsocketResponse.fromJson(jsonDecode(msg));
    if (response.method == WebSocketMethod.getAddressFromLocation){
      var response = AddressFromLocationResponse.fromJson(jsonDecode(msg));
      start = response.place;
      _startLabelSubject.add(response.place.displayName);
    }
    if (response.method == WebSocketMethod.calcRoute) {
      var response = WebSocketResponseRoute.fromJson(jsonDecode(msg));
      setRoute(response.route);
      setState(CreationState.navigateToInformationPage);
    }
  }
}
