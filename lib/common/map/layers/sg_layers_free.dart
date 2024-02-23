import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/free_ride.dart';

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
      // Max opacity
      double opacity = 0.8;
      // Max size
      double size = 0.5;
      // Max text size
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
          final tsHalf = 0.5 * textSize;
          final sHalf = size * 0.5;
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

    final trafficLightIconsLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!trafficLightIconsLayerExists) {
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: layerId,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
          iconSize: 0.25,
          iconAllowOverlap: true,
          textAllowOverlap: true,
          textIgnorePlacement: true,
          minZoom: 10.0,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 24,
          textColor: Colors.white.value,
          textHaloColor: Colors.black.value,
          textHaloWidth: 1,
          textAnchor: mapbox.TextAnchor.BOTTOM,
          textOffset: [0, -1],
        ),
        mapbox.LayerPosition(at: at),
      );

      await mapController.style.setStyleLayerProperty(
        layerId,
        "icon-image",
        jsonEncode([
          "case",
          [
            "==",
            ["get", "greenNow"],
            false
          ],
          "free-ride-red",
          [
            "==",
            ["get", "greenNow"],
            true
          ],
          "free-ride-green",
          "free-ride-none-light",
        ]),
      );

      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-opacity',
          jsonEncode([
            "get",
            "opacity",
          ]));

      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-size',
          jsonEncode([
            "get",
            "size",
          ]));

      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-field',
          jsonEncode([
            "case",
            ["has", "countdown"],
            ["get", "countdown"],
            "?"
          ]));

      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-size',
          jsonEncode([
            "get",
            "textSize",
          ]));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-opacity',
          jsonEncode([
            "get",
            "opacity",
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
