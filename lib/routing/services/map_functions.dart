import 'package:flutter/material.dart';
import 'package:priobike/logging/logger.dart';

class MapFunctions with ChangeNotifier {
  /// A bool specifying whether the map should get centered on the user position.
  bool needsCentering = false;

  /// A bool specifying whether the map should get centered on the user position.
  bool isCentered = true;

  /// A bool specifying whether the map should get centered north.
  bool needsCenteringNorth = false;

  /// A value that holds the bearing of the camera.
  double cameraBearing = 0;

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

  /// Set the camera bearing.
  void setCameraBearing(double bearing) {
    cameraBearing = bearing;
    notifyListeners();
  }

  /// Set centered to false.
  void setCameraNotCentered() {
    isCentered = false;
    notifyListeners();
  }

  /// Set centered to true.
  void setCameraCentered() {
    isCentered = true;
    notifyListeners();
  }
}
