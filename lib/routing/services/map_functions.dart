import 'package:flutter/material.dart';
import 'package:priobike/logging/logger.dart';

class MapFunctions with ChangeNotifier {
  /// A bool specifying whether the map should get centered on the user position.
  bool needsCentering = false;

  /// A bool specifying whether the map should get centered north.
  bool needsCenteringNorth = false;

  /// A bool specifying whether the map should fetch coordinates for move waypoint.
  bool needsNewWaypointCoordinates = false;

  /// The logger for this service.
  final Logger log = Logger("MapFunctionsService");

  MapFunctions() {
    log.i("MapFunctionsService started.");
  }

  /// Apply centering.
  void setCameraCenterOnUserLocation() {
    needsCentering = true;
    notifyListeners();
  }

  /// Apply centering of bearing.
  void setCameraCenterNorth() {
    needsCenteringNorth = true;
    notifyListeners();
  }

  /// Get new coordinates of moved waypoint.
  void getCoordinatesForMovedWaypoint() {
    needsNewWaypointCoordinates = true;
    notifyListeners();
  }
}
