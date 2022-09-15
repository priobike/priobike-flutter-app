import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/logging/logger.dart';

class MapControllerService with ChangeNotifier {
  /// MapboxMapController
  MapboxMapController? controller;

  /// MyLocationTrackingMode determines tracking of position
  MyLocationTrackingMode myLocationTrackingMode = MyLocationTrackingMode.None;

  /// The logger for this service.
  final Logger log = Logger("MapControllerService");

  MapControllerService() {
    log.i("MapControllerService started.");
  }

  void setController(MapboxMapController controller) {
    this.controller = controller;
    notifyListeners();
  }

  void unsetController() {
    controller = null;
    notifyListeners();
  }

  void zoomIn() {
    controller?.animateCamera(CameraUpdate.zoomIn());
  }

  void zoomOut() {
    controller?.animateCamera(CameraUpdate.zoomOut());
  }

  void centerNorth() {
    controller?.animateCamera(CameraUpdate.bearingTo(0));
  }

  void setMyLocationTrackingModeTracking() {
    myLocationTrackingMode = MyLocationTrackingMode.Tracking;
    notifyListeners();
  }

  void setMyLocationTrackingModeNone() {
    myLocationTrackingMode = MyLocationTrackingMode.None;
    notifyListeners();
  }
}
