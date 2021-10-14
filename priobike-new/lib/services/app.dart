import 'dart:async';

// import 'package:priobike/config/logger.dart';
// import 'package:priobike/models/api/api_route.dart';
// import 'package:priobike/models/recommendation.dart';
// import 'package:priobike/session/session_remote/session_remote.dart';
// import 'package:priobike/session/session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/route_response.dart';
import 'package:priobike/session/remote_session.dart';
import 'package:priobike/utils/logger.dart';
import 'package:uuid/uuid.dart';

class AppService with ChangeNotifier {
  Logger log = Logger("AppService");

  String clientId = const Uuid().v4();

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

  updateDestination(
    double toLat,
    double toLon,
  ) {
    currentRoute = null;
    loadingRoute = true;

    if (lastPosition?.latitude != null && lastPosition?.longitude != null) {
      session.updateRoute(
          lastPosition!.latitude, lastPosition!.longitude, toLat, toLon);
    }

    notifyListeners();
  }

  updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    currentRoute = null;
    loadingRoute = true;

    session.updateRoute(fromLat, fromLon, toLat, toLon);

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
