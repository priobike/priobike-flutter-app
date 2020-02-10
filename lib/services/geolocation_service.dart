import 'dart:async';

import 'package:bikenow/config/logger.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationService {
  Geolocator geolocator;

  Logger log = new Logger('GeolocationService');

  StreamController<Position> positionStreamController =
      new StreamController<Position>.broadcast();

  GeolocationService() {
    geolocator = Geolocator();
  }

  startGeolocation() {
    geolocator
        .getPositionStream(LocationOptions(
            accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 5))
        .listen((Position position) {
      positionStreamController.add(position);

      log.i(position == null
          ? 'Position: Unknown'
          : "Position: ${position.latitude}, ${position.longitude} Speed: ${position.speed * 3.6} km/h");
    });
  }

  void dispose() {
    positionStreamController.close();
  }
}
