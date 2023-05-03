import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
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
    for (MapEntry<int, Route> entry in routing.allRoutes?.asMap().entries ?? []) {
      final geometry = {
        "type": "LineString",
        "coordinates": entry.value.route.map((e) => [e.lon, e.lat]).toList(),
      };
      features.add(
        {
          "id": "route-${entry.key}", // Required for click listener.
          "type": "Feature",
          "geometry": geometry,
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<String> install(
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
            lineWidth: lineWidth,
          ),
          mapbox.LayerPosition(below: layerIdClick));
    }

    return layerId;
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
  Future<String> install(mapbox.MapboxMap mapController, {bgLineWidth = 9.0, fgLineWidth = 7.0, at = 0}) async {
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
    return layerId;
  }

  update(mapbox.MapboxMap mapController, {String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class RouteLabelLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  /// The ID of the Mapbox source.
  static const sourceId = "route-label";

  /// The ID of the main Mapbox layer.
  static const layerId = "route-label-layer";

  RouteLabelLayer(List<Map> chosenCoordinates) {
    final routing = getIt<Routing>();

    // // Conditions for having route labels. Limited to 2 route alternatives.
    if (routing.allRoutes != null && routing.allRoutes!.length == 2 && routing.selectedRoute != null) {
      // Determine the relation between the chosenCoordinate.
      // Will be calculated for 2 coordinates only.
      if (chosenCoordinates.length != 2) return;
      final GHCoordinate coordinate1 = chosenCoordinates[0]["coordinate"];
      final GHCoordinate coordinate2 = chosenCoordinates[1]["coordinate"];

      final coordinates = routing.allRoutes![0].path.points.coordinates;

      // Prerequisite that location is hamburg and therefore only positive lat and lon values.
      // Also orientation is lon: the greater the further right, lat: the greater the more top.
      final double diffLat = coordinate1.lat - coordinate2.lat;
      final double diffLon = coordinate1.lon - coordinate2.lon;

      final double diffLatRoute = (coordinates[0].lat - coordinates[coordinates.length - 1].lat).abs();
      final double diffLonRoute = (coordinates[0].lon - coordinates[coordinates.length - 1].lon).abs();

      String coordinate1Orientation = "left"; //Standard orientation.
      String coordinate2Orientation = "right"; //Standard orientation.

      coordinate1Orientation = calculateOrientation(diffLat, diffLon, diffLatRoute, diffLonRoute, true);
      coordinate2Orientation = calculateOrientation(diffLat, diffLon, diffLatRoute, diffLonRoute, false);

      // Set the correct image and text offset.
      chosenCoordinates[0]["feature"]["properties"]["imageSource"] =
          "route-label-${chosenCoordinates[0]["feature"]["properties"]["isPrimary"] ? "primary" : "secondary"}-$coordinate1Orientation";
      chosenCoordinates[0]["feature"]["properties"]["textOffset"] =
          getTextOffsetFromOrientation(coordinate1Orientation, chosenCoordinates[0]["time"].toString().length);
      chosenCoordinates[0]["feature"]["properties"]["anchor"] = coordinate1Orientation;

      chosenCoordinates[1]["feature"]["properties"]["imageSource"] =
          "route-label-${chosenCoordinates[1]["feature"]["properties"]["isPrimary"] ? "primary" : "secondary"}-$coordinate2Orientation";
      chosenCoordinates[1]["feature"]["properties"]["textOffset"] =
          getTextOffsetFromOrientation(coordinate2Orientation, chosenCoordinates[1]["time"].toString().length);
      chosenCoordinates[1]["feature"]["properties"]["anchor"] = coordinate2Orientation;

      // Adding feature to feature list.
      features.add(chosenCoordinates[0]["feature"]);
      features.add(chosenCoordinates[1]["feature"]);
    }
  }

  /// Install the overlay on the layer controller.
  Future<String> install(
    mapbox.MapboxMap mapController, {
    iconSize = 0.4,
    textSize = 14.0,
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

    final routeLabelsLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!routeLabelsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerId,
            iconSize: iconSize,
            iconOpacity: 0,
            textOpacity: 0,
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
            textSize: textSize,
            textAllowOverlap: true,
            textIgnorePlacement: true,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(layerId, 'icon-image', json.encode(["get", "imageSource"]));
      await mapController.style.setStyleLayerProperty(layerId, 'icon-opacity', json.encode(showAfter(zoom: 10)));
      await mapController.style.setStyleLayerProperty(layerId, 'icon-anchor', json.encode(["get", "anchor"]));
      await mapController.style.setStyleLayerProperty(layerId, 'text-anchor', json.encode(["get", "anchor"]));
      await mapController.style.setStyleLayerProperty(layerId, 'text-field', json.encode(["get", "text"]));
      await mapController.style.setStyleLayerProperty(layerId, 'text-offset', json.encode(["get", "textOffset"]));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-color',
          json.encode([
            "case",
            ["get", "isPrimary"],
            "#ffffff",
            "#000000"
          ]));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-opacity',
          json.encode(
            showAfter(zoom: 10),
          ));
    }

    return layerId;
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }

  /// Returns the orientation of the route label.
  String calculateOrientation(diffLat, diffLon, routeDiffLat, routeDiffLon, isFirst) {
    if (routeDiffLat < routeDiffLon) {
      // Case route is more horizontal.
      // Only consider top and bottom.
      if (diffLat > 0 && isFirst || diffLat < 0 && !isFirst) {
        // C1 is above of C2.
        return "bottom";
      } else {
        return "top";
      }
    } else {
      // Case route is more vertical.
      // Only consider left and right.
      if (diffLon > 0 && isFirst || diffLon < 0 && !isFirst) {
        // C1 is right of C2.
        return "left";
      } else {
        return "right";
      }
    }
  }

  /// Returns the text offset of the route label.
  List<double> getTextOffsetFromOrientation(String orientation, int digits) {
    // Careful: values may need to be adjusted on size changes to the route label.
    switch (orientation) {
      case "top":
        return [0, 1.0];
      case "bottom":
        return [0, -1.1];
      case "left":
        return [1.6 - (0.3 * (digits - 1)), 0]; // 1.0 for 3 digits, 1.3 for 2 digits, 1.6 for 1 digit.
      case "right":
        return [-1.7 + (0.3 * (digits - 1)), 0]; // -1.1 for 3 digits, -1.4 for 2 digits, -1.7 for 1 digit.
    }
    return [1.5, 0];
  }
}

class DiscomfortsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "discomforts";

  /// The ID of the main Mapbox layer.
  static const layerId = "discomforts-layer";

  /// The ID of the click Mapbox layer.
  static const layerIdClick = "discomforts-clicklayer";

  /// The ID of the marker Mapbox layer.
  static const layerIdMarker = "discomforts-markers";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  DiscomfortsLayer() {
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
          "id": "discomfort-${e.key}", // Required for click listener.
          "type": "Feature",
          "properties": {
            "number": e.key + 1,
          },
          "geometry": geometry,
        },
      );
    }
  }

  /// Install the overlay on the layer controller.
  Future<String> install(
    mapbox.MapboxMap mapController, {
    iconSize = 0.25,
    lineWidth = 7.0,
    clickWidth = 35.0,
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
    final discomfortsClickLayerExists = await mapController.style.styleLayerExists(layerIdClick);
    if (!discomfortsClickLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: sourceId,
            id: layerIdClick,
            lineColor: Colors.pink.value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineWidth: clickWidth,
            lineOpacity: 0.001,
          ),
          mapbox.LayerPosition(at: at));
    }
    final discomfortsLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!discomfortsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: sourceId,
            id: layerId,
            lineColor: const Color(0xFFE63328).value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineWidth: lineWidth,
          ),
          mapbox.LayerPosition(at: at));
    }
    final discomfortsMarkersExist = await mapController.style.styleLayerExists(layerIdMarker);
    if (!discomfortsMarkersExist) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerIdMarker,
            iconImage: "alert",
            iconSize: iconSize,
            iconAllowOverlap: true,
            textSize: 12,
            textAllowOverlap: true,
            textIgnorePlacement: true,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(layerIdMarker, 'text-field', json.encode(["get", "number"]));
    }
    return layerId;
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
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 0.75, at = 0}) async {
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

    return layerId;
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
