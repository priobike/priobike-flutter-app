import 'dart:async';

import 'package:bikenow/config/logger.dart';
import 'package:bikenow/models/api/api_route.dart';
import 'package:bikenow/models/api/api_sg.dart';

import 'package:geolocator/geolocator.dart';

import 'package:vector_math/vector_math.dart';

class SelectionService {
  Logger log = new Logger('SelectionService');
  ApiRoute _route;

  Position lastPosition;

  StreamController<ApiSg> nextSgStreamController =
      new StreamController<ApiSg>.broadcast();

  SelectionService({
    Stream<ApiRoute> routeStream,
    Stream<Position> positionStream,
  }) {
    routeStream.listen((newRoute) {
      _route = newRoute;
    });

    positionStream.listen((newPosition) {
      if (_route != null &&
          lastPosition != null &&
          (lastPosition.toString() != newPosition.toString())) {
        Stopwatch stopwatch = new Stopwatch()..start();
        for (var i = 0; i < _route.sg.length; i++) {
          ApiSg sg = _route.sg[i];

          Vector2 newPositionVector =
              new Vector2(newPosition.latitude, newPosition.longitude);

          Vector2 lastPositionVector =
              new Vector2(lastPosition.latitude, lastPosition.longitude);

          Vector2 movementVector = newPositionVector - lastPositionVector;

          Vector2 sgPositionVector =
              newPositionVector - new Vector2(sg.lat, sg.lon);

          Vector2 directionVector = newPositionVector + movementVector;

          bool isInFront = directionVector.dot(sgPositionVector) < 0;

          if (isInFront) {
            nextSgStreamController.add(sg);
            break;
          }
        }
        log.i(
            'New Position, selected next sg in ${stopwatch.elapsed.inMicroseconds / 1000}ms');
      } else {
        if (_route == null) {
          log.w('No route available');
        }

        if (lastPosition == null) {
          log.w('Last position not available');
        }

        if (lastPosition.toString() == newPosition.toString()) {
          log.w('Last Position was the same');
        }
      }
      lastPosition = newPosition;
    });
  }

  dispose() {
    nextSgStreamController.close();
  }
}
