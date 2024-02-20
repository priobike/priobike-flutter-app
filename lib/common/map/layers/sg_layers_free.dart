import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/free_ride.dart';

class AllTrafficLightsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "all-traffic-lights";

  /// The ID of the Mapbox layer.
  static const layerId = "all-traffic-lights-icons";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  AllTrafficLightsLayer() {
    final freeRide = getIt<FreeRide>();
    if (freeRide.sgs == null || freeRide.sgs!.isEmpty) return;

    for (final entry in freeRide.sgs!.entries) {
      final Map<String, dynamic> properties = {
        "id": entry.key,
      };

      features.add(
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [entry.value.longitude, entry.value.latitude],
          },
          "properties": properties,
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {iconSize = 1.0, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final trafficLightIconsLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!trafficLightIconsLayerExists) {
      await mapController.style.addLayerAt(
        mapbox.CircleLayer(
          sourceId: sourceId,
          id: layerId,
          circleRadius: iconSize * 10,
          circleColor: Colors.black.value,
          circleOpacity: 1,
        ),
        mapbox.LayerPosition(at: at),
      );
    }
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class AllTrafficLightsPredictionLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "all-traffic-lights-predictions";

  /// The ID of the Mapbox layer.
  static const layerId = "all-traffic-lights-icons-predictions";

  /// The ID of the Mapbox countdown layer.
  static const countdownLayerId = "all-traffic-lights-predictions-countdown";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  AllTrafficLightsPredictionLayer({Map<String, dynamic>? propertiesBySgId, double? userBearing}) {
    final freeRide = getIt<FreeRide>();
    if (freeRide.sgs == null || freeRide.sgs!.isEmpty) return;
    if (freeRide.sgBearings == null || freeRide.sgBearings!.isEmpty) return;

    for (final sg in freeRide.subscriptions) {
      double opacity = 1.0;
      double size = 30;
      double textSize = 30;
      final Map<String, dynamic> properties = {
        "id": sg,
      };

      if (propertiesBySgId != null && propertiesBySgId.containsKey(sg)) {
        properties.addAll(propertiesBySgId[sg]);
        if (userBearing != null) {
          final sgBearing = freeRide.sgBearings![sg];
          final bearingDiff = (userBearing - sgBearing!).abs();
          final oHalf = 0.5 * opacity;
          final sHalf = 0.5 * size;
          final tsHalf = 0.5 * textSize;
          opacity = oHalf + oHalf * (1 - (bearingDiff / 360));
          size = sHalf + sHalf * (1 - (bearingDiff / 360));
          textSize = tsHalf + tsHalf * (1 - (bearingDiff / 360));
        }
      }

      properties["opacity"] = opacity;
      properties["size"] = size;
      properties["textSize"] = textSize;
      features.add(
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [freeRide.sgs![sg]!.longitude, freeRide.sgs![sg]!.latitude],
          },
          "properties": properties,
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final layerPredictionsCountdownExists = await mapController.style.styleLayerExists(countdownLayerId);
    if (!layerPredictionsCountdownExists) {
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: countdownLayerId,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 24,
          textColor: Colors.white.value,
          textAllowOverlap: true,
          textHaloColor: Colors.black.value,
          textHaloWidth: 1,
        ),
        mapbox.LayerPosition(at: at),
      );

      await mapController.style.setStyleLayerProperty(
          countdownLayerId,
          'text-field',
          jsonEncode([
            "case",
            ["has", "countdown"],
            ["get", "countdown"],
            "?"
          ]));

      await mapController.style.setStyleLayerProperty(
          countdownLayerId,
          'text-size',
          jsonEncode([
            "get",
            "textSize",
          ]));
      await mapController.style.setStyleLayerProperty(
          countdownLayerId,
          'text-opacity',
          jsonEncode([
            "get",
            "opacity",
          ]));
    }

    final trafficLightIconsLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!trafficLightIconsLayerExists) {
      await mapController.style.addLayerAt(
        mapbox.CircleLayer(
          sourceId: sourceId,
          id: layerId,
          circleRadius: 20,
          circleColor: Colors.white.value,
          circleStrokeColor: Colors.black.value,
          circleStrokeWidth: 1,
          circleOpacity: 1,
        ),
        mapbox.LayerPosition(at: at),
      );

      await mapController.style.setStyleLayerProperty(
        layerId,
        "circle-color",
        jsonEncode([
          "case",
          [
            "==",
            ["get", "greenNow"],
            false
          ],
          "#fa1e43",
          [
            "==",
            ["get", "greenNow"],
            true
          ],
          "#28cd50",
          "#000000",
        ]),
      );

      await mapController.style.setStyleLayerProperty(
          layerId,
          'circle-opacity',
          jsonEncode([
            "get",
            "opacity",
          ]));

      await mapController.style.setStyleLayerProperty(
          layerId,
          'circle-radius',
          jsonEncode([
            "get",
            "size",
          ]));
    }
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class AllTrafficLightsPredictionGeometryLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "all-traffic-lights-prediction-geometry-source";

  /// The ID of the Mapbox layer.
  static const layerId = "all-traffic-lights-predictions-geometry-layer";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  AllTrafficLightsPredictionGeometryLayer({Map<String, dynamic>? propertiesBySgId, double? userBearing}) {
    final freeRide = getIt<FreeRide>();
    if (freeRide.sgGeometries == null || freeRide.sgGeometries!.isEmpty) return;

    for (final sg in freeRide.subscriptions) {
      final Map<String, dynamic> properties = {
        "id": sg,
      };

      if (propertiesBySgId != null && propertiesBySgId.containsKey(sg)) {
        properties.addAll(propertiesBySgId[sg]);
      }
      features.add(
        {
          "type": "Feature",
          "geometry": freeRide.sgGeometries![sg],
          "properties": properties,
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final trafficLightLineLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!trafficLightLineLayerExists) {
      await mapController.style.addLayerAt(
        mapbox.LineLayer(
          sourceId: sourceId,
          id: layerId,
          lineWidth: 1,
        ),
        mapbox.LayerPosition(at: at),
      );

      await mapController.style.setStyleLayerProperty(
        layerId,
        "line-color",
        jsonEncode([
          "case",
          [
            "==",
            ["get", "greenNow"],
            false
          ],
          "#ff0000",
          [
            "==",
            ["get", "greenNow"],
            true
          ],
          "#00ff00",
          "#000000",
        ]),
      );
    }
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}
