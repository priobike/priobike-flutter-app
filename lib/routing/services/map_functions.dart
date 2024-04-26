import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/logging/logger.dart';

class MapFunctions with ChangeNotifier {
  /// A bool specifying whether the map should get centered on the user position.
  bool needsCentering = false;

  /// A bool specifying whether the map should get centered north.
  bool needsCenteringNorth = false;

  /// A bool specifying whether the map should fetch coordinates for move waypoint.
  bool needsNewWaypointCoordinates = false;

  /// A bool specifying whether the map should be centered to the waypoint icon.
  bool needsWaypointCentering = false;

  /// A bool specifying whether the waypoint layer needs highlight.
  bool needsRemoveHighlighting = false;

  /// The index of the tappedWaypoint.
  int? tappedWaypointIdx;

  /// The initial screen coordinate of the new waypoint to add.
  ScreenCoordinate? addWaypointAtScreenCoordinate;

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
  void getCoordinatesForWaypoint() {
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
    needsRemoveHighlighting = true;
    notifyListeners();
  }

  /// Sets the add new waypoint at screen coordinates.
  void setAddNewWaypointAt(ScreenCoordinate screenCoordinate) {
    addWaypointAtScreenCoordinate = screenCoordinate;
    notifyListeners();
  }

  /// Unsets the add new waypoint at screen coordinates.
  void unsetAddNewWaypointAt() {
    addWaypointAtScreenCoordinate = null;
    needsRemoveHighlighting = true;
    notifyListeners();
  }

  /// Apply centering.
  void setCameraCenterOnWaypointLocation() {
    needsWaypointCentering = true;
    notifyListeners();
  }

  /// Reset all map functions attributes.
  void reset() {
    needsCentering = false;
    needsCenteringNorth = false;
    needsNewWaypointCoordinates = false;
    tappedWaypointIdx = null;
    addWaypointAtScreenCoordinate = null;
    needsWaypointCentering = false;
    needsRemoveHighlighting = false;
    notifyListeners();
  }
}
