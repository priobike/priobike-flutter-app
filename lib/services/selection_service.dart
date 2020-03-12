import 'dart:async';

import 'package:bikenow/alogrithms/geo_algorithms.dart';
import 'package:bikenow/models/api/api_sg.dart';
import 'package:bikenow/config/logger.dart';
import 'package:bikenow/models/api/api_route.dart';

import 'package:geolocator/geolocator.dart';

class SelectionService {
  Logger log = new Logger('SelectionService');

  List<ApiSg> sgList = [];
  ApiSg nextSg;
  double lastDistanceToNextSg;
  bool touchedSg;

  StreamController<ApiSg> nextSgStreamController =
      new StreamController<ApiSg>.broadcast();

  SelectionService({
    Stream<ApiRoute> routeStream,
    Stream<Position> positionStream,
  }) {
    routeStream.listen((newRoute) {
      sgList.clear();
      nextSg = null;
      lastDistanceToNextSg = double.infinity;

      newRoute.sg.forEach((sg) {
        print(sg);
        sgList.add(sg);
      });      
      
    });

    positionStream.listen((newPosition) {
      // Falls keine nächste SG, setze näheste SG
      if (nextSg == null) {
        ApiSg nearestSg = sgList[0];
        double nearestDistance = double.infinity;
        sgList.forEach((sg) {
          double distance = GeoAlgorithm.distanceBetween(
            newPosition.latitude,
            newPosition.longitude,
            sg.lat,
            sg.lon,
          );

          if (distance < nearestDistance) {
            nearestSg = sg;
            nearestDistance = distance;
          }
        });

        print('NÄCHSTE SG IST ${nearestSg.mqtt}');
        nextSg = nearestSg;
        lastDistanceToNextSg = nearestDistance;

        touchedSg = true;

        // entferne alle SGs aus Liste bis zu dieser
        sgList.removeRange(0, nextSg.index + 1);

        print('ÜBRIGE SG:');
        sgList.forEach((sg) {
          print(sg.mqtt);
        });

        nextSgStreamController.add(nextSg);
      }

      double distanceToNextSg = GeoAlgorithm.distanceBetween(
        newPosition.latitude,
        newPosition.longitude,
        nextSg.lat,
        nextSg.lon,
      );

      // Touch Radius bei 20m
      if (distanceToNextSg < 20) {
        touchedSg = true;
      }

      if ((distanceToNextSg - lastDistanceToNextSg >= 1) && touchedSg == true) {
        nextSg = sgList.removeAt(0);
        nextSgStreamController.add(nextSg);
        touchedSg = false;
      }

      lastDistanceToNextSg = distanceToNextSg;
    });
  }

  dispose() {
    nextSgStreamController.close();
  }
}
