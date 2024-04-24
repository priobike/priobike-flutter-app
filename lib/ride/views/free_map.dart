import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/layers/sg_layers_free.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/free_ride.dart';
import 'package:priobike/settings/services/settings.dart';

double getBearingDiff(double bearing1, double bearing2) {
  double diff = bearing1 - bearing2;
  if (diff < -180) {
    diff = 360 + diff;
  } else if (diff > 180) {
    diff = 360 - diff;
  }
  return diff;
}

class FreeRideMapView extends StatefulWidget {
  const FreeRideMapView({super.key});

  @override
  State<StatefulWidget> createState() => FreeRideMapViewState();
}

class FreeRideMapViewState extends State<FreeRideMapView> {
  static const viewId = "free.ride.views.map";

  static const bearingDiffThreshold = 90;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated free ride service, which is injected by the provider.
  late FreeRide freeRide;

  /// If the SG filter is active.
  late bool sgFilterActive;

  /// A map controller for the map.
  mapbox.MapboxMap? mapController;

  /// The index of the basemap layers where the first label layer is located (the label layers are top most).
  int firstBaseMapLabelLayerIndex = 0;

  /// The timer which updates the SGs that are currently visible on the map.
  Timer? updateVisibleSgsTimer;

  /// The timer which updates the predictions on the visible SGs.
  Timer? updateSgPredictionsTimer;

  /// The timer that controls positioning updates.
  Timer? positionUpdateTimer;

  /// The index in the list represents the layer order in z axis.
  final List layerOrder = [
    AllTrafficLightsPredictionGeometryLayer.layerId,
    AllTrafficLightsPredictionLayer.layerId,
    AllTrafficLightsPredictionLayer.countdownLayerId,
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

    freeRide = getIt<FreeRide>();
    freeRide.addListener(onFreeRideUpdate);
    settings = getIt<Settings>();
    sgFilterActive = settings.isFreeRideFilterEnabled;
  }

  void onFreeRideUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    freeRide.removeListener(onFreeRideUpdate);
    positionUpdateTimer?.cancel();
    positionUpdateTimer = null;
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

