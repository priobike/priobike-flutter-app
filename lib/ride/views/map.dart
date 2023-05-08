import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/layers/route_layers.dart';
import 'package:priobike/common/map/layers/sg_layers.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';

class RideMapView extends StatefulWidget {
  const RideMapView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideMapViewState();
}

class RideMapViewState extends State<RideMapView> {
  static const viewId = "ride.views.map";

  static const userLocationLayerId = "user-ride-location-puck";

  late Routing routing;

  /// The associated positioning service, which is injected by the provider.
  late Positioning positioning;

  /// The associated ride service, which is injected by the provider.
  late Ride ride;

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

  /// The index of the basemap layers where the first label layer is located (the label layers are top most).
  var firstBaseMapLabelLayerIndex = 0;

  /// The index in the list represents the layer order in z axis.
  final List layerOrder = [
    SelectedRouteLayer.layerIdBackground,
    SelectedRouteLayer.layerId,
    WaypointsLayer.layerId,
    userLocationLayerId,
    OfflineCrossingsLayer.layerId,
    TrafficLightsLayer.layerId,
    TrafficLightLayer.layerId,
  ];

  /// Returns the index where the layer should be added in the Mapbox layer stack.
  Future<int> getIndex(String layerId) async {
    final currentLayers = await mapController!.style.getStyleLayers();
    // Find out how many of our layers are before the layer that should be added.
    var layersBeforeAdded = 0;
    for (final layer in layerOrder) {
      if (currentLayers.firstWhereOrNull((element) => element?.id == layer) != null) {
        layersBeforeAdded++;
      }
      if (layer == layerId) {
        break;
      }
    }
    // Add the layer on top of our layers that are before it and below the label layers.
    return firstBaseMapLabelLayerIndex + layersBeforeAdded;
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    updateMap();
  }

