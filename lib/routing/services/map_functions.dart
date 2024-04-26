import 'package:flutter/material.dart';
import 'package:priobike/logging/logger.dart';

class MapFunctions with ChangeNotifier {
  /// A bool specifying whether the map should get centered on the user position.
  bool needsCentering = false;

  /// A bool specifying whether the map should get centered north.
  bool needsCenteringNorth = false;

  /// A bool specifying whether the map should fetch coordinates for move waypoint.
  bool needsNewWaypointCoordinates = false;

  /// The index of the tappedWaypoint.
  int? tappedWaypointIdx;

  /// The initial x screen coordinate of the new waypoint to add.
  double? addWaypointAtX;

  /// The initial y screen coordinate of the new waypoint to add.
  double? addWaypointAtY;

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

  /// Sets the tapped waypoint idx.
  void setTappedWaypointIdx(int idx) {
    tappedWaypointIdx = idx;
    notifyListeners();
  }

  /// Sets the tapped waypoint idx.
  void unsetTappedWaypointIdx() {
    tappedWaypointIdx = null;
    notifyListeners();
  }

  /// Sets the tapped waypoint idx.
  void setAddNewWaypointAt(double x, double y) {
    notifyListeners();
    addWaypointAtX = x;
    addWaypointAtY = y;
  }

  /// Reset all map functions attributes.
  void reset() {
    needsCentering = false;
    needsCenteringNorth = false;
    needsNewWaypointCoordinates = false;
    tappedWaypointIdx = null;
    addWaypointAtX = null;
    addWaypointAtY = null;
    notifyListeners();
  }
}
