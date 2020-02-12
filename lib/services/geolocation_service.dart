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
    log.w('Geolocator initialized');
  }

  startGeolocation() {
    log.w('Geolocator started doing its thing');
    geolocator
        .getPositionStream(LocationOptions(
            accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 1))
        .listen((Position position) {
      positionStreamController.add(position);

      log.i(position == null
          ? 'Position: Unknown'
          : "Position: ${position.latitude}, ${position.longitude} Speed: ${position.speed * 3.6} km/h");
    });
  }

  void dispose() {
    log.w('Geolocator disposed');
    positionStreamController.close();
  }
}
