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
      double size = 0.5;
      // Max text size
      double textSize = 30;
      final Map<String, dynamic> properties = {
        "id": sg,
      };

      if (propertiesBySgId != null && propertiesBySgId.containsKey(sg)) {
        properties.addAll(propertiesBySgId[sg]);
      }

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
          textHaloColor: const Color.fromARGB(255, 31, 31, 31).value,
          textHaloWidth: 0.75,
          textAnchor: mapbox.TextAnchor.BOTTOM,
          textOffset: [0, -1],
          textOpacity: 1,
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

  /// The ID of the chevron layer.
  static const layerIdChevrons = "all-traffic-lights-predictions-geometry-layer-chevrons";

  /// The ID of the Mapbox layer.
  static const layerId = "all-traffic-lights-predictions-geometry-layer";

  /// The ID of the background layer.
  static const layerIdBackground = "all-traffic-lights-predictions-geometry-layer-background";

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

    final trafficLightLineChevronLayerExists = await mapController.style.styleLayerExists(layerIdChevrons);
    if (!trafficLightLineChevronLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerIdChevrons,
            symbolPlacement: mapbox.SymbolPlacement.LINE,
            symbolSpacing: 0,
            iconSize: 1,
            iconAllowOverlap: true,
            iconOpacity: 0.6,
            iconIgnorePlacement: true,
            iconRotate: 90,
            iconImage: "routechevrondark",
          ),
          mapbox.LayerPosition(at: at));

      await mapController.style.setStyleLayerProperty(
          layerIdChevrons,
          'icon-opacity',
          jsonEncode([
            "get",
            "opacity",
          ]));
    }

    final trafficLightLineLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!trafficLightLineLayerExists) {
      await mapController.style.addLayerAt(
        mapbox.LineLayer(
          sourceId: sourceId,
          id: layerId,
          lineJoin: mapbox.LineJoin.ROUND,
          lineCap: mapbox.LineCap.ROUND,
          lineWidth: 20,
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
          "#f30034",
          [
            "==",
            ["get", "greenNow"],
            true
          ],
          "#30c73f",
          "#000000",
        ]),
      );

      await mapController.style.setStyleLayerProperty(
          layerId,
          'line-opacity',
          jsonEncode([
            "get",
            "opacity",
          ]));
    }

    final trafficLightLineBackgroundLayerExists = await mapController.style.styleLayerExists(layerIdBackground);
    if (!trafficLightLineBackgroundLayerExists) {
      await mapController.style.addLayerAt(
        mapbox.LineLayer(
          sourceId: sourceId,
          id: layerIdBackground,
          lineJoin: mapbox.LineJoin.ROUND,
          lineCap: mapbox.LineCap.ROUND,
          lineWidth: 24,
          lineColor: const Color.fromARGB(255, 31, 31, 31).value,
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
