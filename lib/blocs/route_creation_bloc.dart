import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_now/database/database_helper.dart';
import 'package:bike_now/websocket/web_socket_service.dart';
import 'package:bike_now/geo_coding/address_to_location_response.dart';
import 'package:bike_now/server_response/websocket_response.dart';
import 'dart:convert';
import 'package:bike_now/websocket/web_socket_method.dart';
import 'package:bike_now/websocket/websocket_commands.dart';
import 'package:bike_now/configuration.dart';

enum CreationState {
  waitingForResponse,
  routeCreation,
  navigateToInformationPage
}


class RouteCreationBloc extends ChangeNotifier implements WebSocketServiceDelegate{
  Place start;
  Place end;
  CreationState state = CreationState.routeCreation;

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


  Stream<String> get serverResponse => _serverResponseSubject.stream;
  final _serverResponseSubject = BehaviorSubject<String>();

  RouteCreationBloc(){
    _deleteRidesController.stream.listen(_deleteRides);
    WebSocketService.instance.delegate = this;
    fetchRides();
  }

  void setStart(Place place){
    start= place;
    _startLabelSubject.add(place.displayName);
  }
  void setEnd(Place place){
    end = place;
    _endLabelSubject.add(place.displayName);
  }

  void toggleLocations(){
    Place swap = start;
    setStart(end);
    setEnd(swap);
  }

  void setState(CreationState state){
    this.state = state;
    _stateSubject.add(state);
    if(state == CreationState.waitingForResponse){
      WebSocketService.instance.sendCommand(CalcRoute(double.parse(start.lat),double.parse(start.lon) , double.parse(end.lat), double.parse(end.lon), Configuration.sessionUUID));
    }
  }

  void _deleteRides(int index) async{
    await DatabaseHelper.instance.delete(index);
  }
  void addRides() async{
    if (start != null && end != null){
      await DatabaseHelper.instance.insert(Ride(start, end, DateTime.now().millisecondsSinceEpoch));
      fetchRides();
    }

  }

  fetchRides() async{
    _ridesSubject.add(await DatabaseHelper.instance.queryAllRides());
  }

  @override
  void websocketDidReceiveMessage(String msg) {
    _serverResponseSubject.add(msg);
    WebsocketResponse response = WebsocketResponse.fromJson(jsonDecode(msg));
    if(response.method == WebSocketMethod.calcRoute){
      setState(CreationState.navigateToInformationPage);
    }

  }




}