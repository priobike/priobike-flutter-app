import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:priobike/models/point.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/route_response.dart';
import 'package:priobike/services/api.dart';
import 'package:priobike/session/remote_session.dart';
import 'package:priobike/utils/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

import 'navigation.dart';

class AppService with ChangeNotifier {
  Logger log = Logger("AppService");

  String clientId = "alpha-app-" + const Uuid().v4();

  bool loadingRoute = true;
  bool loadingRecommendation = true;
  bool isGeolocating = false;
  bool isStaging = true;

  late StreamSubscription<Position> positionStream;

  Position? lastPosition;
  RouteResponse? currentRoute;
  Recommendation? currentRecommendation;
  late RemoteSession session;

  AppService() {
    log.i('AppService started');
    log.i('Your clientId is $clientId');
    initSession();
  }

  initSession() {
    log.i('init session...');
    session = RemoteSession(
      host: isStaging ? Api.hostStaging : Api.hostProduction,
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

  showLocationAccessDeniedDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: const Text("Einstellungen öffnen"),
      onPressed: () {
        Geolocator.openLocationSettings();
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Zugriff auf Standort verweigert."),
      content: const Text(
          "Bitte erlauben Sie den Zugriff auf Ihren Standort in den Einstellungen."),
      actions: [
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<bool> requestGeolocatorPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled - don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }

  startGeolocation() async {
    if (isGeolocating) {
      log.w('Attempted to start geolocation while already geolocating');
      return;
    }
    isGeolocating = true;

    final hasPermission = await requestGeolocatorPermission();
    if (!hasPermission) {
      final context = NavigationService.key.currentContext;
      if (context == null) {
        log.e('Cannot show alert dialog, no context');
        return;
      }
      // Pop to the root of the navigator stack before directing to the settings.
      Navigator.of(context).popUntil((route) => route.isFirst);
      showLocationAccessDeniedDialog(context);
      log.w('Permission to Geolocator denied');
      isGeolocating = false;
      return;
    }

    loadingRecommendation = true;
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (isGeolocating == true) {
        session.updatePosition(
          position.latitude,
          position.longitude,
          position.speed,
        );
        lastPosition = position;
        notifyListeners();
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

  setIsStaging(isStaging) {
    log.i("set isStaging to $isStaging");
    session.clearSessionId();
    this.isStaging = isStaging;
    initSession();
    notifyListeners();
  }
}
