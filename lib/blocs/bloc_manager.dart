import 'package:bike_now_flutter/blocs/route_information_bloc.dart';
import 'package:bike_now_flutter/blocs/route_creation_bloc.dart';
import 'package:bike_now_flutter/blocs/navigation_bloc.dart';
import 'package:bike_now_flutter/blocs/test_bloc.dart';
import 'package:bike_now_flutter/controller/location_controller.dart';

import 'package:flutter/material.dart';

class ManagerBloc extends ChangeNotifier {
  RouteCreationBloc _routeCreationBloc;
  RouteInformationBloc _routeInformationBloc;
  NavigationBloc _navigationBloc;
  TestBloc _testBloc;
  LocationController _locationController = LocationController();

  ManagerBloc() {
    _routeCreationBloc = RouteCreationBloc(_locationController);
    _routeInformationBloc = RouteInformationBloc();
    _navigationBloc = NavigationBloc(_locationController);
    _testBloc = TestBloc();

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
  TestBloc get testBloc => _testBloc;
  LocationController get locationController => _locationController;
}
