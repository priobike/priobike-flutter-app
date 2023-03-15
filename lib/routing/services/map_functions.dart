import 'package:flutter/material.dart';
import 'package:priobike/logging/logger.dart';

class MapFunctions with ChangeNotifier {
  /// A bool specifying whether the camera should be/is centered on the user location.
  bool centerCameraOnUserLocation = false;

  /// The logger for this service.
  final Logger log = Logger("MapFunctionsService");

  MapFunctions() {
    log.i("MapFunctionsService started.");
  }

  /// Change value of centerCameraOnUserLocation (only notify listeners on a change from false to true
  /// (which means that a centering needs to be performed)).
  void setCameraCenterOnUserLocation(bool center) {
    final currentState = centerCameraOnUserLocation;
    centerCameraOnUserLocation = center;
    if (!currentState) notifyListeners();
  }
}
