import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as l;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/common/map/layers.dart';
import 'package:priobike/common/map/markers.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/positioning/services/snapping.dart';
import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';

class RideMapView extends StatefulWidget {
  const RideMapView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideMapViewState();
}

class RideMapViewState extends State<RideMapView> {
  static const viewId = "ride.views.map";

  /// The threshold used for showing traffic light colors and speedometer colors
  static const qualityThreshold = 0.75;

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

  /// The route that is displayed, if a route is selected.
  Line? route;

  /// The route background that is displayed, if a route is selected.
  Line? routeBackground;

  /// The traffic lights that are displayed, if there are traffic lights on the route.
  List<Symbol>? trafficLights;

  /// The offline crossings that are displayed, if there are offline crossings on the route.
  List<Symbol>? offlineCrossings;

  /// The current waypoints, if the route is selected.
  List<Symbol>? waypoints;

  /// The next traffic light that is displayed, if it is known.
  Symbol? upcomingTrafficLight;

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
    await loadRouteLayer();
    await loadTrafficLightMarkers();
    await loadOfflineCrossingMarkers();
    await loadWaypointMarkers();
  }

  /// Update the view with the current data.
  Future<void> onSnappingUpdate() async {
    await adaptToChangedPosition();
  }

  /// Update the view with the current data.
  Future<void> onRideUpdate() async {
    await loadNextTrafficLightLayer();
  }

  /// Load the current route layer.
  Future<void> loadRouteLayer() async {
    // If we have no map controller, we cannot load the route layer.
    if (mapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldRoute = route;
    final oldRouteBackground = routeBackground;
    if (routing.selectedRoute == null) return;
    // Add the new route layer.
    routeBackground = await mapController!.addLine(
      RouteBackgroundLayer(
        points: routing.selectedRoute!.route.map((e) => LatLng(e.lat, e.lon)).toList(),
        lineWidth: 20,
      ),
      routing.selectedRoute!.toJson(),
    );
    route = await mapController!.addLine(
      RouteLayer(points: routing.selectedRoute!.route.map((e) => LatLng(e.lat, e.lon)).toList(), lineWidth: 14),
      routing.selectedRoute!.toJson(),
    );
    // Remove the old route layer.
    if (oldRoute != null) await mapController!.removeLine(oldRoute);
    if (oldRouteBackground != null) {
      await mapController!.removeLine(oldRouteBackground);
    }
  }

  /// Load the current traffic lights.
  Future<void> loadTrafficLightMarkers() async {
    // If we have no map controller, we cannot load the traffic lights.
    if (mapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldTrafficLights = trafficLights;
    // Create a new traffic light marker for each traffic light.
    trafficLights = [];
    final willShowLabels = settings.sgLabelsMode == SGLabelsMode.enabled;
    // Check the prediction status of the traffic light.
    final statusProvider = Provider.of<PredictionSGStatus>(context, listen: false);
    final iconSize = MediaQuery.of(context).devicePixelRatio / 1.5;
    for (Sg sg in routing.selectedRoute?.signalGroups ?? []) {
      final status = statusProvider.cache[sg.id];
      if (status == null) {
        trafficLights!.add(await mapController!.addSymbol(
          OfflineMarker(
            iconSize: iconSize,
            geo: LatLng(sg.position.lat, sg.position.lon),
            label: willShowLabels ? sg.label : null,
            tilted: true,
          ),
        ));
      } else if (status.predictionState == SGPredictionState.offline) {
        trafficLights!.add(await mapController!.addSymbol(
          OfflineMarker(
            iconSize: iconSize,
            geo: LatLng(sg.position.lat, sg.position.lon),
            label: willShowLabels ? sg.label : null,
            tilted: true,
          ),
        ));
      } else if (status.predictionState == SGPredictionState.bad) {
        trafficLights!.add(await mapController!.addSymbol(
          BadSignalMarker(
            iconSize: iconSize,
            geo: LatLng(sg.position.lat, sg.position.lon),
            label: willShowLabels ? sg.label : null,
            tilted: true,
          ),
        ));
      } else {
        trafficLights!.add(await mapController!.addSymbol(
          OnlineMarker(
            iconSize: iconSize,
            geo: LatLng(sg.position.lat, sg.position.lon),
            label: willShowLabels ? sg.label : null,
            tilted: true,
          ),
        ));
      }
    }
    // Remove the old traffic lights.
    await mapController!.removeSymbols(oldTrafficLights ?? []);
  }

  /// Load the current crossings.
  Future<void> loadOfflineCrossingMarkers() async {
    // If we have no map controller, we cannot load the crossings.
    if (mapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldOfflineCrossings = offlineCrossings;
    // Create a new crossing marker for each crossing.
    offlineCrossings = [];
    final willShowLabels = settings.sgLabelsMode == SGLabelsMode.enabled;
    // Check the prediction status of the traffic light.
    final iconSize = MediaQuery.of(context).devicePixelRatio / 1.5;
    for (Crossing crossing in routing.selectedRoute?.crossings ?? []) {
      if (crossing.connected) continue;
      offlineCrossings!.add(await mapController!.addSymbol(
        DisconnectedMarker(
          iconSize: iconSize,
          geo: LatLng(crossing.position.lat, crossing.position.lon),
          label: willShowLabels ? crossing.name : null,
        ),
      ));
    }
    // Remove the old crossings.
    await mapController!.removeSymbols(oldOfflineCrossings ?? []);
  }

  /// Load the current waypoint markers.
  Future<void> loadWaypointMarkers() async {
    // If we have no map controller, we cannot load the waypoint layer.
    if (mapController == null) return;
    // Cache the old annotations to remove them later. This avoids flickering.
    final oldWaypoints = waypoints;
    waypoints = [];
    // Create a new waypoint marker for each waypoint.
    for (MapEntry<int, Waypoint> entry in routing.selectedWaypoints?.asMap().entries ?? []) {
      if (entry.key == 0) {
        waypoints!.add(await mapController!.addSymbol(
          StartMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      } else if (entry.key == routing.selectedWaypoints!.length - 1) {
        waypoints!.add(await mapController!.addSymbol(
          DestinationMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      } else {
        waypoints!.add(await mapController!.addSymbol(
          WaypointMarker(geo: LatLng(entry.value.lat, entry.value.lon)),
          entry.value.toJSON(),
        ));
      }
    }
    // Remove the old waypoint markers.
    await mapController!.removeSymbols(oldWaypoints ?? []);
  }

  /// Adapt the map controller to a changed position.
  Future<void> adaptToChangedPosition() async {
    if (mapController == null) return;
    if (routing.selectedRoute == null) return;

    // Get some data that we will need for adaptive camera control.
    final sgPos = ride.currentRecommendation?.sgPos;
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
    if (cameraHeading == null || (cameraHeading - userSnapHeading).abs() > 45) {
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

    final iconSize = MediaQuery.of(context).devicePixelRatio / 1.5;
    final r = ride.currentRecommendation;
    final isGreen = ride.calcCurrentSignalIsGreen; // Computed by the app for higher precision.

    if (r != null && !r.error && isGreen != null && r.sgPos != null && r.quality! >= qualityThreshold) {
      if (isGreen) {
        upcomingTrafficLight = await mapController!.addSymbol(
          TrafficLightGreenMarker(
            geo: LatLng(r.sgPos!.lat, r.sgPos!.lon),
            iconSize: iconSize,
          ),
        );
      } else {
        upcomingTrafficLight = await mapController!.addSymbol(
          TrafficLightRedMarker(
            geo: LatLng(r.sgPos!.lat, r.sgPos!.lon),
            iconSize: iconSize,
          ),
        );
      }
    }

    if (currentTrafficLight != null) {
      await mapController!.removeSymbol(currentTrafficLight);
    }
  }

  /// A callback that is called when the user taps a fill.
  Future<void> onFillTapped(Fill fill) async {/* Do nothing */}

  /// A callback that is called when the user taps a circle.
  Future<void> onCircleTapped(Circle circle) async {/* Do nothing */}

  /// A callback that is called when the user taps a line.
  Future<void> onLineTapped(Line line) async {/* Do nothing */}

  /// A callback that is called when the user taps a symbol.
  Future<void> onSymbolTapped(Symbol symbol) async {/* Do nothing */}

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(MapboxMapController controller) async {
    mapController = controller;

    // Bind the interaction callbacks.
    controller.onFillTapped.add(onFillTapped);
    controller.onCircleTapped.add(onCircleTapped);
    controller.onLineTapped.add(onLineTapped);
    controller.onSymbolTapped.add(onSymbolTapped);

    // Dont call any line/symbol/... removal/add operations here.
    // The mapcontroller won't have the necessary line/symbol/...manager.
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(BuildContext context) async {
    if (mapController == null) return;

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
  void dispose() {
    () async {
      // Remove all layers from the map.
      await mapController?.clearFills();
      await mapController?.clearCircles();
      await mapController?.clearLines();
      await mapController?.clearSymbols();

      // Unbind the interaction callbacks.
      mapController?.onFillTapped.remove(onFillTapped);
      mapController?.onCircleTapped.remove(onCircleTapped);
      mapController?.onLineTapped.remove(onLineTapped);
      mapController?.onSymbolTapped.remove(onSymbolTapped);
      mapController?.dispose();
    }();

    super.dispose();
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
