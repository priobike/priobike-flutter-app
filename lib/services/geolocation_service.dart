import 'dart:async';

import 'package:bikenow/config/logger.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationService {
  Geolocator geolocator;

  Logger log = new Logger('GeolocationService');

  Timer timer;

  StreamController<Position> positionStreamController =
      new StreamController<Position>.broadcast();

  GeolocationService() {
    geolocator = Geolocator();
    log.w('Geolocator initialized');
  }

  startGeolocation() {
    log.w('Geolocator started doing its thing');

    if (timer == null) {
      timer = Timer.periodic(new Duration(seconds: 1), (t) async {
        Position position = await geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );

        positionStreamController.add(position);

        log.i(position == null
            ? 'Position: Unknown'
            : "Position: ${position.latitude}, ${position.longitude} Speed: ${position.speed * 3.6} km/h");
      });
    } else {
      log.w('Geolocation was started twice!!');
    }
  }

  stopGeolocation() {
    timer.cancel();
    timer = null; 
    log.w('Geolocator stopped!');
  }

  void dispose() {
    log.w('Geolocator disposed');
    positionStreamController.close();
    timer.cancel();
    timer = null;
  }
}
