import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_now/database/database_helper.dart';
import 'package:bike_now/websocket/web_socket_service.dart';

class RouteCreationBloc extends ChangeNotifier implements WebSocketServiceDelegate{



  Stream<List<Ride>> get rides => _ridesSubject.stream;
  final _ridesSubject = BehaviorSubject<List<Ride>>();
  Sink<int> get deleteRides => _deleteRidesController.sink;
  final _deleteRidesController = StreamController<int>();
  Sink<Ride> get addRides => _addRidesController.sink;
  final _addRidesController = StreamController<Ride>();

  Stream<String> get serverResponse => _serverResponseSubject.stream;
  final _serverResponseSubject = BehaviorSubject<String>();

  RouteCreationBloc(){
    _deleteRidesController.stream.listen(_deleteRides);
    _addRidesController.stream.listen(_addRides);
    WebSocketService.instance.delegate = this;
    fetchRides();
  }

  void _deleteRides(int index) async{
    await DatabaseHelper.instance.delete(index);
  }
  void _addRides(Ride ride) async{
    await DatabaseHelper.instance.insert(ride);
    fetchRides();
  }

  fetchRides() async{
    _ridesSubject.add(await DatabaseHelper.instance.queryAllRides());
  }

  @override
  void websocketDidReceiveMessage(String msg) {
    _serverResponseSubject.add(msg);
  }


}