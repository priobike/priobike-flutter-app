import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/status/services/sg.dart';

class AllRoutesLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "routes";

  /// The ID of the main Mapbox layer.
  static const layerId = "routes-layer";

  /// The ID of the click Mapbox layer.
  static const layerIdClick = "routes-clicklayer";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  AllRoutesLayer() {
    final routing = getIt<Routing>();
    if (routing.allRoutes == null) return;

    for (Route route in routing.allRoutes!) {
      if (routing.selectedRoute!.id == route.id) continue;
      final navNodes = route.route;

      final status = getIt<PredictionSGStatus>();
      Map<String, dynamic>? currentFeature;
      for (int i = navNodes.length - 1; i >= 0; i--) {
        final navNode = navNodes[i];
        final sgStatus = status.cache[navNode.signalGroupId];

        var q = min(1, max(0, sgStatus?.predictionQuality ?? 0));
        // If the status is not "ok" (e.g. if the prediction is too old), set the quality to 0.
        if (sgStatus?.predictionState != SGPredictionState.ok) q = 0;
        // Interpolate between green and blue, by the prediction quality.

        Color color = Color.fromRGBO(
            (0 * q + 0 * (1 - q)).round(), (255 * q + 115 * (1 - q)).round(), (106 * q + 255 * (1 - q)).round(), 1);

        final colorHSL = HSLColor.fromColor(color);
        color = HSLColor.fromColor(color).withSaturation(colorHSL.saturation * 0.33).toColor();

        String colorString = "rgb(${color.red}, ${color.green}, ${color.blue})";

        if (currentFeature == null || currentFeature["color"] != color) {
          if (currentFeature != null) {
            currentFeature["geometry"]["coordinates"].add([navNode.lon, navNode.lat]);
            features.add(currentFeature);
          }
          currentFeature = {
            "type": "Feature",
            "properties": {
              "color": colorString,
            },
            "geometry": {
              "type": "LineString",
              "coordinates": [
                [navNode.lon, navNode.lat]
              ],
            },
          };
        } else {
          currentFeature["geometry"]["coordinates"].add([navNode.lon, navNode.lat]);
        }
      }
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(
    mapbox.MapboxMap mapController, {
    lineWidth = 9.0,
    clickLineWidth = 25.0,
    at = 0,
  }) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }
    // Add another layer that makes it easier to click on the route.
    final routeClickLayerExists = await mapController.style.styleLayerExists(layerIdClick);
    if (!routeClickLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: sourceId,
            id: layerIdClick,
            lineColor: Colors.pink.value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineWidth: clickLineWidth,
            lineOpacity: 0.001,
          ),
          mapbox.LayerPosition(at: at));
    }
    final routesLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!routesLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: sourceId,
            id: layerId,
            lineColor: const Color(0xFFC6C6C6).value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineWidth: lineWidth,
          ),
          mapbox.LayerPosition(at: at));
    }

    await mapController.style.setStyleLayerProperty(layerId, 'line-color', json.encode(["get", "color"]));
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

class SelectedRouteLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "route";

  /// The ID of the main Mapbox layer.
  static const layerId = "route-layer";

  /// The ID of the background Mapbox layer.
  static const layerIdBackground = "route-background-layer";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  SelectedRouteLayer() {
    final routing = getIt<Routing>();
    final navNodes = routing.selectedRoute?.route ?? [];

    final status = getIt<PredictionSGStatus>();
    Map<String, dynamic>? currentFeature;
    for (int i = navNodes.length - 1; i >= 0; i--) {
      final navNode = navNodes[i];
      final sgStatus = status.cache[navNode.signalGroupId];
      String color;
      var q = min(1, max(0, sgStatus?.predictionQuality ?? 0));
      // If the status is not "ok" (e.g. if the prediction is too old), set the quality to 0.
      if (sgStatus?.predictionState != SGPredictionState.ok) q = 0;
      // Interpolate between green and blue, by the prediction quality.
      color = "rgb(${(0 * q + 0 * (1 - q)).round()}, ${255 * q + 115 * (1 - q)}, ${106 * q + 255 * (1 - q)})";
      if (currentFeature == null || currentFeature["color"] != color) {
        if (currentFeature != null) {
          currentFeature["geometry"]["coordinates"].add([navNode.lon, navNode.lat]);
          features.add(currentFeature);
        }
        currentFeature = {
          "type": "Feature",
          "properties": {
            "color": color,
          },
          "geometry": {
            "type": "LineString",
            "coordinates": [
              [navNode.lon, navNode.lat]
            ],
          },
        };
      } else {
        currentFeature["geometry"]["coordinates"].add([navNode.lon, navNode.lat]);
      }
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {bgLineWidth = 9.0, fgLineWidth = 7.0, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }
    final routeLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!routeLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: sourceId,
            id: layerId,
            lineColor: const Color(0xFFC6C6C6).value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineWidth: fgLineWidth,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(layerId, 'line-color', json.encode(["get", "color"]));
    }
    final routeBackgroundLayerExists = await mapController.style.styleLayerExists(layerIdBackground);
    if (!routeBackgroundLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: sourceId,
            id: layerIdBackground,
            lineColor: const Color(0xFFC6C6C6).value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineWidth: bgLineWidth,
          ),
          mapbox.LayerPosition(at: at));
    }
  }

  update(mapbox.MapboxMap mapController, {String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class DiscomfortsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "discomforts";

  /// The ID of the marker Mapbox layer.
  static const layerIdMarker = "discomforts-markers";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  DiscomfortsLayer(this.isDark) {
    final discomforts = getIt<Discomforts>().foundDiscomforts;
    for (MapEntry<int, DiscomfortSegment> e in discomforts?.asMap().entries ?? []) {
      if (e.value.coordinates.isEmpty) continue;
      // A section of the route.
      final geometry = {
        "type": "LineString",
        "coordinates": e.value.coordinates.map((e) => [e.longitude, e.latitude]).toList(),
      };

      features.add(
        {
          "type": "Feature",
          "properties": {
            "description": e.value.description,
            "color": "#003064",
          },
          "geometry": geometry,
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(
    mapbox.MapboxMap mapController, {
    showLabels = true,
    iconSize = 0.25,
    lineWidth = 5.0,
    at = 0,
  }) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }
    if (showLabels) {
      final discomfortsMarkersExist = await mapController.style.styleLayerExists(layerIdMarker);
      if (!discomfortsMarkersExist) {
        await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerIdMarker,
            iconImage: "dangerspot",
            iconSize: iconSize,
            iconAllowOverlap: true,
            iconOpacity: 1,
            textHaloColor: isDark ? const Color(0xFF003064).value : const Color(0xFFFFFFFF).value,
            textColor: isDark ? const Color(0xFFFFFFFF).value : const Color(0xFF003064).value,
            textHaloWidth: 0.2,
            textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
            textSize: 12,
            textAnchor: mapbox.TextAnchor.CENTER,
            textAllowOverlap: true,
            textOpacity: 1,
          ),
          mapbox.LayerPosition(at: at),
        );
        await mapController.style.setStyleLayerProperty(
            layerIdMarker,
            'text-offset',
            json.encode(
              [
                "literal",
                [0, 1]
              ],
            ));
        await mapController.style
            .setStyleLayerProperty(layerIdMarker, 'text-field', json.encode(["get", "description"]));
        await mapController.style.setStyleLayerProperty(
            layerIdMarker,
            'text-opacity',
            json.encode(
              showAfter(zoom: 11),
            ));
        await mapController.style.setStyleLayerProperty(
            layerIdMarker,
            'icon-opacity',
            json.encode(
              showAfter(zoom: 11),
            ));
      }
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

class WaypointsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "waypoints";

  /// The ID of the Mapbox layer.
  static const layerId = "waypoints-icons";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  WaypointsLayer() {
    final routing = getIt<Routing>();
    final waypoints = routing.selectedWaypoints ?? [];
    for (MapEntry<int, Waypoint> entry in waypoints.asMap().entries) {
      features.add(
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [entry.value.lon, entry.value.lat],
          },
          "properties": {
            "isFirst": entry.key == 0,
            "isLast": entry.key == waypoints.length - 1,
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {iconSize = 0.75, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }
    final waypointsIconsLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!waypointsIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
              sourceId: sourceId,
              id: layerId,
              iconSize: iconSize,
              textAllowOverlap: true,
              textIgnorePlacement: true,
              iconAllowOverlap: true),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-image',
          json.encode([
            "case",
            ["get", "isFirst"],
            "start",
            ["get", "isLast"],
            "destination",
            "waypoint",
          ]));
    }
  }

  /// Update the overlay on the layer controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}
