import 'dart:convert';
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
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';

class RideMapView extends StatefulWidget {
  /// Callback that is called when the map is moved by the user.
  final Function onMapMoved;

  /// If the map should follow the user location.
  final bool cameraFollowUserLocation;

  const RideMapView({Key? key, required this.onMapMoved, required this.cameraFollowUserLocation}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideMapViewState();
}

class RideMapViewState extends State<RideMapView> {
  static const viewId = "ride.views.map";

  static const userLocationLayerId = "user-ride-location-puck";

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated positioning service, which is injected by the provider.
  late Positioning positioning;

  /// The associated ride service, which is injected by the provider.
  late Ride ride;

  /// The associated sg status service, which is injected by the provider.
  late PredictionSGStatus predictionSGStatus;

  /// A map controller for the map.
  mapbox.MapboxMap? mapController;

  /// The next traffic light that is displayed, if it is known.
  Symbol? upcomingTrafficLight;

  /// If the upcoming traffic light is green.
  bool? upcomingTrafficLightIsGreen;

  /// The index of the basemap layers where the first label layer is located (the label layers are top most).
  int firstBaseMapLabelLayerIndex = 0;

  /// The index in the list represents the layer order in z axis.
  final List layerOrder = [
    SelectedRouteLayer.layerIdBackground,
    SelectedRouteLayer.layerId,
    WaypointsLayer.layerId,
    userLocationLayerId,
    OfflineCrossingsLayer.layerId,
    TrafficLightsLayer.layerId,
    TrafficLightsLayer.touchIndicatorsLayerId,
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

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(onRoutingUpdate);
    ride = getIt<Ride>();
    ride.addListener(onRideUpdate);
    positioning = getIt<Positioning>();
    positioning.addListener(onPositioningUpdate);
    predictionSGStatus = getIt<PredictionSGStatus>();
    predictionSGStatus.addListener(onStatusUpdate);
  }

  @override
  void dispose() {
    routing.removeListener(onRoutingUpdate);
    ride.removeListener(onRideUpdate);
    positioning.removeListener(onPositioningUpdate);
    predictionSGStatus.removeListener(onStatusUpdate);
    super.dispose();
  }

  /// Update the view with the current data.
  Future<void> onStatusUpdate() async {
    if (mapController == null) return;
    if (!mounted) return;
    await SelectedRouteLayer().update(mapController!);
  }

  /// Update the view with the current data.
  Future<void> onRoutingUpdate() async {
    if (mapController == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!mounted) return;
    await SelectedRouteLayer().update(mapController!);
    if (!mounted) return;
    await WaypointsLayer().update(mapController!);
    // Only hide the traffic lights behind the position if the user hasn't selected a SG.
    if (!mounted) return;
    await TrafficLightsLayer(isDark, hideBehindPosition: false, showTouchIndicators: !widget.cameraFollowUserLocation)
        .update(mapController!);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark, hideBehindPosition: false).update(mapController!);
  }

  /// Update the view with the current data.
  Future<void> onPositioningUpdate() async {
    if (mapController == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Only hide the traffic lights behind the position if the user hasn't selected a SG.
    if (!mounted) return;
    await TrafficLightsLayer(isDark, hideBehindPosition: false, showTouchIndicators: !widget.cameraFollowUserLocation)
        .update(mapController!);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark, hideBehindPosition: false).update(mapController!);
    await adaptToChangedPosition();
  }

