import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/status/services/sg.dart';

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

List<double> getTextOffsetFromOrientation(String orientation) {
  switch (orientation) {
    case "top":
      return [0, 1];
    case "bottom":
      return [0, -1];
    case "left":
      return [1.5, 0];
    case "right":
      return [-1.5, 0];
  }
  return [1.5, 0];
}

class AllRoutesLayer {
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
    String? below,
  }) async {
    final sourceExists = await mapController.style.styleSourceExists("routes");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "routes", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }
    // Add another layer that makes it easier to click on the route.
    final routeClickLayerExists = await mapController.style.styleLayerExists("routes-clicklayer");
    if (!routeClickLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: "routes",
            id: "routes-clicklayer",
            lineColor: Colors.pink.value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineWidth: clickLineWidth,
            lineOpacity: 0.001,
          ),
          mapbox.LayerPosition(below: below));
    }
    final routesLayerExists = await mapController.style.styleLayerExists("routes-layer");
    if (!routesLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: "routes",
            id: "routes-layer",
            lineColor: const Color(0xFFC6C6C6).value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineWidth: lineWidth,
          ),
          mapbox.LayerPosition(below: "routes-clicklayer"));
    }

    return "routes-layer";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists("routes");
    if (sourceExists) {
      final source = await mapController.style.getSource("routes");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class SelectedRouteLayer {
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
  Future<String> install(mapbox.MapboxMap mapController, {bgLineWidth = 9.0, fgLineWidth = 7.0, String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists("route");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "route", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }
    final routeBackgroundLayerExists = await mapController.style.styleLayerExists("route-background-layer");
    if (!routeBackgroundLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: "route",
            id: "route-background-layer",
            lineColor: const Color(0xFFC6C6C6).value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineWidth: bgLineWidth,
          ),
          mapbox.LayerPosition(below: below));
    }
    final routeLayerExists = await mapController.style.styleLayerExists("route-layer");
    if (!routeLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: "route",
            id: "route-layer",
            lineColor: const Color(0xFFC6C6C6).value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineWidth: fgLineWidth,
          ),
          mapbox.LayerPosition(below: below));
      await mapController.style.setStyleLayerProperty("route-layer", 'line-color', json.encode(["get", "color"]));
    }
    return "route-layer";
  }

  update(mapbox.MapboxMap mapController, {String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists("route");
    if (sourceExists) {
      final source = await mapController.style.getSource("route");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class RouteLabelLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  RouteLabelLayer(double deviceWidth, double deviceHeight, CameraState cameraState) {
    final routing = getIt<Routing>();

    // Conditions for having route labels. Limited to 2 route alternatives.
    if (routing.allRoutes != null && routing.allRoutes!.length == 2 && routing.selectedRoute != null) {
      var distance = const Distance();

      double meterPerPixel = zoomToGeographicalDistance[cameraState.zoom.toInt()] ?? 0;
      double cameraPosLat = (cameraState.center["coordinates"] as List)[1];
      double cameraPosLong = (cameraState.center["coordinates"] as List)[0];

      // Cast to LatLng2 format.
      LatLng cameraPos = LatLng(cameraPosLat, cameraPosLong);

      // Getting the bounds north, east, south, west.
      // Calculation of Bounding Points: Distance between camera position and the distance to the edge of the screen.
      LatLng north = distance.offset(cameraPos, deviceHeight / 2 * meterPerPixel, 0);
      LatLng east = distance.offset(cameraPos, deviceWidth / 2 * meterPerPixel, 90);
      LatLng south = distance.offset(cameraPos, deviceHeight / 2 * meterPerPixel, 180);
      LatLng west = distance.offset(cameraPos, deviceWidth / 2 * meterPerPixel, 270);

      bool allInBounds = true;
      // Check if current route labels are in bounds still.
      if (routing.routeLabelCoordinates.isNotEmpty) {
        for (Map data in routing.routeLabelCoordinates) {
          // Check out of new bounds.
          if (data["coordinate"].lat < south.latitude ||
              data["coordinate"].lat > north.latitude ||
              data["coordinate"].lon < west.longitude ||
              data["coordinate"].lon > east.longitude) {
            // Not in new bounds.
            allInBounds = false;
          }
        }
      }

      // If all in bounds then we don't have to calculate new positions.
      // But update route labels in case the selected route changed.
      if (allInBounds && routing.allRoutes!.length == routing.routeLabelCoordinates.length) {
        for (var i = 0; i < routing.allRoutes!.length; i++) {
          String imageSource = routing.routeLabelCoordinates[i]["feature"]["properties"]["imageSource"];
          // Check if the image source needs to change.
          if (routing.selectedRoute!.id == routing.allRoutes![i].id) {
            imageSource = imageSource.replaceFirst(RegExp(r'secondary'), "primary");
          } else {
            imageSource = imageSource.replaceFirst(RegExp(r'primary'), "secondary");
          }
          routing.routeLabelCoordinates[i]["feature"]["properties"]["isPrimary"] =
              routing.selectedRoute!.id == routing.allRoutes![i].id;
          routing.routeLabelCoordinates[i]["feature"]["properties"]["imageSource"] = imageSource;
          features.add(routing.routeLabelCoordinates[i]["feature"]);
        }
        return;
      }

      // Reset the old coordinates before adding the new ones.
      routing.resetRouteLabelCoords();
      // Chosen coordinates and feature object.
      List<Map> chosenCoordinates = [];

      // Search appropriate Point in Route
      for (r.Route route in routing.allRoutes!) {
        GHCoordinate? chosenCoordinate;
        List<GHCoordinate> uniqueInBounceCoordinates = [];

        // go through all coordinates.
        for (GHCoordinate coordinate in route.path.points.coordinates) {
          // Check if the coordinate is unique and not on the same line.
          bool unique = true;
          // Loop through all route coordinates.
          for (r.Route routeToBeChecked in routing.allRoutes!) {
            // Would always be not unique without this check.
            if (routeToBeChecked.id != route.id) {
              // Compare coordinate to all coordinates in other route.
              for (GHCoordinate coordinateToBeChecked in routeToBeChecked.path.points.coordinates) {
                if (!unique) {
                  break;
                }
                if (coordinateToBeChecked.lon == coordinate.lon && coordinateToBeChecked.lat == coordinate.lat) {
                  unique = false;
                }
              }
            }
          }

          if (unique) {
            // Check bounds, no check for side of earth needed since in Hamburg.
            if (coordinate.lat > south.latitude &&
                coordinate.lat < north.latitude &&
                coordinate.lon > west.longitude &&
                coordinate.lon < east.longitude) {
              uniqueInBounceCoordinates.add(coordinate);
            }
          }
        }

        // Determine which coordinate to use.
        if (uniqueInBounceCoordinates.isNotEmpty) {
          // Use the middlemost coordinate.
          chosenCoordinate = uniqueInBounceCoordinates[uniqueInBounceCoordinates.length ~/ 2];
        }

        if (chosenCoordinate != null) {
          chosenCoordinates.add({
            "coordinate": chosenCoordinate,
            "feature": {
              "id": "routeLabel-${route.id}", // Required for click listener.
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [chosenCoordinate.lon, chosenCoordinate.lat],
              },
              "properties": {
                "isPrimary": routing.selectedRoute!.id == route.id,
                "text": "${((route.path.time * 0.001) * 0.016).round()} min"
              },
            }
          });
        }
      }
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
          getTextOffsetFromOrientation(coordinate1Orientation);
      chosenCoordinates[0]["feature"]["properties"]["anchor"] = coordinate1Orientation;

      chosenCoordinates[1]["feature"]["properties"]["imageSource"] =
          "route-label-${chosenCoordinates[1]["feature"]["properties"]["isPrimary"] ? "primary" : "secondary"}-$coordinate2Orientation";
      chosenCoordinates[1]["feature"]["properties"]["textOffset"] =
          getTextOffsetFromOrientation(coordinate2Orientation);
      chosenCoordinates[1]["feature"]["properties"]["anchor"] = coordinate2Orientation;

      // Adding feature to feature list.
      features.add(chosenCoordinates[0]["feature"]);
      features.add(chosenCoordinates[1]["feature"]);

      // Adding data to routing label coordinates.
      routing.addRouteLabelCoords(
          GHCoordinate(lon: chosenCoordinates[0]["coordinate"].lon, lat: chosenCoordinates[0]["coordinate"].lat),
          chosenCoordinates[0]["feature"]);
      routing.addRouteLabelCoords(
          GHCoordinate(lon: chosenCoordinates[1]["coordinate"].lon, lat: chosenCoordinates[1]["coordinate"].lat),
          chosenCoordinates[1]["feature"]);
    }
  }

  /// Install the overlay on the layer controller.
  Future<String> install(
    mapbox.MapboxMap mapController, {
    iconSize = 0.75,
    String? below,
  }) async {
    final sourceExists = await mapController.style.styleSourceExists("routeLabels");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "routeLabels", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    // Make it easier to click on the route.
    final routeLabelsClickLayerExists = await mapController.style.styleLayerExists("routeLabels-clicklayer");
    if (!routeLabelsClickLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: "routeLabels",
            id: "routeLabels-clicklayer",
            iconSize: iconSize,
            iconOpacity: 0,
            textOpacity: 0,
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
            textSize: 12,
            textAllowOverlap: true,
            textIgnorePlacement: true,
          ),
          mapbox.LayerPosition(below: below));
      await mapController.style
          .setStyleLayerProperty("routeLabels-clicklayer", 'icon-image', json.encode(["get", "imageSource"]));
      await mapController.style
          .setStyleLayerProperty("routeLabels-clicklayer", 'icon-opacity', json.encode(showAfter(zoom: 10)));
      await mapController.style
          .setStyleLayerProperty("routeLabels-clicklayer", 'icon-anchor', json.encode(["get", "anchor"]));
      await mapController.style
          .setStyleLayerProperty("routeLabels-clicklayer", 'text-anchor', json.encode(["get", "anchor"]));
      await mapController.style
          .setStyleLayerProperty("routeLabels-clicklayer", 'text-field', json.encode(["get", "text"]));
      await mapController.style
          .setStyleLayerProperty("routeLabels-clicklayer", 'text-offset', json.encode(["get", "textOffset"]));
      await mapController.style.setStyleLayerProperty(
          "routeLabels-clicklayer",
          'text-color',
          json.encode([
            "case",
            ["get", "isPrimary"],
            "#ffffff",
            "#000000"
          ]));
      await mapController.style.setStyleLayerProperty(
          "routeLabels-clicklayer",
          'text-opacity',
          json.encode(
            showAfter(zoom: 10),
          ));
    }

    return "routeLabels-layer";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists("routeLabels");
    if (sourceExists) {
      final source = await mapController.style.getSource("routeLabels");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class DiscomfortsLayer {
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
    String? below,
  }) async {
    final sourceExists = await mapController.style.styleSourceExists("discomforts");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "discomforts", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }
    final discomfortsClickLayerExists = await mapController.style.styleLayerExists("discomforts-clicklayer");
    if (!discomfortsClickLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: "discomforts",
            id: "discomforts-clicklayer",
            lineColor: Colors.pink.value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineWidth: clickWidth,
            lineOpacity: 0.001,
          ),
          mapbox.LayerPosition(below: below));
    }
    final discomfortsLayerExists = await mapController.style.styleLayerExists("discomforts-layer");
    if (!discomfortsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
            sourceId: "discomforts",
            id: "discomforts-layer",
            lineColor: const Color(0xFFE63328).value,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineWidth: lineWidth,
          ),
          mapbox.LayerPosition(below: below));
    }
    final discomfortsMarkersExist = await mapController.style.styleLayerExists("discomforts-markers");
    if (!discomfortsMarkersExist) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: "discomforts",
            id: "discomforts-markers",
            iconImage: "alert",
            iconSize: iconSize,
            iconAllowOverlap: true,
            textSize: 12,
            textAllowOverlap: true,
            textIgnorePlacement: true,
          ),
          mapbox.LayerPosition(below: below));
      await mapController.style
          .setStyleLayerProperty("discomforts-markers", 'text-field', json.encode(["get", "number"]));
    }
    return "discomforts-layer";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists("discomforts");
    if (sourceExists) {
      final source = await mapController.style.getSource("discomforts");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class WaypointsLayer {
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
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 0.75, String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists("waypoints");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "waypoints", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }
    final waypointsIconsLayerExists = await mapController.style.styleLayerExists("waypoints-icons");
    if (!waypointsIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
              sourceId: "waypoints",
              id: "waypoints-icons",
              iconSize: iconSize,
              textAllowOverlap: true,
              textIgnorePlacement: true,
              iconAllowOverlap: true),
          mapbox.LayerPosition(below: below));
      await mapController.style.setStyleLayerProperty(
          "waypoints-icons",
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

    return "waypoints-icons";
  }

  /// Update the overlay on the layer controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists("waypoints");
    if (sourceExists) {
      final source = await mapController.style.getSource("waypoints");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class DangersLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  DangersLayer(bool isDark, {hideBehindPosition = false}) {
    final dangers = getIt<Dangers>();
    final routing = getIt<Routing>();
    final userPosSnap = getIt<Positioning>().snap;
    if (routing.selectedRoute == null) return;
    for (int i = 0; i < dangers.dangers.length; i++) {
      final danger = dangers.dangers[i];
      final dangerDistanceOnRoute = dangers.dangersDistancesOnRoute[i];
      // Clamp the value to not unnecessarily update the source.
      final distanceToDangerOnRoute = max(-5, min(0, dangerDistanceOnRoute - (userPosSnap?.distanceOnRoute ?? 0)));
      String icon;
      switch (danger.category) {
        case "obstacle":
          icon = "obstacle";
          break;
        case "potholes":
          icon = "potholes";
          break;
        default:
          icon = "dangerspot";
          break;
      }
      features.add(
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [danger.lon, danger.lat],
          },
          "properties": {
            "icon": icon,
            "isDark": isDark,
            "distanceToDangerOnRoute": distanceToDangerOnRoute,
            "hideBehindPosition": hideBehindPosition,
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 1.0, String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists("dangers");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "dangers", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final dangersIconsLayerExists = await mapController.style.styleLayerExists("dangers-icons");
    if (!dangersIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: "dangers",
            id: "dangers-icons",
            iconSize: iconSize,
            iconAllowOverlap: true,
            textAllowOverlap: true,
            textIgnorePlacement: true,
          ),
          mapbox.LayerPosition(below: below));
      await mapController.style.setStyleLayerProperty("dangers-icons", 'icon-image', json.encode(["get", "icon"]));
      await mapController.style.setStyleLayerProperty(
          "dangers-icons",
          'icon-opacity',
          json.encode(
            showAfter(zoom: 16, opacity: [
              "case",
              ["get", "hideBehindPosition"],
              [
                "case",
                [
                  "<",
                  ["get", "distanceToDangerOnRoute"],
                  -5, // See above - this is clamped to [-5, 0]
                ],
                0,
                // Interpolate between -5 (opacity=0) and 0 (opacity=1) meters
                [
                  "interpolate",
                  ["linear"],
                  ["get", "distanceToDangerOnRoute"],
                  -5, // See above - this is clamped to [-5, 0]
                  0,
                  0,
                  1
                ],
              ],
              1
            ]),
          ));
    }

    return "dangers-icons";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists("dangers");
    if (sourceExists) {
      final source = await mapController.style.getSource("dangers");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}
