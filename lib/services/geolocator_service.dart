import 'dart:async';

import 'package:geolocator/geolocator.dart';

class GeolocatorService {
  Geolocator geolocator;

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

      print(position == null
          ? '# position: Unknown #'
          : "# position: ${position.latitude}, ${position.longitude} speed: ${position.speed * 3.6} km/h");
    });
  }

  void dispose() {
    locationStreamController.close();
  }
}
