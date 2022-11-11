import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as l;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/controller.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/common/map/layers.dart';
import 'package:priobike/common/map/markers.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/positioning/services/snapping.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class RideMapView extends StatefulWidget {
  const RideMapView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideMapViewState();
}

class RideMapViewState extends State<RideMapView> {
  static const viewId = "ride.views.map";

  /// The threshold used for showing traffic light colors and speedometer colors
  static const qualityThreshold = 0.5;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated snapping service, which is injected by the provider.
  late Snapping snapping;

  /// The associated ride service, which is injected by the provider.
  late Ride ride;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// A map controller for the map.
  MapboxMapController? mapController;

  /// A layer controller to safe add and remove layers.
  LayerController? layerController;

  /// The next traffic light that is displayed, if it is known.
  Symbol? upcomingTrafficLight;

  /// If the upcoming traffic light is green.
  bool? upcomingTrafficLightIsGreen;

  @override
  void didChangeDependencies() {
    settings = Provider.of<Settings>(context);

    routing = Provider.of<Routing>(context);
    if (routing.needsLayout[viewId] != false && mapController != null) {
      onRoutingUpdate();
      routing.needsLayout[viewId] = false;
    }

    ride = Provider.of<Ride>(context);
    if (ride.needsLayout[viewId] != false && mapController != null) {
      onRideUpdate();
      ride.needsLayout[viewId] = false;
    }

    snapping = Provider.of<Snapping>(context);
    if (snapping.needsLayout[viewId] != false && mapController != null) {
      onSnappingUpdate();
      snapping.needsLayout[viewId] = false;
    }

    super.didChangeDependencies();
  }

  /// Update the view with the current data.
  Future<void> onRoutingUpdate() async {
    final ppi = MediaQuery.of(context).devicePixelRatio;
    await SelectedRouteLayer(context).addTo(layerController!, bgLineWidth: 20, fgLineWidth: 14);
    await WaypointsLayer(context).addTo(layerController!, iconSize: ppi / 4);
    await TrafficLightsLayer(context).addTo(layerController!, iconSize: ppi);
    await OfflineCrossingsLayer(context).addTo(layerController!, iconSize: ppi);
  }

  /// Update the view with the current data.
  Future<void> onSnappingUpdate() async {
    await adaptToChangedPosition();
  }

  /// Update the view with the current data.
  Future<void> onRideUpdate() async {
    await loadNextTrafficLightLayer();
  }