  /// Determine for the given prediction if it is currently green and the seconds until the next phase change.
  Future<(bool?, int?)> getGreenNowAndSecondsToPhaseChange(PredictionServicePrediction prediction) async {
    if (prediction.greentimeThreshold == -1) return (null, null);
    if (prediction.predictionQuality == -1) return (null, null);
    if (prediction.value.isEmpty) return (null, null);

    // Calculate the seconds since the start of the prediction.
    final now = DateTime.now();
    final secondsSinceStart = max(0, now.difference(prediction.startTime).inSeconds);
    // Chop off the seconds that are not in the prediction vector.
    final secondsInVector = prediction.value.length;
    if (secondsSinceStart >= secondsInVector) return (null, null);
    // Calculate the current vector.
    final currentVector = prediction.value.sublist(secondsSinceStart);
    if (currentVector.isEmpty) return (null, null);
    // Calculate the seconds to the next phase change.
    int secondsToPhaseChange = 0;
    // Check if the phase changes within the current vector.
    bool greenNow = currentVector[0] >= prediction.greentimeThreshold;
    for (int i = 1; i < currentVector.length; i++) {
      final greenThen = currentVector[i] >= prediction.greentimeThreshold;
      if ((greenNow && !greenThen) || (!greenNow && greenThen)) {
        break;
      }
      secondsToPhaseChange++;
    }
    return (greenNow, secondsToPhaseChange);
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(mapbox.StyleLoadedEventData styleLoadedEventData) async {
    if (mapController == null || !mounted) return;

    await getFirstLabelLayer();

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // var index = await getIndex(AllTrafficLightsLayer.layerId);
    // if (!mounted) return;
    // await AllTrafficLightsLayer().install(mapController!, at: index);
    var index = await getIndex(AllTrafficLightsPredictionGeometryLayer.layerId);
    if (!mounted) return;
    await AllTrafficLightsPredictionGeometryLayer().install(mapController!, at: index);
    index = await getIndex(AllTrafficLightsPredictionLayer.layerId);
    if (!mounted) return;
    await AllTrafficLightsPredictionLayer().install(mapController!, at: index);

    onPositioningUpdate();

    // Keep track of the last bearings to calculate a correction factor.
    final lastGPSPositionsForCorr =
        List<Position>.empty(growable: true); // Note: may lack some positions that were too close to the last one.
    final lastMagBearingsForCorr = List<double>.empty(growable: true); // Note: only updated on new position.

    // Will store our calculated bearing, which is a mixture of the
    // GPS bearing and the magnetometer bearing.
    double? currentCalcBearing;

    final positioning = getIt<Positioning>(); // Note: positioning is initiated in the above view.
    // The position is updated every 1 second, but the orientation is updated more frequently.
    // Thus, we choose a shorter updated interval to react more quickly to orientation changes.
    positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      if (mapController == null) return;

      // Get the current orientation from the mapbox puck layer.
      mapbox.Layer? puckLayer;
      if (Platform.isAndroid) {
        puckLayer = await mapController?.style.getLayer("mapbox-location-indicator-layer");
      } else {
        puckLayer = await mapController?.style.getLayer("puck");
      }
      if (puckLayer == null || puckLayer is! mapbox.LocationIndicatorLayer || puckLayer.bearing == null) return;
      final magBearing = puckLayer.bearing!;

      // Fetch the current position and its calculated bearing.
      var lastPosition = positioning.lastPosition;
      if (lastPosition == null) return;

      final receivedNewPosition = lastGPSPositionsForCorr.isEmpty || lastGPSPositionsForCorr.last != lastPosition;

      // Sometimes the orientation may be decalibrated. As a result,
      // we will have a constant offset between the GPS bearing and the magnetometer bearing.
      // Thus, we calculate the mean deviation between the GPS bearing and the magnetometer bearing
      // and use this as a correction factor for the magnetometer bearing.
      double sumDeviation = 0;
      if (lastGPSPositionsForCorr.length != lastMagBearingsForCorr.length) {
        throw Exception("Unequal length of bearing lists.");
      }
      for (int i = 0; i < lastGPSPositionsForCorr.length; i++) {
        sumDeviation += lastGPSPositionsForCorr[i].heading - lastMagBearingsForCorr[i];
      }
      double meanDeviation = lastGPSPositionsForCorr.isEmpty ? 0 : sumDeviation / lastGPSPositionsForCorr.length;

      // Update the last bearings, but only if we actually got a new GPS position.
      if (receivedNewPosition) {
        // Sometimes the last GNSS position may be very close to the current one.
        // In this case, the orientation will fluctuate a lot. Thus, we only add the
        // received GPS position if it is not too close to the last one.
        var shouldAdd = lastGPSPositionsForCorr.isEmpty ||
            vincenty.distance(
                  LatLng(lastPosition.latitude, lastPosition.longitude),
                  LatLng(lastGPSPositionsForCorr.last.latitude, lastGPSPositionsForCorr.last.longitude),
                ) >
                (5 / 3.6) * 1; // 5 km/h at 1 second.
        if (shouldAdd) {
          lastGPSPositionsForCorr.add(lastPosition);
          lastMagBearingsForCorr.add(magBearing);
          if (lastGPSPositionsForCorr.length > 5 /* 5 seconds (only updated on new position) */) {
            lastGPSPositionsForCorr.removeAt(0);
            lastMagBearingsForCorr.removeAt(0);
          }
        }
      }

      // Apply the correction factor.
      currentCalcBearing = magBearing + meanDeviation;

      mapController!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              lastPosition.longitude,
              lastPosition.latitude,
            ),
          ).toJson(),
          bearing: currentCalcBearing,
          zoom: 18.5,
          pitch: 60,
          padding: mapbox.MbxEdgeInsets(top: 200, bottom: 0, right: 0, left: 0),
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );
    });

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

      for (final entry in freeRide.receivedPredictions.entries) {
        // Check if we have all necessary information.
        if (freeRide.sgGeometries == null || freeRide.sgGeometries!.isEmpty) continue;
        if (currentCalcBearing == null) continue;
        if (positioning.lastPosition == null) continue;

        bool? greenNow;
        int? secondsToPhaseChange;
        (greenNow, secondsToPhaseChange) = await getGreenNowAndSecondsToPhaseChange(entry.value);

        if (!sgFilterActive) {
          propertiesBySgId[entry.key] = {
            "greenNow": greenNow,
            "opacity": 1,
            "countdown": secondsToPhaseChange?.toInt(),
            "lineWidth": 5,
          };
          continue;
        }

        // Bool that holds the state if a sg is most likely relevant for the user or not.
        bool isRelevant = false;

        final sgGeometry = freeRide.sgGeometries![entry.key];
        double sgBearing = freeRide.sgBearings![entry.key]!;

        // Fix sg bearing to make it comparable with user bearing.
        if (sgBearing < 0) {
          sgBearing = 180 + (180 - sgBearing.abs());
        }

        // 1. A sg facing towards the user is considered as relevant.
        // 360 need to be considered.

        final bearingDiff = getBearingDiff(currentCalcBearing!, sgBearing);
        if (-45 < bearingDiff && bearingDiff < 45) {
          isRelevant = true;
        }

        // 2. A sg facing to the left of the user with a lane going left from the user is considered as relevant.
        final coordinates = sgGeometry?['coordinates'];

        if (45 < bearingDiff && bearingDiff < 135) {
          if (coordinates != null && coordinates.length > 1) {
            final secondLast = coordinates[coordinates.length - 2];
            final last = coordinates[coordinates.length - 1];
            double laneEndBearing = vincenty.bearing(LatLng(secondLast[1], secondLast[0]), LatLng(last[1], last[0]));
            if (laneEndBearing < 0) {
              laneEndBearing = 180 + (180 - laneEndBearing.abs());
            }

            final bearingDiffLastSegment = getBearingDiff(currentCalcBearing!, laneEndBearing);

            // relative left is okay.
            // Just not
            if (45 < bearingDiffLastSegment && bearingDiffLastSegment < 135) {
              // Left sg.
              isRelevant = true;
            }
          }
        }

        // 3. A sg facing to the right of the user and being oriented towards the right side of the user is considered as relevant.
        if (-180 < bearingDiff && bearingDiff < 0) {
          if (coordinates != null && coordinates.length > 1) {
            final last = coordinates[coordinates.length - 1];
            double laneEndPositionBearing = vincenty.bearing(
              LatLng(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude),
              LatLng(last[1], last[0]),
            );
            if (laneEndPositionBearing < 0) {
              laneEndPositionBearing = 180 + (180 - laneEndPositionBearing.abs());
            }

            final bearingDiffUserSG = getBearingDiff(currentCalcBearing!, laneEndPositionBearing);

            if (170 < bearingDiffUserSG && bearingDiffUserSG < 0) {
              isRelevant = true;
            }
          }
        }

        propertiesBySgId[entry.key] = {
          "greenNow": greenNow,
          "countdown": secondsToPhaseChange?.toInt(),
          "opacity": isRelevant ? 1 : 0.25,
          "lineWidth": isRelevant ? 5 : 1,
        };
      }
      AllTrafficLightsPredictionLayer(propertiesBySgId: propertiesBySgId, userBearing: currentCalcBearing)
          .update(mapController!);
      AllTrafficLightsPredictionGeometryLayer(propertiesBySgId: propertiesBySgId, userBearing: currentCalcBearing)
          .update(mapController!);
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
      useMapboxPositioning: true,
    );
  }
}
