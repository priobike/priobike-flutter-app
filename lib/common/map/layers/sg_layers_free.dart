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

  /// The ID of the Mapbox countdown layer.
  static const countdownLayerId = "all-traffic-lights-countdown";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  AllTrafficLightsLayer({Map<String, dynamic>? propertiesBySgId}) {
    final freeRide = getIt<FreeRide>();
    if (freeRide.sgs == null || freeRide.sgs!.isEmpty) return;

    for (final entry in freeRide.sgs!.entries) {
      final Map<String, dynamic> properties = {
        "id": entry.key,
      };

      if (propertiesBySgId != null && propertiesBySgId.containsKey(entry.key)) {
        properties.addAll(propertiesBySgId[entry.key]);
      }
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
          circleColor: Colors.white.value,
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

    final layerPredictionsCountdownExists = await mapController.style.styleLayerExists(countdownLayerId);
    if (!layerPredictionsCountdownExists) {
      await mapController.style.addLayer(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: countdownLayerId,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textColor: Colors.white.value,
          textAllowOverlap: true,
          textHaloColor: Colors.black.value,
          textHaloWidth: 1,
        ),
      );

      await mapController.style.setStyleLayerProperty(
          countdownLayerId,
          'text-field',
          jsonEncode(
            ["get", "countdown"],
          ));
      await mapController.style.setStyleLayerProperty(
          countdownLayerId,
          'text-opacity',
          jsonEncode(
            [
              "interpolate",
              ["linear"],
              ["zoom"],
              0,
              0,
              16,
              0,
              17,
              0.75,
            ],
          ));
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
