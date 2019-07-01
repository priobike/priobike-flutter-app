import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:bike_now/models/route.dart' as BikeRoute;

class RouteInformationBloc extends ChangeNotifier {

double distance;
double astimatedTime;
DateTime timeOfArrival;

BikeRoute.Route route;

void setRoute(BikeRoute.Route route){
  this.route = route;
  _routeSubject.add(route);
}

Stream<BikeRoute.Route> get getRoute => _routeSubject.stream;
final _routeSubject = BehaviorSubject<BikeRoute.Route>();




// STREAMS
Stream<double> get getDistance => _distanceSubject.stream;
final _distanceSubject = BehaviorSubject<double>();
Sink<double> get setDistance => _setDistanceController.sink;
final _setDistanceController = StreamController<double>();

Stream<double> get getAstimatedTime => _astimatedTimeSubject.stream;
final _astimatedTimeSubject = BehaviorSubject<double>();
Sink<double> get setAstimatedTime => _setAstimatedTimeController.sink;
final _setAstimatedTimeController = StreamController<double>();

Stream<DateTime> get getTimeOfArrival => _timeOfArrivalSubject.stream;
final _timeOfArrivalSubject = BehaviorSubject<DateTime>();
Sink<DateTime> get setTimeOfArrival => _setTimeOfArrivalController.sink;
final _setTimeOfArrivalController = StreamController<DateTime>();




RouteInformationBloc(){
  _setDistanceController.stream.listen(_setDistance);
  _setAstimatedTimeController.stream.listen(_setAstimatedTime);
  _setTimeOfArrivalController.stream.listen(_setTimeOfArrival);




}
void _setDistance(double distance){

}
void _setAstimatedTime(double astimatedTime){}

void _setTimeOfArrival(DateTime timeOfArrival){}



}