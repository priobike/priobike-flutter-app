import 'package:flutter/material.dart';
import 'package:priobike/logging/logger.dart';

class MapValues with ChangeNotifier {
  /// A value that holds the state of if the camera is centered.
  bool isCentered = true;

  /// A value that holds the bearing of the camera.
  double cameraBearing = 0;

  /// The logger for this service.
  final Logger log = Logger("MapValuesService");

  MapValues() {
    log.i("MapValuesService started.");
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
