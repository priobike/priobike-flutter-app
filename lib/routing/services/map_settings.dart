import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views_beta/widgets/calculate_routing_bar_height.dart';

enum ControllerType {
  main,
  selectOnMap,
}

class MapSettings with ChangeNotifier {
  /// MapboxMapController for routingView
  MapboxMap? controller;

  /// MapboxMapController for selectOnMapView
  MapboxMap? controllerSelectOnMap;

  /// A bool specifying whether the camera should be/is centered on the user location.
  bool centerCameraOnUserLocation = false;

  /// The logger for this service.
  final Logger log = Logger("MapSettingsService");

  MapSettings() {
    log.i("MapSettingsService started.");
  }

  /// Change value of centerCameraOnUserLocation (only notify listeners on a change from false to true
  /// (which means that a centering needs to be performed)).
  void setCameraCenterOnUserLocation(bool center) {
    final currentState = centerCameraOnUserLocation;
    centerCameraOnUserLocation = center;
    if (!currentState) notifyListeners();
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
  void zoomIn(ControllerType controllerType) async {
    switch (controllerType) {
      case ControllerType.main:
        final currentZoom = (await controller?.getCameraState())!.zoom;
        controller?.flyTo(CameraOptions(zoom: (currentZoom + 1)), MapAnimationOptions(duration: 1000));
        break;
      case ControllerType.selectOnMap:
        final currentZoom = (await controllerSelectOnMap?.getCameraState())!.zoom;
        controllerSelectOnMap?.flyTo(CameraOptions(zoom: (currentZoom + 1)), MapAnimationOptions(duration: 1000));
        break;
    }
  }

  /// Function which zooms out the controller by type.
  void zoomOut(ControllerType controllerType) async {
    switch (controllerType) {
      case ControllerType.main:
        final currentZoom = (await controller?.getCameraState())!.zoom;
        controller?.flyTo(CameraOptions(zoom: (currentZoom - 1)), MapAnimationOptions(duration: 1000));
        break;
      case ControllerType.selectOnMap:
        final currentZoom = (await controllerSelectOnMap?.getCameraState())!.zoom;
        controllerSelectOnMap?.flyTo(CameraOptions(zoom: (currentZoom - 1)), MapAnimationOptions(duration: 1000));
        break;
    }
  }

  /// Function which clears the bearing of the controller by type.
  void centerNorth(ControllerType controllerType) {
    switch (controllerType) {
      case ControllerType.main:
        controller?.flyTo(CameraOptions(bearing: 0), MapAnimationOptions(duration: 1000));
        break;
      case ControllerType.selectOnMap:
        controllerSelectOnMap?.flyTo(CameraOptions(bearing: 0), MapAnimationOptions(duration: 1000));
        break;
    }
  }

  /// Function which the camera position of the controller by type.
  Future<Map<String?, Object?>?> getCameraPosition(ControllerType controllerType) async {
    switch (controllerType) {
      case ControllerType.main:
        return (await controller?.getCameraState())!.center;
      case ControllerType.selectOnMap:
        return (await controllerSelectOnMap?.getCameraState())!.center;
    }
  }

  /// Fit the camera to the current route.
  fitCameraToRouteBounds(Routing routing, MediaQueryData frame) async {
    if (controller == null) return;
    // FIXME with changenotifier at some point this condition needs to be adapted.
    // if (routing.selectedRoute == null || mapboxMapController?.isCameraMoving != false) return;
    if (routing.selectedRoute == null) return;
    // The delay is necessary, otherwise sometimes the camera won't move.
    await Future.delayed(const Duration(milliseconds: 500));
    // final coordinatesSouthwest = routing.selectedRoute!.paddedBounds.southwest["coordinates"] as List;
    // final s = coordinatesSouthwest[1] as double;
    // final w = coordinatesSouthwest[0] as double;
    // final coordinatesNortheast = routing.selectedRoute!.paddedBounds.northeast["coordinates"] as List;
    // final n = coordinatesNortheast[1] as double;
    // final e = coordinatesNortheast[0] as double;
    // final newBounds = CoordinateBounds(
    //     southwest: Point(
    //         coordinates: Position(
    //       s + 0.175 * frame.size.height,
    //       w,
    //     )).toJson(),
    //     northeast: Point(
    //         coordinates: Position(
    //       n + calculateRoutingBarHeight(frame, routing.selectedWaypoints?.length ?? 0, true, routing.minimized),
    //       e,
    //     )).toJson(),
    //     infiniteBounds: false);

    final currentCameraOptions = await controller?.getCameraState();
    if (currentCameraOptions == null) return;
    final cameraOptionsForBounds = await controller?.cameraForCoordinateBounds(
      routing.selectedRoute!.paddedBounds,
      currentCameraOptions.padding,
      currentCameraOptions.bearing,
      currentCameraOptions.pitch,
    );
    await controller?.flyTo(
      cameraOptionsForBounds!,
      MapAnimationOptions(duration: 1000),
    );
  }

  /// Fit the camera to the current route in top part.
  fitCameraToRouteBoundsTop(Routing routing, MediaQueryData frame) async {
    if (controller == null) return;
    // if (routing.selectedRoute == null || mapboxMapController?.isCameraMoving != false) return;
    if (routing.selectedRoute == null) return;
    // FIXME when Viewport is ready in new mapbox flutter.
    // The delay is necessary, otherwise sometimes the camera won't move.
    // await Future.delayed(const Duration(milliseconds: 750));
    // final coordinatesSouthwest = routing.selectedRoute!.paddedBounds.southwest["coordinates"] as List;
    // final s = coordinatesSouthwest[1] as double;
    // final w = coordinatesSouthwest[0] as double;
    // final coordinatesNortheast = routing.selectedRoute!.paddedBounds.northeast["coordinates"] as List;
    // final n = coordinatesNortheast[1] as double;
    // final e = coordinatesNortheast[0] as double;
    // final newBounds = CoordinateBounds(
    //     southwest: Point(
    //         coordinates: Position(
    //       s + 0.66 * frame.size.height,
    //       w,
    //     )).toJson(),
    //     northeast: Point(
    //         coordinates: Position(
    //       n,
    //       e,
    //     )).toJson(),
    //     infiniteBounds: false);
    // final currentCameraOptions = await controller?.getCameraState();
    // if (currentCameraOptions == null) return;
    // final cameraOptionsForBounds = await controller?.cameraForCoordinateBounds(
    //   newBounds,
    //   currentCameraOptions.padding,
    //   currentCameraOptions.bearing,
    //   currentCameraOptions.pitch,
    // );
    // await controller?.flyTo(
    //   cameraOptionsForBounds!,
    //   MapAnimationOptions(duration: 1000),
    // );
  }
}
