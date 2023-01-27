import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/layers.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:turf/helpers.dart' as turf;

class RideMapView extends StatefulWidget {
  const RideMapView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideMapViewState();
}

class RideMapViewState extends State<RideMapView> {
  static const viewId = "ride.views.map";

  late Routing routing;

  /// The associated positioning service, which is injected by the provider.
  late Positioning positioning;

  /// The associated ride service, which is injected by the provider.
  late Ride ride;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated dangers service, which is injected by the provider.
  late Dangers dangers;

  /// A map controller for the map.
  mapbox.MapboxMap? mapController;

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

    positioning = Provider.of<Positioning>(context);
    if (positioning.needsLayout[viewId] != false && mapController != null) {
      onPositioningUpdate();
      positioning.needsLayout[viewId] = false;
    }

    dangers = Provider.of<Dangers>(context);
    if (dangers.needsLayout[viewId] != false && mapController != null) {
      onDangersUpdate();
      dangers.needsLayout[viewId] = false;
    }

    super.didChangeDependencies();
  }

  /// Update the view with the current data.
  Future<void> onRoutingUpdate() async {
    if (!mounted) return;
    await SelectedRouteLayer(context).update(mapController!);
    if (!mounted) return;
    await WaypointsLayer(context).update(mapController!);
    // Only hide the traffic lights behind the position if the user hasn't selected a SG.
    if (!mounted) return;
    await TrafficLightsLayer(context, hideBehindPosition: ride.userSelectedSG == null).update(mapController!);
    if (!mounted) return;
    await OfflineCrossingsLayer(context, hideBehindPosition: ride.userSelectedSG == null).update(mapController!);
  }

  /// Update the view with the current data.
  Future<void> onPositioningUpdate() async {
    // Only hide the traffic lights behind the position if the user hasn't selected a SG.
    if (!mounted) return;
    await TrafficLightsLayer(context, hideBehindPosition: ride.userSelectedSG == null).update(mapController!);
    if (!mounted) return;
    await OfflineCrossingsLayer(context, hideBehindPosition: ride.userSelectedSG == null).update(mapController!);
    if (!mounted) return;
    await DangersLayer(context, hideBehindPosition: true).update(mapController!);
    await adaptToChangedPosition();
  }

  /// Update the view with the current data.
  Future<void> onRideUpdate() async {
    if (!mounted) return;
    await TrafficLightLayer(context).update(mapController!);

    if (ride.userSelectedSG != null) {
      // The camera target is the selected SG.
      final cameraTarget = LatLng(ride.userSelectedSG!.position.lat, ride.userSelectedSG!.position.lon);
      await mapController?.flyTo(
        mapbox.CameraOptions(
            center: turf.Point(coordinates: turf.Position(cameraTarget.longitude, cameraTarget.latitude)).toJson()),
        mapbox.MapAnimationOptions(duration: 200),
      );
    }
  }

  /// Update the view with the current data.
  Future<void> onDangersUpdate() async {
    if (!mounted) return;
    await DangersLayer(context, hideBehindPosition: true).update(mapController!);
  }

  /// Adapt the map controller to a changed position.
  Future<void> adaptToChangedPosition() async {
    if (mapController == null) return;
    if (routing.selectedRoute == null) return;

    // Get some data that we will need for adaptive camera control.
    final sgPos = ride.calcCurrentSG?.position;
    final sgPosLatLng = sgPos == null ? null : LatLng(sgPos.lat, sgPos.lon);
    final userPos = Provider.of<Positioning>(context, listen: false).lastPosition;
    final userPosSnap = positioning.snap;

    if (userPos == null || userPosSnap == null) {
      await mapController?.setBounds(mapbox.CameraBoundsOptions(bounds: routing.selectedRoute!.paddedBounds));
      return;
    }

    const vincenty = Distance(roundResult: false);

    // Calculate the bearing to the next traffic light.
    double? sgBearing = sgPosLatLng == null ? null : vincenty.bearing(userPosSnap.position, sgPosLatLng);

    // Adapt the focus dynamically to the next interesting feature.
    final distanceOfInterest = min(
      ride.calcDistanceToNextTurn ?? double.infinity,
      ride.calcDistanceToNextSG ?? double.infinity,
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
    if (ride.calcDistanceToNextSG != null &&
        sgBearing != null &&
        ride.calcDistanceToNextSG! < 500 &&
        ride.calcDistanceToNextSG! > 10) {
      cameraHeading = sgBearing > 0 ? sgBearing : 360 + sgBearing; // Look into the direction of the next SG.
    }
    // Avoid looking too far away from the route.
    if (cameraHeading == null || (cameraHeading - userPosSnap.heading).abs() > 20) {
      cameraHeading = userPosSnap.heading; // Look into the direction of the user.
    }

    if (ride.userSelectedSG == null) {
      // TODO Set duration in dependence of the speed (difference between current and last coordinate)
      mapController!.easeTo(
          mapbox.CameraOptions(
            center:
                turf.Point(coordinates: turf.Position(userPosSnap.position.longitude, userPosSnap.position.latitude))
                    .toJson(),
            bearing: cameraHeading,
            zoom: zoom,
            pitch: 60,
          ),
          mapbox.MapAnimationOptions(duration: 1500));
    }

    await mapController?.style.styleLayerExists("user-ride-location-puck").then((value) async {
      if (value) {
        // TODO Set duration in dependence of the speed (difference between current and last coordinate)
        // On iOS, in the current implementation, the puck won't show if we use the style transition to slower the
        // animation of the puck. Therefore, for now, we need to exclude that from the iOS version.
        if (Platform.isAndroid) {
          await mapController!.style
              .setStyleTransition(mapbox.TransitionOptions(duration: 3000, enablePlacementTransitions: false));
        }
        mapController!.style.updateLayer(
          mapbox.LocationIndicatorLayer(
            id: "user-ride-location-puck",
            bearing: userPos.heading,
            location: [userPosSnap.position.latitude, userPosSnap.position.longitude, userPos.altitude],
            accuracyRadius: userPos.accuracy,
          ),
        );
      }
    });
  }

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(mapbox.MapboxMap controller) async {
    mapController = controller;

    await mapController?.style.styleLayerExists("user-ride-location-puck").then((value) async {
      if (!value) {
        await mapController!.style.addLayer(
          mapbox.LocationIndicatorLayer(
            id: "user-ride-location-puck",
            bearingImage: Theme.of(context).brightness == Brightness.dark ? "positiondark" : "positionlight",
            bearingImageSize: 0.2,
            accuracyRadiusColor: const Color(0x00000000).value,
            accuracyRadiusBorderColor: const Color(0x00000000).value,
          ),
        );
        // On iOS, in the current implementation, the puck won't show if we use the style transition to slower the
        // animation of the puck. Therefore, for now, we need to exclude that from the iOS version.
        if (Platform.isAndroid) {
          await mapController!.style
              .setStyleTransition(mapbox.TransitionOptions(duration: 3000, enablePlacementTransitions: false));
        }
      }
    });
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(mapbox.StyleLoadedEventData styleLoadedEventData) async {
    if (mapController == null) return;

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    final ppi = MediaQuery.of(context).devicePixelRatio;
    await SelectedRouteLayer(context)
        .install(mapController!, bgLineWidth: 20.0, fgLineWidth: 14.0, below: "user-ride-location-puck");
    await WaypointsLayer(context).install(mapController!, iconSize: ppi / 8, below: "user-ride-location-puck");
    await TrafficLightsLayer(context, hideBehindPosition: ride.userSelectedSG == null)
        .install(mapController!, iconSize: ppi / 4);
    await OfflineCrossingsLayer(context, hideBehindPosition: ride.userSelectedSG == null)
        .install(mapController!, iconSize: ppi / 4);
    await DangersLayer(context, hideBehindPosition: true).install(mapController!, iconSize: ppi / 4);
    // The traffic light layer image has a 2x resolution to make it look good on high DPI screens.
    await TrafficLightLayer(context).install(mapController!, iconSize: ppi / 8);

    onRoutingUpdate();
    onPositioningUpdate();
    onRideUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    return AppMap(
      onMapCreated: onMapCreated,
      onStyleLoaded: onStyleLoaded,
      logoViewMargins: Point(10, frame.size.height - MediaQuery.of(context).padding.top - 35),
      attributionButtonMargins: Point(10, frame.size.height - MediaQuery.of(context).padding.top - 35),
    );
  }
}
