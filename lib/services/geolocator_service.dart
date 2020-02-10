import 'dart:async';

import 'package:bikenow/config/logger.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorService {
  Geolocator geolocator;

  Logger log = new Logger('GeolocatorService');

  StreamController<Position> locationStreamController =
      new StreamController<Position>.broadcast();

  GeolocatorService() {
    geolocator = Geolocator();
  }

  startGeolocation() {
    geolocator
        .getPositionStream(LocationOptions(
            accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 5))
        .listen((Position position) {
      locationStreamController.add(position);

      log.i(position == null
          ? 'Position: Unknown'
          : "Position: ${position.latitude}, ${position.longitude} Speed: ${position.speed * 3.6} km/h");
    });
  }

  void dispose() {
    locationStreamController.close();
  }
}
