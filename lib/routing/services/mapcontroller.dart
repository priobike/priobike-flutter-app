import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/logging/logger.dart';

enum ControllerType {
  main,
  selectOnMap,
}

class MapController with ChangeNotifier {
  /// MapboxMapController for routingView
  MapboxMapController? controller;

  /// MapboxMapController for selectOnMapView
  MapboxMapController? controllerSelectOnMap;

  /// MyLocationTrackingMode determines tracking of position in RoutingView
  MyLocationTrackingMode myLocationTrackingMode = MyLocationTrackingMode.None;

  /// MyLocationTrackingMode determines tracking of position in selectOnMapView
  MyLocationTrackingMode myLocationTrackingModeSelectOnMapView = MyLocationTrackingMode.None;

  /// The logger for this service.
  final Logger log = Logger("MapControllerService");

  MapController() {
    log.i("MapControllerService started.");
  }

  void unsetController(ControllerType controllerType) {
    switch (controllerType) {
      case ControllerType.main:
        controller = null;
        break;
      case ControllerType.selectOnMap:
        controllerSelectOnMap = null;
        break;
    }
  }

  void zoomIn(ControllerType controllerType) {
    switch (controllerType) {
      case ControllerType.main:
        controller?.animateCamera(CameraUpdate.zoomIn());
        break;
      case ControllerType.selectOnMap:
        controllerSelectOnMap?.animateCamera(CameraUpdate.zoomIn());
        break;
    }
  }

  void zoomOut(ControllerType controllerType) {
    switch (controllerType) {
      case ControllerType.main:
        controller?.animateCamera(CameraUpdate.zoomOut());
        break;
      case ControllerType.selectOnMap:
        controllerSelectOnMap?.animateCamera(CameraUpdate.zoomOut());
        break;
    }
  }

  void centerNorth(ControllerType controllerType) {
    switch (controllerType) {
      case ControllerType.main:
        controller?.animateCamera(CameraUpdate.bearingTo(0));
        break;
      case ControllerType.selectOnMap:
        controllerSelectOnMap?.animateCamera(CameraUpdate.bearingTo(0));
        break;
    }
  }

  void setMyLocationTrackingModeTracking(ControllerType controllerType) {
    switch (controllerType) {
      case ControllerType.main:
        myLocationTrackingMode = MyLocationTrackingMode.Tracking;
        break;
      case ControllerType.selectOnMap:
        myLocationTrackingModeSelectOnMapView = MyLocationTrackingMode.Tracking;
        break;
    }
    notifyListeners();
  }

  void setMyLocationTrackingModeNone(ControllerType controllerType) {
    switch (controllerType) {
      case ControllerType.main:
        myLocationTrackingMode = MyLocationTrackingMode.None;
        break;
      case ControllerType.selectOnMap:
        myLocationTrackingModeSelectOnMapView = MyLocationTrackingMode.None;
        break;
    }
    notifyListeners();
  }

  LatLng? getCameraPosition(ControllerType controllerType) {
    switch (controllerType) {
      case ControllerType.main:
        return controller?.cameraPosition?.target;
      case ControllerType.selectOnMap:
        return controllerSelectOnMap?.cameraPosition?.target;
    }
  }
}