  /// Adapt the map controller to a changed position.
  Future<void> adaptToChangedPosition() async {
    if (mapController == null) return;
    if (routing.selectedRoute == null) return;

    // Get some data that we will need for adaptive camera control.
    final sgPos = ride.currentRecommendation?.sg?.position;
    final sgPosLatLng = sgPos == null ? null : l.LatLng(sgPos.lat, sgPos.lon);
    final userSnapPos = snapping.snappedPosition;
    final userSnapHeading = snapping.snappedHeading;
    final userSnapPosLatLng = userSnapPos == null ? null : l.LatLng(userSnapPos.latitude, userSnapPos.longitude);

    if (userSnapPos == null || userSnapPosLatLng == null || userSnapHeading == null) {
      await mapController?.animateCamera(CameraUpdate.newLatLngBounds(routing.selectedRoute!.paddedBounds));
      return;
    }

    const vincenty = l.Distance(roundResult: false);

    // Calculate the distance to the next traffic light.
    double? sgDistance = sgPosLatLng == null ? null : vincenty.distance(userSnapPosLatLng, sgPosLatLng);

    // Calculate the bearing to the next traffic light.
    double? sgBearing = sgPosLatLng == null ? null : vincenty.bearing(userSnapPosLatLng, sgPosLatLng);

    // Adapt the focus dynamically to the next interesting feature.
    final distanceOfInterest = min(
      snapping.distanceToNextTurn ?? double.infinity,
      sgDistance ?? double.infinity,
    );
    // Scale the zoom level with the distance of interest.
    // Between 0 meters: zoom 18 and 500 meters: zoom 18.
    double zoom = 18 - (distanceOfInterest / 500).clamp(0, 1) * 2;

    // Within those thresholds the bearing to the next SG is used.
    // max-threshold: If the next SG is to far away it doesn't make sense to align to it.
    // min-threshold: Often the SGs are slightly on the left or right side of the route and
    //                without this threshold the camera would orient away from the route
    //                when it's close to the SG.
    double? cameraHeading;
    if (sgDistance != null && sgBearing != null && sgDistance < 500 && sgDistance > 10) {
      cameraHeading = sgBearing > 0 ? sgBearing : 360 + sgBearing; // Look into the direction of the next SG.
    }
    // Avoid looking too far away from the route.
    if (cameraHeading == null || (cameraHeading - userSnapHeading).abs() > 30) {
      cameraHeading = userSnapHeading; // Look into the direction of the user.
    }

    // The camera target is the estimated user position.
    final cameraTarget = LatLng(userSnapPosLatLng.latitude, userSnapPosLatLng.longitude);

    await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          bearing: cameraHeading,
          target: cameraTarget,
          zoom: zoom,
          tilt: 60,
        )),
        duration: const Duration(milliseconds: 1000 /* Avg. GPS refresh rate */));

    await mapController!.updateUserLocation(
      lat: userSnapPos.latitude,
      lon: userSnapPos.longitude,
      alt: userSnapPos.altitude,
      acc: userSnapPos.accuracy,
      heading: userSnapPos.heading,
      speed: userSnapPos.speed,
    );
  }

  /// Load the upcoming traffic light layer.
  Future<void> loadNextTrafficLightLayer() async {
    if (mapController == null) return;

    // Cache the already displayed one to remove it after we have drawn on top.
    final currentTrafficLight = upcomingTrafficLight;
    final currentTrafficLightIsGreen = upcomingTrafficLightIsGreen;

    final iconSize = MediaQuery.of(context).devicePixelRatio / 2; // Green/Red icons are x2.
    final r = ride.currentRecommendation;
    final isGreen = ride.calcCurrentSignalIsGreen; // Computed by the app for higher precision.

    if (r != null && !r.error && isGreen != null && r.sg?.position != null && r.quality! >= qualityThreshold) {
      if (isGreen && currentTrafficLightIsGreen != true) {
        upcomingTrafficLight = await mapController!.addSymbol(
          TrafficLightGreenMarker(
            geo: LatLng(r.sg!.position.lat, r.sg!.position.lon),
            iconSize: iconSize,
            brightness: Theme.of(context).brightness,
          ),
        );
        upcomingTrafficLightIsGreen = isGreen;
        if (currentTrafficLight != null) {
          await mapController!.removeSymbol(currentTrafficLight);
        }
      } else if (!isGreen && currentTrafficLightIsGreen != false) {
        upcomingTrafficLight = await mapController!.addSymbol(
          TrafficLightRedMarker(
            geo: LatLng(r.sg!.position.lat, r.sg!.position.lon),
            iconSize: iconSize,
            brightness: Theme.of(context).brightness,
          ),
        );
        upcomingTrafficLightIsGreen = isGreen;
        if (currentTrafficLight != null) {
          await mapController!.removeSymbol(currentTrafficLight);
        }
      }
    }
  }

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(MapboxMapController controller) async {
    mapController = controller;

    // Wrap the map controller in a layer controller for safer layer access.
    layerController = LayerController(mapController: controller);

    // Dont call any line/symbol/... removal/add operations here.
    // The mapcontroller won't have the necessary line/symbol/...manager.
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(BuildContext context) async {
    if (mapController == null) return;

    // Remove all layers from the map that may still exist.
    await mapController?.clearFills();
    await mapController?.clearCircles();
    await mapController?.clearLines();
    await mapController?.clearSymbols();

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // Allow overlaps so that important symbols and texts are not hidden.
    await mapController!.setSymbolIconAllowOverlap(true);
    await mapController!.setSymbolIconIgnorePlacement(true);
    await mapController!.setSymbolTextAllowOverlap(true);
    await mapController!.setSymbolTextIgnorePlacement(true);

    onRoutingUpdate();
    onSnappingUpdate();
    onRideUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return AppMap(
      puckImage: Theme.of(context).brightness == Brightness.dark
          ? 'assets/images/position-dark.png'
          : 'assets/images/position-light.png',
      dragEnabled: false,
      onMapCreated: onMapCreated,
      onStyleLoaded: () => onStyleLoaded(context),
    );
  }
}