  /// Update the view with the current data.
  Future<void> onRideUpdate() async {
    if (mapController == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!mounted) return;
    await TrafficLightLayer(isDark).update(mapController!);

    if (ride.userSelectedSG != null) {
      // The camera target is the selected SG.
      final cameraTarget = LatLng(ride.userSelectedSG!.position.lat, ride.userSelectedSG!.position.lon);
      await mapController?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(cameraTarget.longitude, cameraTarget.latitude)).toJson(),
          padding: mapbox.MbxEdgeInsets(bottom: 200, top: 0, left: 0, right: 0),
        ),
        mapbox.MapAnimationOptions(duration: 200),
      );
    }
  }

  /// Snap the location indicator to the start of the route.
  Future<void> snapLocationIndicatorToRouteStart() async {
    if (mapController == null) return;
    final startPointLon = routing.selectedRoute!.route.first.lon;
    final startPointLat = routing.selectedRoute!.route.first.lat;
    final secondPointLon = routing.selectedRoute!.route[1].lon;
    final secondPointLat = routing.selectedRoute!.route[1].lat;
    final bearingStart = vincenty.bearing(LatLng(startPointLat, startPointLon), LatLng(secondPointLat, secondPointLon));
    final cameraOptions = mapbox.CameraOptions(
      center: mapbox.Point(coordinates: mapbox.Position(startPointLon, startPointLat)).toJson(),
      zoom: 16,
      bearing: bearingStart,
    );
    await mapController?.flyTo(cameraOptions, mapbox.MapAnimationOptions(duration: 1000));
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

    const vincenty = Distance(roundResult: false);

    if (routing.hadErrorDuringFetch) {
      // If there was an error during fetching, we don't have a route and thus also can't snap the position.
      // We can only try to display the real user position.
      if (userPos == null) {
        await snapLocationIndicatorToRouteStart();
        return;
      }
      mapController!.easeTo(
          mapbox.CameraOptions(
            center: mapbox.Point(coordinates: mapbox.Position(userPos.longitude, userPos.latitude)).toJson(),
            bearing: userPos.heading,
            zoom: 16,
            pitch: 60,
          ),
          mapbox.MapAnimationOptions(duration: 1500));
      await mapController?.style.styleLayerExists(userLocationLayerId).then((value) async {
        if (value) {
          mapController!.style.updateLayer(
            mapbox.LocationIndicatorLayer(
              id: userLocationLayerId,
              bearing: userPos.heading,
              location: [userPos.latitude, userPos.longitude, userPos.altitude],
              accuracyRadius: userPos.accuracy,
            ),
          );
        }
      });
      return;
    }

    if (userPos == null || userPosSnap == null) {
      await snapLocationIndicatorToRouteStart();
      return;
    }

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

    if (ride.userSelectedSG == null && widget.cameraFollowUserLocation) {
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
    // If there are no label layers in the style we want to start adding on top of the last layer.
    if (firstLabel == null) {
      firstBaseMapLabelLayerIndex = (layers.isNotEmpty) ? layers.length - 1 : 0;
      return;
    }
    final firstLabelIndex = layers.indexOf(firstLabel);
    // If there are no label layers in the style we want to start adding on top of the last layer.
    if (firstLabelIndex == -1) {
      firstBaseMapLabelLayerIndex = (layers.isNotEmpty) ? layers.length - 1 : 0;
      return;
    }

    firstBaseMapLabelLayerIndex = firstLabelIndex;
  }

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(mapbox.MapboxMap controller) async {
    mapController = controller;
  }

  /// Show the user location on the map.
  Future<void> showUserLocationIndicator() async {
    final index = await getIndex(userLocationLayerId);
    await mapController?.style.styleLayerExists(userLocationLayerId).then((value) async {
      if (!value) {
        await mapController!.style.addLayerAt(
          mapbox.LocationIndicatorLayer(
            id: userLocationLayerId,
            bearingImage: Theme.of(context).brightness == Brightness.dark ? "positiondark" : "positionlight",
            bearingImageSize: 0.35,
            accuracyRadiusColor: const Color(0x00000000).value,
            accuracyRadiusBorderColor: const Color(0x00000000).value,
          ),
          mapbox.LayerPosition(at: index),
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

    await getFirstLabelLayer();

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    await showUserLocationIndicator();

    var index = await getIndex(SelectedRouteLayer.layerId);
    if (!mounted) return;
    await SelectedRouteLayer().install(mapController!, bgLineWidth: 16.0, fgLineWidth: 14.0, at: index);
    index = await getIndex(WaypointsLayer.layerId);
    if (!mounted) return;
    await WaypointsLayer().install(mapController!, iconSize: ppi / 8, at: index);
    index = await getIndex(TrafficLightsLayer.layerId);
    if (!mounted) return;
    await TrafficLightsLayer(isDark, hideBehindPosition: false, showTouchIndicators: !widget.cameraFollowUserLocation)
        .install(
      mapController!,
      iconSize: ppi / 5,
      at: index,
    );
    index = await getIndex(OfflineCrossingsLayer.layerId);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark, hideBehindPosition: false)
        .install(mapController!, iconSize: ppi / 5, at: index);
    index = await getIndex(TrafficLightLayer.layerId);
    if (!mounted) return;
    await TrafficLightLayer(isDark).install(mapController!, iconSize: ppi / 5, at: index);

    onRoutingUpdate();
    onPositioningUpdate();
    onRideUpdate();
  }

  /// A callback which is executed when the map is scrolled.
  Future<void> onMapScroll(mapbox.ScreenCoordinate screenCoordinate) async {
    widget.onMapMoved();
  }

  /// A callback which is executed when a tap on the map is registered.
  /// This also resolves if a certain feature is being tapped on. This function
  /// should get screen coordinates. However, at the moment (mapbox_maps_flutter version 0.4.0)
  /// there is a bug causing this to get world coordinates in the form of a ScreenCoordinate.
  Future<void> onMapTap(mapbox.ScreenCoordinate screenCoordinate) async {
    if (mapController == null || !mounted) return;
    if (widget.cameraFollowUserLocation) return;

    // Because of the bug in the plugin we need to calculate the actual screen coordinates to query
    // for the features in dependence of the tapped on screenCoordinate afterwards. If the bug is
    // fixed in an upcoming version we need to remove this conversion.
    final mapbox.ScreenCoordinate actualScreenCoordinate = await mapController!.pixelForCoordinate(
      mapbox.Point(
        coordinates: mapbox.Position(
          screenCoordinate.y,
          screenCoordinate.x,
        ),
      ).toJson(),
    );

    final List<mapbox.QueriedFeature?> features = await mapController!.queryRenderedFeatures(
      mapbox.RenderedQueryGeometry(
        value: json.encode(actualScreenCoordinate.encode()),
        type: mapbox.Type.SCREEN_COORDINATE,
      ),
      mapbox.RenderedQueryOptions(
        layerIds: [TrafficLightsLayer.layerId, TrafficLightsLayer.touchIndicatorsLayerId],
      ),
    );

    if (features.isNotEmpty) {
      onFeatureTapped(features[0]!);
    }
  }

  /// A callback that is called when the user taps a feature.
  onFeatureTapped(mapbox.QueriedFeature queriedFeature) async {
    // Map the id of the layer to the corresponding feature.
    final id = queriedFeature.feature['id'];
    if ((id as String).startsWith("traffic-light-")) {
      final sgIdx = int.tryParse(id.split("-")[2]);
      if (sgIdx == null) return;
      ride.userSelectSG(sgIdx);
    }
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
      onMapScroll: onMapScroll,
      onMapTap: onMapTap,
      logoViewMargins: Point(20, marginYLogo),
      logoViewOrnamentPosition: mapbox.OrnamentPosition.TOP_LEFT,
      attributionButtonMargins: Point(20, marginYAttribution),
      attributionButtonOrnamentPosition: mapbox.OrnamentPosition.TOP_RIGHT,
      saveBatteryModeEnabled: getIt<Settings>().saveBatteryModeEnabled,
    );
  }
}
