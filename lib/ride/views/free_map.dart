import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/layers/sg_layers_free.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/free_ride.dart';
import 'package:priobike/settings/services/settings.dart';

class FreeRideMapView extends StatefulWidget {
  const FreeRideMapView({super.key});

  @override
  State<StatefulWidget> createState() => FreeRideMapViewState();
}

class FreeRideMapViewState extends State<FreeRideMapView> {
  static const viewId = "free.ride.views.map";

  static const userLocationLayerId = "user-ride-location-puck";

  /// The associated positioning service, which is injected by the provider.
  late Positioning positioning;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated free ride service, which is injected by the provider.
  late FreeRide freeRide;

  /// A map controller for the map.
  mapbox.MapboxMap? mapController;

  /// The index of the basemap layers where the first label layer is located (the label layers are top most).
  int firstBaseMapLabelLayerIndex = 0;

  /// The timer which updates the SGs that are currently visible on the map.
  Timer? updateVisibleSgsTimer;

  /// The timer which updates the predictions on the visible SGs.
  Timer? updateSgPredictionsTimer;

  /// The index in the list represents the layer order in z axis.
  final List layerOrder = [
    AllTrafficLightsLayer.layerId,
    AllTrafficLightsPredictionLayer.layerId,
    AllTrafficLightsPredictionLayer.countdownLayerId,
    userLocationLayerId,
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

    positioning = getIt<Positioning>();
    positioning.addListener(onPositioningUpdate);
    freeRide = getIt<FreeRide>();
    freeRide.addListener(onFreeRideUpdate);
    settings = getIt<Settings>();
  }

  void onFreeRideUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    positioning.removeListener(onPositioningUpdate);
    freeRide.removeListener(onFreeRideUpdate);
    updateVisibleSgsTimer?.cancel();
    updateVisibleSgsTimer = null;
    updateSgPredictionsTimer?.cancel();
    updateSgPredictionsTimer = null;
    super.dispose();
  }

  /// Update the view with the current data.
  Future<void> onPositioningUpdate() async {
    if (mapController == null) return;
    await adaptToChangedPosition();
  }

  /// Adapt the map controller to a changed position.
  Future<void> adaptToChangedPosition() async {
    if (mapController == null) return;

    final userPos = getIt<Positioning>().lastPosition;

    if (userPos == null) return;

    mapController!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(userPos.longitude, userPos.latitude)).toJson(),
          bearing: userPos.heading,
          zoom: 18,
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

    await getFirstLabelLayer();

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    await showUserLocationIndicator();

    var index = await getIndex(AllTrafficLightsLayer.layerId);
    if (!mounted) return;
    await AllTrafficLightsLayer().install(mapController!, at: index);
    index = await getIndex(AllTrafficLightsPredictionLayer.layerId);
    if (!mounted) return;
    await AllTrafficLightsPredictionLayer().install(mapController!, at: index);

    onPositioningUpdate();

    updateVisibleSgsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (mapController == null) return;
      final cameraBounds = await mapController!.getBounds();
      final cameraState = await mapController!.getCameraState();
      final List coordinates = cameraState.center["coordinates"] as List;
      if (coordinates.length != 2) return;
      final double lat = coordinates[1];
      final double lon = coordinates[0];
      freeRide.updateVisibleSgs(cameraBounds, LatLng(lat, lon), cameraState.zoom);
    });

    updateSgPredictionsTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mapController == null) return;
      final Map<String, dynamic> propertiesBySgId = {};
      for (final entries in freeRide.receivedPredictions.entries) {
        // Check if we have all necessary information.
        if (entries.value.greentimeThreshold == -1) continue;
        if (entries.value.predictionQuality == -1) continue;
        if (entries.value.value.isEmpty) continue;
        // Calculate the seconds since the start of the prediction.
        final now = DateTime.now();
        final secondsSinceStart = max(0, now.difference(entries.value.startTime).inSeconds);
        // Chop off the seconds that are not in the prediction vector.
        final secondsInVector = entries.value.value.length;
        if (secondsSinceStart >= secondsInVector) continue;
        // Calculate the current vector.
        final currentVector = entries.value.value.sublist(secondsSinceStart);
        if (currentVector.isEmpty) continue;
        // Calculate the seconds to the next phase change.
        int secondsToPhaseChange = 0;
        // Check if the phase changes within the current vector.
        bool greenNow = currentVector[0] >= entries.value.greentimeThreshold;
        for (int i = 1; i < currentVector.length; i++) {
          final greenThen = currentVector[i] >= entries.value.greentimeThreshold;
          if ((greenNow && !greenThen) || (!greenNow && greenThen)) {
            break;
          }
          secondsToPhaseChange++;
        }

        propertiesBySgId[entries.key] = {
          "greenNow": greenNow,
          "countdown": secondsToPhaseChange,
        };

        // Update the layer.
        AllTrafficLightsPredictionLayer(propertiesBySgId: propertiesBySgId).update(mapController!);
      }
    });
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
      logoViewMargins: Point(10, marginYLogo),
      logoViewOrnamentPosition: mapbox.OrnamentPosition.TOP_LEFT,
      attributionButtonMargins: Point(10, marginYAttribution),
      attributionButtonOrnamentPosition: mapbox.OrnamentPosition.TOP_RIGHT,
      saveBatteryModeEnabled: settings.saveBatteryModeEnabled,
    );
  }
}
