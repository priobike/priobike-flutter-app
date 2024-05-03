import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/poi.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/waypoint.dart';
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
      final navNodes = route.route;

      final status = getIt<PredictionSGStatus>();
      Map<String, dynamic>? currentFeature;
      for (int i = navNodes.length - 1; i >= 0; i--) {
        final navNode = navNodes[i];
        final sgStatus = status.cache[navNode.signalGroupId];

        var q = min(1, max(0, sgStatus?.predictionQuality ?? 0));
        // If the status is not "ok" (e.g. if the prediction is too old), set the quality to 0.
        if (sgStatus?.predictionState != SGPredictionState.ok) q = 0;
        // Interpolate between green and grey, by the prediction quality.

        Color color = Color.fromRGBO(
            (0 * q + 198 * (1 - q)).round(), (255 * q + 198 * (1 - q)).round(), (106 * q + 198 * (1 - q)).round(), 1);

        final colorHSL = HSLColor.fromColor(color);
        color = colorHSL.withSaturation(colorHSL.saturation * 0.25).toColor();

        String colorString = "rgb(${color.red}, ${color.green}, ${color.blue})";

        if (currentFeature == null || currentFeature["color"] != color) {
          if (currentFeature != null) {
            currentFeature["geometry"]["coordinates"].add([navNode.lon, navNode.lat]);
            features.add(currentFeature);
          }
          currentFeature = {
            "id": "route-${route.idx}", // Required for click listener.
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

class HashableLatLng {
  final LatLng coord;

  HashableLatLng(this.coord);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HashableLatLng &&
        other.runtimeType == runtimeType &&
        other.coord.longitude == coord.longitude &&
        other.coord.latitude == coord.latitude;
  }

  @override
  int get hashCode => Object.hash(coord.longitude, coord.latitude);
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

  /// If the layer should show the status of the predictions.
  final bool showStatus;

  /// Get the color for the status.
  String getStatusColor(PredictionSGStatus status, NavigationNode navNode) {
    final sgStatus = status.cache[navNode.signalGroupId];
    String color;
    var q = min(1, max(0, sgStatus?.predictionQuality ?? 0));
    // If the status is not "ok" (e.g. if the prediction is too old), set the quality to 0.
    if (sgStatus?.predictionState != SGPredictionState.ok) q = 0;
    // Interpolate between green and blue, by the prediction quality.
    color = "rgb(${(0 * q + 0 * (1 - q)).round()}, ${255 * q + 115 * (1 - q)}, ${106 * q + 255 * (1 - q)})";
    return color;
  }

  SelectedRouteLayer({this.showStatus = false}) {
    final routing = getIt<Routing>();
    final navNodes = routing.selectedRoute?.route ?? [];

    final status = showStatus ? getIt<PredictionSGStatus>() : null;
    Map<String, dynamic>? currentFeature;
    for (int i = navNodes.length - 1; i >= 0; i--) {
      final navNode = navNodes[i];
      final color = status != null ? getStatusColor(status, navNode) : CI.route.value;
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
            lineColor: CI.route.value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineWidth: fgLineWidth,
          ),
          mapbox.LayerPosition(at: at));
      if (showStatus) {
        await mapController.style.setStyleLayerProperty(layerId, 'line-color', json.encode(["get", "color"]));
      }
    }
    final routeBackgroundLayerExists = await mapController.style.styleLayerExists(layerIdBackground);
    if (!routeBackgroundLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: sourceId,
            id: layerIdBackground,
            lineColor: CI.routeBackground.value,
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

class PoisLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "route-pois";

  /// The ID of the main Mapbox layer.
  static const layerId = "route-pois-layer";

  /// The ID of the background Mapbox layer.
  static const layerIdBackground = "route-pois-background-layer";

  /// The ID of the symbol/text layer.
  static const layerIdSymbol = "route-pois-symbol-layer";

  /// The ID of the text POI count layer.
  static const layerIdCount = "route-pois-count-layer";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  PoisLayer(this.isDark) {
    final routing = getIt<Routing>();

    // Alternative routes
    if (routing.allRoutes == null) return;
    for (final route in routing.allRoutes!) {
      if (route.idx == routing.selectedRoute?.idx) continue;
      if (route.foundPois == null) continue;
      for (final poi in route.foundPois!) {
        if (!poi.isWarning) continue; // Don't display pois that are not warnings.
        if (poi.coordinates.isEmpty) continue;
        // A section of the route.
        final geometry = {
          "type": "LineString",
          "coordinates": poi.coordinates.map((point) => [point.longitude, point.latitude]).toList(),
        };

        features.add(
          {
            "type": "Feature",
            "properties": {
              "color": "#d9c89e",
              "bgcolor": "#d1b873",
              "symbol": poi.type.mapboxIcon,
              "symbolopacity": 0,
            },
            "geometry": geometry,
          },
        );
      }
    }

    // Selected route
    if (routing.selectedRoute == null) return;
    if (routing.selectedRoute?.foundWarningPoisAggregated == null) return;
    for (final poi in routing.selectedRoute!.foundWarningPoisAggregated!) {
      if (!poi.isWarning) continue; // Don't display pois that are not warnings.
      if (poi.coordinates.isEmpty) continue;
      // A section of the route.
      final geometry = {
        "type": "LineString",
        "coordinates": poi.coordinates.map((point) => [point.longitude, point.latitude]).toList(),
      };

      features.add(
        {
          "type": "Feature",
          "properties": {
            "description": poi.description,
            "color": "#ffdc00",
            "bgcolor": "#ad9600",
            "symbol": poi.type.mapboxIcon,
            "symbolopacity": 1,
            "poiCount": poi.poiCount > 1 ? poi.poiCount : "",
          },
          "geometry": geometry,
        },
      );
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
    final poiCountLayerExists = await mapController.style.styleLayerExists(layerIdCount);
    if (!poiCountLayerExists) {
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: layerIdCount,
          textHaloColor: const Color(0xFFFFFFFF).value,
          textColor: const Color(0xFF003064).value,
          textHaloWidth: 0.2,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textAnchor: mapbox.TextAnchor.CENTER,
          textAllowOverlap: true,
          textIgnorePlacement: true,
          textOpacity: 1,
          minZoom: 9.0,
        ),
        mapbox.LayerPosition(at: at),
      );
      await mapController.style.setStyleLayerProperty(
          layerIdCount,
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 0.1]
            ],
          ));
      await mapController.style.setStyleLayerProperty(layerIdCount, 'text-field', json.encode(["get", "poiCount"]));
      await mapController.style.setStyleLayerProperty(
          layerIdCount,
          'text-opacity',
          json.encode(
            showAfter(zoom: 16),
          ));
    }
    final routePoisSymbolLayerExists = await mapController.style.styleLayerExists(layerIdSymbol);
    if (!routePoisSymbolLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerIdSymbol,
            iconSize: 0.15,
            iconAllowOverlap: true,
            iconOpacity: 1,
            textHaloColor: isDark ? const Color(0xFF003064).value : const Color(0xFFFFFFFF).value,
            textColor: isDark ? const Color(0xFFFFFFFF).value : const Color(0xFF003064).value,
            textHaloWidth: 0.2,
            textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
            textSize: 12,
            textAnchor: mapbox.TextAnchor.CENTER,
            textAllowOverlap: true,
            textIgnorePlacement: true,
            textOpacity: 1,
            minZoom: 9.0,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(layerIdSymbol, 'icon-image', json.encode(["get", "symbol"]));
      await mapController.style
          .setStyleLayerProperty(layerIdSymbol, 'icon-opacity', json.encode(["get", "symbolopacity"]));
      await mapController.style.setStyleLayerProperty(
          layerIdSymbol,
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 2]
            ],
          ));
      await mapController.style.setStyleLayerProperty(layerIdSymbol, 'text-field', json.encode(["get", "description"]));
      await mapController.style.setStyleLayerProperty(
          layerIdSymbol,
          'text-opacity',
          json.encode(
            showAfter(zoom: 16),
          ));
    }
    final routePoisLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!routePoisLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: sourceId,
            id: layerId,
            lineColor: const Color.fromARGB(255, 0, 0, 0).value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineWidth: fgLineWidth,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(layerId, 'line-color', json.encode(["get", "color"]));
    }
    final routePoisBackgroundLayerExists = await mapController.style.styleLayerExists(layerIdBackground);
    if (!routePoisBackgroundLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: sourceId,
            id: layerIdBackground,
            lineColor: const Color.fromARGB(255, 0, 0, 0).value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineWidth: bgLineWidth,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(layerIdBackground, 'line-color', json.encode(["get", "bgcolor"]));
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

class WaypointsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "waypoints";

  /// The ID of the Mapbox layer.
  static const layerId = "waypoints-icons";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  /// If a waypoint is tapped and needs highlighting.
  int? tappedWaypointIdx;

  WaypointsLayer({this.tappedWaypointIdx}) {
    final routing = getIt<Routing>();
    final waypoints = routing.selectedWaypoints ?? [];
    for (MapEntry<int, Waypoint> entry in waypoints.asMap().entries) {
      features.add(
        {
          "id": "waypoint-${entry.key}",
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [entry.value.lon, entry.value.lat],
          },
          "properties": {
            "isFirst": entry.key == 0,
            "isLast": entry.key == waypoints.length - 1,
            "idx": entry.key + 1,
            "editing": tappedWaypointIdx == entry.key
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {iconSize = 0.75, at = 0, textSize = 12.0}) async {
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
            iconAllowOverlap: true,
            textColor: const Color(0xFF003064).value,
            textFont: ['DIN Offc Pro Bold', 'Arial Unicode MS Bold'],
            textSize: textSize,
            textAnchor: mapbox.TextAnchor.CENTER,
            textOpacity: 1,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.addLayerAt(
          mapbox.CircleLayer(
              sourceId: sourceId,
              id: "$layerId-circle",
              circleOpacity: 0.0,
              circleColor: CI.route.value,
              circleBlur: 0.4,
              circleRadius: 16),
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
      // Only show idx label if it's not the first or last waypoint, otherwise show blank text
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-field',
          json.encode([
            "case",
            ["get", "isFirst"],
            "",
            ["get", "isLast"],
            "",
            ["get", "idx"],
          ]));
      // If this waypoint is being edited add a circle layer as selection.
      await mapController.style.setStyleLayerProperty(
          "$layerId-circle",
          'circle-opacity',
          json.encode([
            "case",
            ["get", "editing"],
            0.66,
            0,
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

class RoutePreviewLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "route-preview";

  /// The ID of the main Mapbox layer.
  static const layerId = "route-preview-layer";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  /// The coordinate of the added position.
  final LatLng? addedPosition;

  /// The coordinate of the snapped waypoint on the route.
  final LatLng? snappedWaypoint;

  /// The coordinate of the snapped second waypoint on the route.
  final LatLng? snappedSecondWaypoint;

  RoutePreviewLayer({this.addedPosition, this.snappedWaypoint, this.snappedSecondWaypoint}) {
    if (addedPosition != null && snappedWaypoint != null) {
      features.add(
        {
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": [
              [addedPosition!.longitude, addedPosition!.latitude],
              [snappedWaypoint!.longitude, snappedWaypoint!.latitude]
            ],
          },
        },
      );
    }

    if (addedPosition != null && snappedSecondWaypoint != null) {
      features.add(
        {
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": [
              [addedPosition!.longitude, addedPosition!.latitude],
              [snappedSecondWaypoint!.longitude, snappedSecondWaypoint!.latitude]
            ],
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {fgLineWidth = 3.5, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }
    final routePreviewLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!routePreviewLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
              sourceId: sourceId,
              id: layerId,
              lineColor: CI.route.value,
              lineJoin: mapbox.LineJoin.ROUND,
              lineCap: mapbox.LineCap.ROUND,
              lineWidth: fgLineWidth,
              lineDasharray: [0.25, 1.5]),
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
