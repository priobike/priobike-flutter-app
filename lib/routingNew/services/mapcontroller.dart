import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/logging/logger.dart';

class MapControllerService with ChangeNotifier {
  /// MapboxMapController
  MapboxMapController? controller;

  /// The logger for this service.
  final Logger log = Logger("MapControllerService");

  MapControllerService() {
    log.i("MapControllerService started.");
  }

  void setController(MapboxMapController controller) {
    this.controller = controller;
  }

  void unsetController() {
    controller = null;
  }

  void zoomIn() {
    print("ZOOMIN");
    controller?.animateCamera(CameraUpdate.zoomIn());
  }

  void zoomOut() {
    controller?.animateCamera(CameraUpdate.zoomOut());
  }
}
