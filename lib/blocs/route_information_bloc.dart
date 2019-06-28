import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class RouteInformationBloc extends ChangeNotifier {

double distance;
double astimatedTime;
DateTime timeOfArrival;






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