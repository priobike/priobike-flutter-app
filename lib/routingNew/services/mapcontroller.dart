import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/routingNew/views/widgets/calculateRoutingBarHeight.dart';

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

  /// Function which unsets the controller by type.
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

  /// Function which zooms in the controller by type.
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

  /// Function which zooms out the controller by type.
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

  /// Function which clears the bearing of the controller by type.
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

  /// Function which the location tracking mode of the controller by type.
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

  /// Function which the location tracking mode to none of the controller by type.
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

  /// Function which the camera position of the controller by type.
  LatLng? getCameraPosition(ControllerType controllerType) {
    switch (controllerType) {
      case ControllerType.main:
        return controller?.cameraPosition?.target;
      case ControllerType.selectOnMap:
        return controllerSelectOnMap?.cameraPosition?.target;
    }
  }

  /// Fit the camera to the current route.
  fitCameraToRouteBounds(Routing routing, MediaQueryData frame) async {
    if (controller == null) return;
    // FIXME with changenotifier at some point this condition needs to be adapted.
    // if (routing.selectedRoute == null || mapboxMapController?.isCameraMoving != false) return;
    if (routing.selectedRoute == null) return;
    // The delay is necessary, otherwise sometimes the camera won't move.
    await Future.delayed(const Duration(milliseconds: 750));
    await controller?.animateCamera(
      // Bottom and top to not hide route below UI components.
      CameraUpdate.newLatLngBounds(routing.selectedRoute!.paddedBounds,
          bottom: 0.175 * frame.size.height,
          top: calculateRoutingBarHeight(frame, routing.selectedWaypoints?.length ?? 0, true, routing.minimized)),
      duration: const Duration(milliseconds: 1000),
    );
  }

  /// Fit the camera to the current route in top part.
  fitCameraToRouteBoundsTop(Routing routing, MediaQueryData frame) async {
    if (controller == null) return;
    // FIXME with changenotifier at some point this condition needs to be adapted.
    // if (routing.selectedRoute == null || mapboxMapController?.isCameraMoving != false) return;
    if (routing.selectedRoute == null) return;
    // The delay is necessary, otherwise sometimes the camera won't move.
    await Future.delayed(const Duration(milliseconds: 750));
    await controller?.animateCamera(
      CameraUpdate.newLatLngBounds(routing.selectedRoute!.paddedBounds, bottom: 0.66 * frame.size.height),
      duration: const Duration(milliseconds: 1000),
    );
  }
}
