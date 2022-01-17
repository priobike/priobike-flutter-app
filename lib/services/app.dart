import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:priobike/models/point.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/route_response.dart';
import 'package:priobike/session/remote_session.dart';
import 'package:priobike/utils/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class AppService with ChangeNotifier {
  Logger log = Logger("AppService");

  String clientId = "alpha-app-" + const Uuid().v4();

  bool loadingRoute = true;
  bool loadingRecommendation = true;
  bool isGeolocating = false;

  late StreamSubscription<Position> positionStream;

  Position? lastPosition;
  RouteResponse? currentRoute;
  Recommendation? currentRecommendation;
  late RemoteSession session;

  AppService() {
    log.i('AppService started');
    log.i('Your clientId is $clientId');

    session = RemoteSession(
      clientId: clientId,
      onDone: () {
        notifyListeners();
      },
    );

    session.routeStreamController.stream.listen((route) {
      loadingRoute = false;
      currentRoute = route;
      notifyListeners();
    });

    session.recommendationStreamController.stream.listen((recommendation) {
      loadingRecommendation = false;
      currentRecommendation = recommendation;
      notifyListeners();
    });
  }

  updateRoute(
    List<Point> waypoints,
  ) {
    currentRoute = null;
    loadingRoute = true;

    session.updateRoute(waypoints);

    notifyListeners();
  }

  startGeolocation() async {
    isGeolocating = true;
    loadingRecommendation = true;
    positionStream = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
      intervalDuration: const Duration(seconds: 1),
    ).listen((Position position) {
      if (isGeolocating == true) {
        session.updatePosition(
          position.latitude,
          position.longitude,
          position.speed,
        );
        lastPosition = position;
      }
    });
    log.i('Geolocator started!');
  }

  stopGeolocation() {
    isGeolocating = false;
    positionStream.cancel();
    log.i('Geolocator stopped!');
  }

  startNavigation() {
    session.startRecommendation();
  }

  stopNavigation() {
    session.stopRecommendation();
    currentRecommendation = null;
  }
}
