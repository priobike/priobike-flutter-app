import 'package:bike_now_flutter/blocs/route_creation_bloc.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:bike_now_flutter/models/route.dart' as BikeRoute;

class RouteInformationBloc extends ChangeNotifier {
  double distance;
  double astimatedTime;
  DateTime timeOfArrival;

  BikeRoute.Route route;
  String startLabel;
  String endLabel;

  void setRoute(BikeRoute.Route route) {
    this.route = route;
    _routeSubject.add(route);
  }

  setStartLabel(String label) {
    if (label.length <= 30) {
      startLabel = label;
    } else {
      startLabel = label.substring(0, 29);
    }
    _startLabelSubject.add(startLabel);
  }

  setEndLabel(String label) {
    if (label.length <= 30) {
      endLabel = label;
    } else {
      endLabel = label.substring(0, 29);
    }
    _endLabelSubject.add(endLabel);
  }

  Stream<BikeRoute.Route> get getRoute => _routeSubject.stream;
  final _routeSubject = BehaviorSubject<BikeRoute.Route>();

  Stream<String> get getStartLabel => _startLabelSubject.stream;
  final _startLabelSubject = BehaviorSubject<String>();

  Stream<String> get getEndLabel => _endLabelSubject.stream;
  final _endLabelSubject = BehaviorSubject<String>();

// STREAMS
  Stream<double> get getDistance => _distanceSubject.stream;
  final _distanceSubject = BehaviorSubject<double>();

  Stream<double> get getAstimatedTime => _astimatedTimeSubject.stream;
  final _astimatedTimeSubject = BehaviorSubject<double>();

  Stream<DateTime> get getTimeOfArrival => _timeOfArrivalSubject.stream;
  final _timeOfArrivalSubject = BehaviorSubject<DateTime>();

  RouteInformationBloc() {}
}
