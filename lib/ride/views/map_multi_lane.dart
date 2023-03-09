import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/layers/route_layers.dart';
import 'package:priobike/common/map/layers/sg_layers.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning_multi_lane.dart';
import 'package:priobike/ride/services/ride_multi_lane.dart';
import 'package:priobike/routing/services/routing_multi_lane.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';

class RideMapMultiLaneView extends StatefulWidget {
  const RideMapMultiLaneView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideMapMultiLaneViewState();
}

class RideMapMultiLaneViewState extends State<RideMapMultiLaneView> {
  static const viewId = "ride.views.map.multi_lane";

  /// The associated routing service, which is injected by the provider.
  late RoutingMultiLane routingMultiLane;

  /// The associated positioning service, which is injected by the provider.
  late PositioningMultiLane positioningMultiLane;

  /// The associated ride service, which is injected by the provider.
  late RideMultiLane rideMultiLane;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated dangers service, which is injected by the provider.
  late Dangers dangers;

  /// The associated sg status service, which is injected by the provider.
  late PredictionSGStatus predictionSGStatus;

  /// A map controller for the map.
  mapbox.MapboxMap? mapController;

  /// The next traffic light that is displayed, if it is known.
  Symbol? upcomingTrafficLight;

  /// If the upcoming traffic light is green.
  bool? upcomingTrafficLightIsGreen;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    updateMap();
    setState(() {});
  }

  /// Update the map.
  void updateMap() {
    if (routingMultiLane.needsLayout[viewId] != false && mapController != null) {
      onRoutingUpdate();
      routingMultiLane.needsLayout[viewId] = false;
    }
    if (rideMultiLane.needsLayout[viewId] != false && mapController != null) {
      onRideUpdate();
      rideMultiLane.needsLayout[viewId] = false;
    }
    if (positioningMultiLane.needsLayout[viewId] != false && mapController != null) {
      onPositioningUpdate();
      positioningMultiLane.needsLayout[viewId] = false;
    }
    if (dangers.needsLayout[viewId] != false && mapController != null) {
      onDangersUpdate();
      dangers.needsLayout[viewId] = false;
    }
    if (predictionSGStatus.needsLayout[viewId] != false && mapController != null) {
      onStatusUpdate();
      predictionSGStatus.needsLayout[viewId] = false;
    }
  }

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);
    routingMultiLane = getIt<RoutingMultiLane>();
    routingMultiLane.addListener(update);
    rideMultiLane = getIt<RideMultiLane>();
    rideMultiLane.addListener(update);
    positioningMultiLane = getIt<PositioningMultiLane>();
    positioningMultiLane.addListener(update);
    dangers = getIt<Dangers>();
    dangers.addListener(update);
    predictionSGStatus = getIt<PredictionSGStatus>();
    predictionSGStatus.addListener(update);

    updateMap();
  }

  @override
  void dispose() {
    settings.removeListener(update);
    routingMultiLane.removeListener(update);
    rideMultiLane.removeListener(update);
    positioningMultiLane.removeListener(update);
    dangers.removeListener(update);
    predictionSGStatus.removeListener(update);
    super.dispose();
  }

  /// Update the view with the current data.
  Future<void> onStatusUpdate() async {
    if (!mounted) return;
    await SelectedRouteMultiLaneLayer().update(mapController!);
  }

  /// Update the view with the current data.
  Future<void> onRoutingUpdate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!mounted) return;
    await SelectedRouteMultiLaneLayer().update(mapController!);
    if (!mounted) return;
    await WaypointsLayer().update(mapController!);
    // Only hide the traffic lights behind the position if the user hasn't selected a SG.
    if (!mounted) return;
    await MultiLaneTrafficLightsLayer(isDark).update(mapController!);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark).update(mapController!);
  }

  /// Update the view with the current data.
  Future<void> onPositioningUpdate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Only hide the traffic lights behind the position if the user hasn't selected a SG.
    if (!mounted) return;
    await MultiLaneTrafficLightsLayer(isDark).update(mapController!);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark).update(mapController!);
    if (!mounted) return;
    await DangersLayer(isDark, hideBehindPosition: true).update(mapController!);
    await adaptToChangedPosition();
  }

  /// Update the view with the current data.
  Future<void> onRideUpdate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await TrafficLightMultiLaneLayer(isDark).update(mapController!);
  }

  /// Update the view with the current data.
  Future<void> onDangersUpdate() async {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await DangersLayer(isDark, hideBehindPosition: true).update(mapController!);
  }

  /// Adapt the map controller to a changed position.
  Future<void> adaptToChangedPosition() async {
    if (mapController == null) return;
    if (routingMultiLane.selectedRoute == null) return;

    final userPos = positioningMultiLane.lastPosition;
    final userPosSnap = positioningMultiLane.snap;

    if (userPos == null || userPosSnap == null) {
      await mapController?.setBounds(mapbox.CameraBoundsOptions(bounds: routingMultiLane.selectedRoute!.paddedBounds));
      return;
    }

    mapController!.easeTo(
        mapbox.CameraOptions(
          center:
              mapbox.Point(coordinates: mapbox.Position(userPosSnap.position.longitude, userPosSnap.position.latitude))
                  .toJson(),
          bearing: userPos.heading,
          zoom: 18,
          pitch: 60,
        ),
        mapbox.MapAnimationOptions(duration: 1500));

    await mapController?.style.styleLayerExists("user-ride-location-puck").then((value) async {
      if (value) {
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
            bearingImageSize: 0.35,
            accuracyRadiusColor: const Color(0x00000000).value,
            accuracyRadiusBorderColor: const Color(0x00000000).value,
          ),
        );
        // On iOS it seems like the duration is being given in seconds while on Android in milliseconds.
        if (Platform.isAndroid) {
          await mapController!.style
              .setStyleTransition(mapbox.TransitionOptions(duration: 1500, enablePlacementTransitions: false));
        } else {
          await mapController!.style
              .setStyleTransition(mapbox.TransitionOptions(duration: 1, enablePlacementTransitions: false));
        }
      }
    });
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(mapbox.StyleLoadedEventData styleLoadedEventData) async {
    if (mapController == null || !mounted) return;
    final ppi = MediaQuery.of(context).devicePixelRatio;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();
    if (!mounted) return;
    await SelectedRouteMultiLaneLayer()
        .install(mapController!, bgLineWidth: 16.0, fgLineWidth: 14.0, below: "user-ride-location-puck");
    await WaypointsLayer().install(mapController!, iconSize: ppi / 8, below: "user-ride-location-puck");
    if (!mounted) return;
    await MultiLaneTrafficLightsLayer(isDark).install(mapController!, iconSize: ppi / 5);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark).install(mapController!, iconSize: ppi / 5);
    if (!mounted) return;
    await DangersLayer(isDark, hideBehindPosition: true).install(mapController!, iconSize: ppi / 5);
    if (!mounted) return;
    await TrafficLightMultiLaneLayer(isDark).install(mapController!, iconSize: ppi / 5);

    onRoutingUpdate();
    onPositioningUpdate();
    onRideUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    // On iOS and Android we documented different behaviour regarding the position of the attribution and logo.
    // If this is fixed in an upcoming version of the Mapbox plugin, we may be able to remove those workaround adjustments
    // below.
    double marginYLogo = frame.padding.top;
    double marginYAttribution = 0.0;
    if (Platform.isAndroid) {
      final ppi = frame.devicePixelRatio;
      marginYLogo = marginYLogo * ppi;
      marginYAttribution = marginYLogo;
    } else {
      marginYLogo = marginYLogo * 0.7;
      marginYAttribution = marginYLogo - (22 * frame.devicePixelRatio);
    }
    return AppMap(
      onMapCreated: onMapCreated,
      onStyleLoaded: onStyleLoaded,
      logoViewMargins: Point(20, marginYLogo),
      logoViewOrnamentPosition: mapbox.OrnamentPosition.TOP_LEFT,
      attributionButtonMargins: Point(20, marginYAttribution),
      attributionButtonOrnamentPosition: mapbox.OrnamentPosition.TOP_RIGHT,
    );
  }
}
