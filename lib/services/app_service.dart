import 'dart:async';

import 'package:priobike/config/logger.dart';
import 'package:priobike/models/api/api_route.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/session/session_remote/session_remote.dart';
import 'package:priobike/session/session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

class AppService with ChangeNotifier {
  Logger log = Logger("AppService");

  String clientId = Uuid().v4();

  bool loadingRoute = true;
  bool loadingRecommendation = true;
  bool isGeolocating = false;

  StreamSubscription<Position> positionStream;

  Position lastPosition;
  ApiRoute route;
  Recommendation recommendation;
  Session session;

  AppService() {
    log.i('Your ID is $clientId');

    session = new RemoteSession(clientId: clientId);

    session.routeStreamController.stream.listen((route) {
      log.i('<- Route');
      loadingRoute = false;
      this.route = route;
      notifyListeners();
    });

    session.recommendationStreamController.stream.listen((recommendation) {
      log.i('<- Recommendation');
      loadingRecommendation = false;
      this.recommendation = recommendation;
      notifyListeners();
    });
  }

  updateDestination(
    double toLat,
    double toLon,
  ) {
    log.i('-> Route Request');
    route = null;
    loadingRoute = true;

    if (lastPosition != null) {
      session.updateRoute(
          lastPosition.latitude, lastPosition.longitude, toLat, toLon);
    }

    notifyListeners();
  }

  updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    log.i('-> Route Request');
    route = null;
    loadingRoute = true;

    session.updateRoute(fromLat, fromLon, toLat, toLon);

    notifyListeners();
  }

  startGeolocation() async {
    isGeolocating = true;
    loadingRecommendation = true;

    positionStream = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 7,
      intervalDuration: Duration(seconds: 3),
    ).listen((Position position) {
      if (position != null && isGeolocating == true) {
        session.updatePosition(
          position.latitude,
          position.longitude,
          (position.speed * 3.6).round(),
        );
        log.i('-> Position');
        lastPosition = position;
      }
    });
    log.i('GEOLOCATOR STARTED!');
  }

  stopGeolocation() {
    log.i('-> Stop Request');

    session.stopRecommendation();

    isGeolocating = false;
    positionStream.cancel();
    recommendation = null;

    log.i('GEOLOCATOR STOPPED!');
  }

  startNavigation() {
    session.startRecommendation();
  }
}