  /// Update the map.
  void updateMap() {
    if (routing.needsLayout[viewId] != false && mapController != null) {
      onRoutingUpdate();
      routing.needsLayout[viewId] = false;
    }
    if (ride.needsLayout[viewId] != false && mapController != null) {
      onRideUpdate();
      ride.needsLayout[viewId] = false;
    }
    if (positioning.needsLayout[viewId] != false && mapController != null) {
      onPositioningUpdate();
      positioning.needsLayout[viewId] = false;
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
    routing = getIt<Routing>();
    routing.addListener(update);
    ride = getIt<Ride>();
    ride.addListener(update);
    positioning = getIt<Positioning>();
    positioning.addListener(update);
    dangers = getIt<Dangers>();
    dangers.addListener(update);
    predictionSGStatus = getIt<PredictionSGStatus>();
    predictionSGStatus.addListener(update);
  }

  @override
  void dispose() {
    settings.removeListener(update);
    routing.removeListener(update);
    ride.removeListener(update);
    positioning.removeListener(update);
    dangers.removeListener(update);
    predictionSGStatus.removeListener(update);
    super.dispose();
  }

  /// Update the view with the current data.
  Future<void> onStatusUpdate() async {
    if (!mounted) return;
    await SelectedRouteLayer().update(mapController!);
  }

  /// Update the view with the current data.
  Future<void> onRoutingUpdate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!mounted) return;
    await SelectedRouteLayer().update(mapController!);
    if (!mounted) return;
    await WaypointsLayer().update(mapController!);
    // Only hide the traffic lights behind the position if the user hasn't selected a SG.
    if (!mounted) return;
    await TrafficLightsLayer(isDark, hideBehindPosition: ride.userSelectedSG == null).update(mapController!);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark, hideBehindPosition: ride.userSelectedSG == null).update(mapController!);
  }

  /// Update the view with the current data.
  Future<void> onPositioningUpdate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Only hide the traffic lights behind the position if the user hasn't selected a SG.
    if (!mounted) return;
    await TrafficLightsLayer(isDark, hideBehindPosition: ride.userSelectedSG == null).update(mapController!);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark, hideBehindPosition: ride.userSelectedSG == null).update(mapController!);
    await adaptToChangedPosition();
  }

  /// Update the view with the current data.
  Future<void> onRideUpdate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!mounted) return;
    await TrafficLightLayer(isDark).update(mapController!);

    if (ride.userSelectedSG != null) {
      // The camera target is the selected SG.
      final cameraTarget = LatLng(ride.userSelectedSG!.position.lat, ride.userSelectedSG!.position.lon);
      await mapController?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(cameraTarget.longitude, cameraTarget.latitude)).toJson(),
          zoom: 16,
        ),
        mapbox.MapAnimationOptions(duration: 200),
      );
    }
  }

  /// Adapt the map controller to a changed position.
  Future<void> adaptToChangedPosition() async {
    if (mapController == null) return;
    if (routing.selectedRoute == null) return;

    // Get some data that we will need for adaptive camera control.
    final sgPos = ride.calcCurrentSG?.position;
    final sgPosLatLng = sgPos == null ? null : LatLng(sgPos.lat, sgPos.lon);
    final userPos = getIt<Positioning>().lastPosition;
    final userPosSnap = positioning.snap;

    if (userPosSnap == null || userPos == null) {
      final currentCameraOptions = await mapController!.getCameraState();
      final cameraOptionsForBounds = await mapController!.cameraForCoordinateBounds(
        routing.selectedRoute!.paddedBounds,
        currentCameraOptions.padding,
        currentCameraOptions.bearing,
        currentCameraOptions.pitch,
      );
      final adaptedCameraOptionsForBounds = mapbox.CameraOptions(
        center: cameraOptionsForBounds.center,
        zoom: (cameraOptionsForBounds.zoom ?? 16) * (settings.saveBatteryModeEnabled ? 0.85 : 1),
        bearing: cameraOptionsForBounds.bearing,
        pitch: cameraOptionsForBounds.pitch,
        padding: cameraOptionsForBounds.padding,
      );
      await mapController?.flyTo(
        adaptedCameraOptionsForBounds,
        mapbox.MapAnimationOptions(duration: 1000),
      );
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
      mapController!.easeTo(
          mapbox.CameraOptions(
            center: mapbox.Point(
                    coordinates: mapbox.Position(userPosSnap.position.longitude, userPosSnap.position.latitude))
                .toJson(),
            bearing: cameraHeading,
            zoom: zoom,
            pitch: 60,
          ),
          mapbox.MapAnimationOptions(duration: 1500));
    }

    await mapController?.style.styleLayerExists(userLocationLayerId).then((value) async {
      if (value) {
        mapController!.style.updateLayer(
          mapbox.LocationIndicatorLayer(
            id: userLocationLayerId,
            bearing: userPos.heading,
            location: [userPosSnap.position.latitude, userPosSnap.position.longitude, userPos.altitude],
            accuracyRadius: userPos.accuracy,
          ),
        );
      }
    });
  }

  /// Used to get the index of the first label layer in the layer stack. This is used to place our layers below the
  /// label layers such that they are still readable.
  getFirstLabelLayer() async {
    if (mapController == null) return;

    final layers = await mapController!.style.getStyleLayers();
    final firstLabel = layers.firstWhereOrNull((layer) {
      final layerId = layer?.id ?? "";
      return layerId.contains("-label");
    });
    final firstLabelIndex = layers.indexOf(firstLabel);
    // If there are no label layers in the style we want to start adding on top of the last layer.
    if (firstLabelIndex != -1) {
      firstBaseMapLabelLayerIndex = firstLabelIndex;
    } else {
      firstBaseMapLabelLayerIndex = layers.length - 1;
    }
  }

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(mapbox.MapboxMap controller) async {
    mapController = controller;

    await getFirstLabelLayer();

    await mapController?.style.styleLayerExists(userLocationLayerId).then((value) async {
      if (!value) {
        await mapController!.style.addLayer(
          mapbox.LocationIndicatorLayer(
            id: userLocationLayerId,
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
    var index = await getIndex(SelectedRouteLayer.layerId);
    if (!mounted) return;
    await SelectedRouteLayer().install(mapController!, bgLineWidth: 16.0, fgLineWidth: 14.0, at: index);
    index = await getIndex(WaypointsLayer.layerId);
    if (!mounted) return;
    await WaypointsLayer().install(mapController!, iconSize: ppi / 8, at: index);
    index = await getIndex(TrafficLightsLayer.layerId);
    if (!mounted) return;
    await TrafficLightsLayer(isDark, hideBehindPosition: ride.userSelectedSG == null)
        .install(mapController!, iconSize: ppi / 5, at: index);
    index = await getIndex(OfflineCrossingsLayer.layerId);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark, hideBehindPosition: ride.userSelectedSG == null)
        .install(mapController!, iconSize: ppi / 5, at: index);
    index = await getIndex(TrafficLightLayer.layerId);
    if (!mounted) return;
    await TrafficLightLayer(isDark).install(mapController!, iconSize: ppi / 5, at: index);

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
      saveBatteryModeEnabled: settings.saveBatteryModeEnabled,
    );
  }
}
