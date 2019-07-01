import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'package:bike_now/models/route.dart' as BikeRoute;

class NavigationBloc extends ChangeNotifier {

  BikeRoute.Route route;

  Stream<BikeRoute.Route> get getRoute => _routeSubject.stream;
  final _routeSubject = BehaviorSubject<BikeRoute.Route>();

  void setRoute(BikeRoute.Route route){
    this.route = route;
    _routeSubject.add(route);
  }

}