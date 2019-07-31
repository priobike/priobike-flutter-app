import 'package:bike_now/blocs/route_information_bloc.dart';
import 'package:bike_now/blocs/route_creation_bloc.dart';
import 'package:bike_now/blocs/navigation_bloc.dart';
import 'package:bike_now/controller/location_controller.dart';

import 'package:flutter/material.dart';

class ManagerBloc extends ChangeNotifier {
  RouteCreationBloc _routeCreationBloc;
  RouteInformationBloc _routeInformationBloc;
  NavigationBloc _navigationBloc;
  LocationController _locationController = LocationController();

  ManagerBloc() {
    _routeCreationBloc = RouteCreationBloc(_locationController);
    _routeInformationBloc = RouteInformationBloc();
    _navigationBloc = NavigationBloc(_locationController);

    // Pipe Route to blocs
    _routeCreationBloc.getRoute.listen((route) {
      _routeInformationBloc.setRoute(route);
    });
    _routeCreationBloc.getStartLabel.listen((label) {
      _routeInformationBloc.setStartLabel(label);
    });
    _routeCreationBloc.getEndLabel.listen((label) {
      _routeInformationBloc.setEndLabel(label);
    });
    routeCreationBlog.getRoute
        .listen((route) => _navigationBloc.setRoute(route));
  }

  RouteCreationBloc get routeCreationBlog => _routeCreationBloc;
  RouteInformationBloc get routeInformationBloc => _routeInformationBloc;
  NavigationBloc get navigationBloc => _navigationBloc;
  LocationController get locationController => _locationController;
}
