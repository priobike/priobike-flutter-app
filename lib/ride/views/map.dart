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

  const RideMapView({super.key, required this.onMapMoved, required this.cameraFollowUserLocation});

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

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

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
    TrafficLightsLayerClickable.layerId,
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
    settings = getIt<Settings>();
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
    await TrafficLightsLayer(isDark, hideBehindPosition: true).update(mapController!);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark, hideBehindPosition: true).update(mapController!);
  }

  /// Update the view with the current data.
  Future<void> onPositioningUpdate() async {
    if (mapController == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Only hide the traffic lights behind the position if the user hasn't selected a SG.
    if (!mounted) return;
    await TrafficLightsLayer(isDark, hideBehindPosition: true).update(mapController!);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark, hideBehindPosition: true).update(mapController!);
    await adaptToChangedPosition();
  }

  /// Update the view with the current data.
  Future<void> onRideUpdate() async {
    if (mapController == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!mounted) return;
    await TrafficLightLayer(isDark).update(mapController!);
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

    // Portrait/landscape mode
    final orientation = MediaQuery.of(context).orientation;
    final mapbox.MbxEdgeInsets padding;
    if (orientation == Orientation.portrait) {
      padding = mapbox.MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
    } else {
      // Landscape-Mode: Set user-puk to the left and a little down
      // The padding must be different if battery save mode is enabled by user because the map is rendered differently
      final isBatterySaveModeEnabled = getIt<Settings>().saveBatteryModeEnabled;
      final deviceWidth = MediaQuery.of(context).size.width;
      final deviceHeight = MediaQuery.of(context).size.height;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      if (isBatterySaveModeEnabled) {
        if (Platform.isAndroid) {
          padding = mapbox.MbxEdgeInsets(
              top: deviceHeight * 0.25, left: 0, bottom: 0, right: deviceWidth * pixelRatio * 0.055);
        } else {
          padding =
              mapbox.MbxEdgeInsets(top: deviceHeight * 0.55, left: 0, bottom: 0, right: deviceWidth * pixelRatio * 0.2);
        }
      } else {
        padding =
            mapbox.MbxEdgeInsets(top: deviceHeight * 0.7, left: 0, bottom: 0, right: deviceWidth * pixelRatio * 0.19);
      }
    }

    if (routing.hadErrorDuringFetch) {
      // If there was an error during fetching, we don't have a route and thus also can't snap the position.
      // We can only try to display the real user position.
      if (userPos == null) {
        await snapLocationIndicatorToRouteStart();
        return;
      }
      // Note: in the current version ease to is broken on ios devices.
      mapController!.flyTo(
          mapbox.CameraOptions(
            center: mapbox.Point(coordinates: mapbox.Position(userPos.longitude, userPos.latitude)).toJson(),
            bearing: userPos.heading,
            zoom: 16,
            pitch: 60,
            padding: padding,
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
      // Note: in the current version ease to is broken on ios devices.
      mapController!.flyTo(
          mapbox.CameraOptions(
            center: mapbox.Point(
                    coordinates: mapbox.Position(userPosSnap.position.longitude, userPosSnap.position.latitude))
                .toJson(),
            bearing: cameraHeading,
            zoom: zoom,
            pitch: 60,
            padding: padding,
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
              .setStyleTransition(mapbox.TransitionOptions(duration: 1000, enablePlacementTransitions: false));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await getFirstLabelLayer();

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    await showUserLocationIndicator();

    var index = await getIndex(SelectedRouteLayer.layerId);
    if (!mounted) return;
    try {
      await SelectedRouteLayer().install(mapController!, bgLineWidth: 16.0, fgLineWidth: 14.0, at: index);
    } catch (e) {
      log.e("Error while installing layers: $e");
    }
    index = await getIndex(WaypointsLayer.layerId);
    if (!mounted) return;
    try {
      await WaypointsLayer().install(mapController!, iconSize: 0.2, at: index, textSize: 18.0);
    } catch (e) {
      log.e("Error while installing layers: $e");
    }
    index = await getIndex(TrafficLightsLayer.layerId);
    if (!mounted) return;
    try {
      await TrafficLightsLayer(isDark, hideBehindPosition: true).install(
        mapController!,
        iconSize: 0.5,
        at: index,
        showTouchIndicator: true,
      );
    } catch (e) {
      log.e("Error while installing layers: $e");
    }
    index = await getIndex(TrafficLightsLayer.layerId);
    if (!mounted) return;
    try {
      await TrafficLightsLayerClickable().install(
        mapController!,
        iconSize: 0.5,
        at: index,
      );
    } catch (e) {
      log.e("Error while installing layers: $e");
    }
    index = await getIndex(OfflineCrossingsLayer.layerId);
    if (!mounted) return;
    try {
      await OfflineCrossingsLayer(isDark, hideBehindPosition: true).install(mapController!, iconSize: 0.5, at: index);
    } catch (e) {
      log.e("Error while installing layers: $e");
    }
    index = await getIndex(TrafficLightLayer.layerId);
    if (!mounted) return;
    try {
      await TrafficLightLayer(isDark).install(mapController!, iconSize: 0.5, at: index);
    } catch (e) {
      log.e("Error while installing layers: $e");
    }

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

    // Returns the Features for a given screen coordinate.
    final List<mapbox.QueriedRenderedFeature?> features = await mapController!.queryRenderedFeatures(
      mapbox.RenderedQueryGeometry(
        value: json.encode(actualScreenCoordinate.encode()),
        type: mapbox.Type.SCREEN_COORDINATE,
      ),
      mapbox.RenderedQueryOptions(
        layerIds: [TrafficLightsLayerClickable.layerId],
      ),
    );

    if (features.isNotEmpty) {
      onFeatureTapped(features[0]!);
    }
  }

  /// A callback that is called when the user taps a feature.
  onFeatureTapped(mapbox.QueriedRenderedFeature queriedFeature) async {
    // Map the id of the layer to the corresponding feature.
    final id = queriedFeature.queriedFeature.feature['id'];
    if ((id as String).startsWith("traffic-light-clickable")) {
      final sgIdx = int.tryParse(id.split("-")[3]);
      if (sgIdx == null) return;
      ride.userSelectSG(sgIdx);
      if (ride.userSelectedSG != null) {
        if (mapController == null) return;
        if (widget.cameraFollowUserLocation) widget.onMapMoved();
        // The camera target is the selected SG.
        final cameraTarget = LatLng(ride.userSelectedSG!.position.lat, ride.userSelectedSG!.position.lon);
        if (!mounted) return;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        await TrafficLightLayer(isDark).update(mapController!);

        if (mounted) {
          // Portrait/landscape mode
          final orientation = MediaQuery.of(context).orientation;
          final mapbox.MbxEdgeInsets padding;

          final isBatterySaveModeEnabled = getIt<Settings>().saveBatteryModeEnabled;
          final deviceWidth = MediaQuery.of(context).size.width;
          final deviceHeight = MediaQuery.of(context).size.height;
          final pixelRatio = MediaQuery.of(context).devicePixelRatio;

          // Get the scaled width and height.
          double scaleWidth = deviceWidth * (pixelRatio / Settings.scalingFactor);
          double scaleHeight = deviceHeight * (pixelRatio / Settings.scalingFactor);

          if (orientation == Orientation.portrait) {
            // We need to consider the scale factor in battery save mode.
            if (isBatterySaveModeEnabled) {
              // Note: ios uses device-independent pixel units and therefore we need to consider the scale factor.
              if (Platform.isIOS) {
                padding = mapbox.MbxEdgeInsets(top: 0, left: 0, bottom: scaleHeight * 0.05, right: 0);
              } else {
                padding = mapbox.MbxEdgeInsets(top: 0, left: 0, bottom: deviceHeight * 0.05, right: 0);
              }
            } else {
              padding = mapbox.MbxEdgeInsets(top: 0, left: 0, bottom: deviceHeight * 0.05, right: 0);
            }
          } else {
            // Landscape-Mode: Set user-puk to the left and a little down
            // The padding must be different if battery save mode is enabled by user because the map is rendered differently
            // We need to consider the scale factor in battery save mode for ios.
            if (isBatterySaveModeEnabled) {
              // Note: ios uses device-independent pixel units and therefore we need to consider the scale factor.
              if (Platform.isIOS) {
                padding = mapbox.MbxEdgeInsets(top: scaleHeight * 0.05, left: 0, bottom: 0, right: scaleWidth * 0.5);
              } else {
                padding =
                    mapbox.MbxEdgeInsets(top: deviceHeight * 0.05, left: 0, bottom: 0, right: deviceWidth * 0.175);
              }
            } else {
              padding = mapbox.MbxEdgeInsets(top: deviceHeight * 0.05, left: 0, bottom: 0, right: deviceWidth * 0.42);
            }
          }

          await mapController?.flyTo(
            mapbox.CameraOptions(
              center:
                  mapbox.Point(coordinates: mapbox.Position(cameraTarget.longitude, cameraTarget.latitude)).toJson(),
              padding: padding,
            ),
            mapbox.MapAnimationOptions(duration: 200),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    // On iOS and Android we documented different behaviour regarding the position of the attribution and logo.
    // If this is fixed in an upcoming version of the Mapbox plugin, we may be able to remove those workaround adjustments
    // below.
    // Note: still not fixed with version 3.16.4 and mapbox 0.5.0.
    double marginYLogo = 0;
    double marginYAttribution = 0;
    if (Platform.isAndroid) {
      marginYLogo = frame.padding.top + 15;
      marginYAttribution = frame.padding.top + 15;
    } else {
      marginYLogo = 15;
      marginYAttribution = -5;
    }

    return AppMap(
      onMapCreated: onMapCreated,
      onStyleLoaded: onStyleLoaded,
      onMapScroll: onMapScroll,
      onMapTap: onMapTap,
      logoViewMargins: Point(10, marginYLogo),
      logoViewOrnamentPosition: mapbox.OrnamentPosition.TOP_LEFT,
      attributionButtonMargins: Point(10, marginYAttribution),
      attributionButtonOrnamentPosition: mapbox.OrnamentPosition.TOP_RIGHT,
      saveBatteryModeEnabled: settings.saveBatteryModeEnabled,
    );
  }
}
