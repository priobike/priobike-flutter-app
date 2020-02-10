import 'dart:async';

import 'package:bikenow/config/logger.dart';
import 'package:bikenow/models/api/api_route.dart';
import 'package:bikenow/models/api/api_sg.dart';

import 'package:geolocator/geolocator.dart';

class SelectionService {
  Logger log = new Logger('SelectionService');
  ApiRoute _route;

  StreamController<ApiSg> nextSgStreamController =
      new StreamController<ApiSg>.broadcast();

  SelectionService(
      {Stream<ApiRoute> routeStream, Stream<Position> positionStream}) {
    routeStream.listen((newRoute) {
      _route = newRoute;
    });

    positionStream.listen((newPosition) {
      if (_route != null) {
        //TODO: implement correct selection algo
        nextSgStreamController.add(_route.sg[0]);
        log.i('Selected next Sg on route');
      } else {
        log.w('Tried to select Sg on route, but there was no route');
      }
    });
  }

  dispose() {
    nextSgStreamController.close();
  }
}
