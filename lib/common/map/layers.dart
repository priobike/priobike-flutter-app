import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/map_settings.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';

/// The zoomToGeographicalDistance map includes all zoom level and maps it to the distance in meter per pixel.
/// Taken from +-60 Latitude since it only needs to be approximate and its closer to 53 than +-40.
/// Its also to small in worst case.
final Map<int, double> zoomToGeographicalDistance = {
  0: 39135.742,
  1: 19567.871,
  2: 9783.936,
  3: 4891.968,
  4: 2445.984,
  5: 1222.992,
  6: 611.496,
  7: 305.748,
  8: 152.874,
  9: 76.437,
  10: 38.218,
  11: 19.109,
  12: 9.555,
  13: 4.777,
  14: 2.389,
  15: 1.194,
  16: 0.597,
  17: 0.299,
  18: 0.149,
  19: 0.075,
  20: 0.047,
  21: 0.019,
  22: 0.009
};

/// Fade a layer out before a specific zoom level.
dynamic showAfter({required int zoom, dynamic opacity = 1.0}) {
  return [
    "interpolate",
    ["linear"],
    ["zoom"],
    0,
    0,
    zoom - 1,
    0,
    zoom,
    opacity,
  ];
}

class AllRoutesLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  AllRoutesLayer(BuildContext context) {
    final routing = Provider.of<Routing>(context, listen: false);
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
    await mapController.style.styleSourceExists("routes").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(id: "routes", data: json.encode({"type": "FeatureCollection", "features": features})),
        );
      } else {
        await update(mapController);
      }
    });
    await mapController.style.styleLayerExists("routes-clicklayer").then((exists) async {
      if (!exists) {
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
    });
    await mapController.style.styleLayerExists("routes-layer").then((exists) async {
      if (!exists) {
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
    });

    return "routes-layer";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    await mapController.style.styleSourceExists("routes").then((exists) async {
      if (exists) {
        final source = await mapController.style.getSource("routes");
        (source as mapbox.GeoJsonSource)
            .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
      }
    });
  }
}

class SelectedRouteLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  SelectedRouteLayer(BuildContext context) {
    final routing = Provider.of<Routing>(context, listen: false);
    final navNodes = routing.selectedRoute?.route ?? [];

    final status = Provider.of<PredictionSGStatus>(context, listen: false);
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
    await mapController.style.styleSourceExists("route").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(id: "route", data: json.encode({"type": "FeatureCollection", "features": features})),
        );
      } else {
        await update(mapController);
      }
    });
    await mapController.style.styleLayerExists("route-background-layer").then((exists) async {
      if (!exists) {
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
    });
    await mapController.style.styleLayerExists("route-layer").then((exists) async {
      if (!exists) {
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
    });
    return "route-layer";
  }

  update(mapbox.MapboxMap mapController, {String? below}) async {
    await mapController.style.styleSourceExists("route").then((exists) async {
      if (exists) {
        final source = await mapController.style.getSource("route");
        (source as mapbox.GeoJsonSource)
            .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
      }
    });
  }
}

class RouteLabelLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  RouteLabelLayer(BuildContext context) {
    final routing = Provider.of<Routing>(context, listen: false);
    final mapController = Provider.of<MapSettings>(context, listen: false);

    // Conditions for having route labels.
    if (mapController.controller != null &&
        mapController.controller!.cameraPosition != null &&
        routing.allRoutes != null &&
        routing.allRoutes!.length >= 2 &&
        routing.selectedRoute != null) {
      var distance = const latlng.Distance();

      double width = MediaQuery.of(context).size.width;
      double height = MediaQuery.of(context).size.height;
      double meterPerPixel = zoomToGeographicalDistance[mapController.controller!.cameraPosition!.zoom.toInt()] ?? 0;
      double cameraPosLat = mapController.controller!.cameraPosition!.target.latitude;
      double cameraPosLong = mapController.controller!.cameraPosition!.target.longitude;

      // Cast to LatLng2 format.
      latlng.LatLng cameraPos = latlng.LatLng(cameraPosLat, cameraPosLong);

      // Getting the bounds north, east, south, west.
      // Calculation of Bounding Points: Distance between camera position and the distance to the edge of the screen.
      latlng.LatLng north = distance.offset(cameraPos, height / 2 * meterPerPixel, 0);
      latlng.LatLng east = distance.offset(cameraPos, width / 2 * meterPerPixel, 90);
      latlng.LatLng south = distance.offset(cameraPos, height / 2 * meterPerPixel, 180);
      latlng.LatLng west = distance.offset(cameraPos, width / 2 * meterPerPixel, 270);

      bool allInBounds = true;
      // Check if current route labels are in bounds still.
      if (routing.routeLabelCoords.isNotEmpty) {
        for (GHCoordinate ghCoordinate in routing.routeLabelCoords) {
          // Check out of new bounds.
          if (ghCoordinate.lat < south.latitude ||
              ghCoordinate.lat > north.latitude ||
              ghCoordinate.lon < west.longitude ||
              ghCoordinate.lon > east.longitude) {
            // Not in new bounds.
            allInBounds = false;
          }
        }
      }

      // If all in bounds then we don't have to calculate new positions.
      // But update route labels in case the selected route changed.
      if (allInBounds && routing.allRoutes!.length == routing.routeLabelCoords.length) {
        for (var i = 0; i < routing.allRoutes!.length; i++) {
          features.add(
            {
              "id": "routeLabel-${routing.allRoutes![i].id}", // Required for click listener.
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [routing.routeLabelCoords[i].lon, routing.routeLabelCoords[i].lat],
              },
              "properties": {
                "isPrimary": routing.selectedRoute!.id == routing.allRoutes![i].id,
                "text": "${((routing.allRoutes![i].path.time * 0.001) * 0.016).round()} min"
              },
            },
          );
        }
        return;
      }

      // Reset the old coords before adding the new ones.
      routing.resetRouteLabelCoords();

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
          // Use the middlest coordinate.
          chosenCoordinate = uniqueInBounceCoordinates[uniqueInBounceCoordinates.length ~/ 2];
        }

        if (chosenCoordinate != null) {
          // Found coordinate and add Label with time.
          features.add(
            {
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
            },
          );
          // Add to routing coords.
          routing.addRouteLabelCoords(GHCoordinate(lon: chosenCoordinate.lon, lat: chosenCoordinate.lat));
        }
      }
    }
  }

  /// Install the overlay on the layer controller.
  Future<String> install(
    LayerController layerController, {
    iconSize = 0.75,
    String? below,
  }) async {
    await layerController.addGeoJsonSource(
      "routeLabels",
      {"type": "FeatureCollection", "features": features},
    );
    // Make it easier to click on the route.
    await layerController.addLayer(
      "routeLabels",
      "routeLabels-clicklayer",
      SymbolLayerProperties(
        // iconAnchor: "bottom",
        // textAnchor: "bottom",
        iconImage: [
          "case",
          ["get", "isPrimary"],
          "route-label-pmm",
          "route-label-smm"
        ],
        iconSize: iconSize,
        iconOpacity: showAfter(zoom: 10),
        iconOffset: [
          Expressions.literal,
          [0, -10]
        ],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        textField: ["get", "text"],
        textOffset: [
          Expressions.literal,
          [0, -1.25]
        ],
        textColor: [
          "case",
          ["get", "isPrimary"],
          "#ffffff",
          "#000000"
        ],
        textSize: 12,
        textOpacity: showAfter(zoom: 10),
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
      enableInteraction: true,
      belowLayerId: below,
    );
    return "routeLabels-layer";
  }

  /// Update the overlay on the layer controller (without updating the layers).
  update(LayerController layerController) async {
    await layerController.updateGeoJsonSource(
      "routeLabels",
      {"type": "FeatureCollection", "features": features},
    );
  }
}

class DiscomfortsLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  DiscomfortsLayer(BuildContext context) {
    final discomforts = Provider.of<Discomforts>(context, listen: false).foundDiscomforts;
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
    await mapController.style.styleSourceExists("discomforts").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(
              id: "discomforts", data: json.encode({"type": "FeatureCollection", "features": features})),
        );
      } else {
        await update(mapController);
      }
    });
    await mapController.style.styleLayerExists("discomforts-layer").then((exists) async {
      if (!exists) {
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
    });

    // TODO look if neceissary
    /*await layerController.addLayer(
      "discomforts",
      "discomforts-clicklayer",
      LineLayerProperties(
        lineWidth: clickWidth,
        lineColor: "#000000",
        lineCap: "round",
        lineJoin: "round",
        lineOpacity: 0.001, // Not 0 to make the click listener work.
      ),
      enableInteraction: true,
      belowLayerId: below,
    );*/

    await mapController.style.styleLayerExists("discomforts-markers").then((exists) async {
      if (!exists) {
        await mapController.style.addLayerAt(
            mapbox.SymbolLayer(
              sourceId: "discomforts",
              id: "discomforts-markers",
              iconImage: "alert",
              iconSize: iconSize,
              textSize: 12,
              textAllowOverlap: true,
              textIgnorePlacement: true,
            ),
            mapbox.LayerPosition(below: below));
        await mapController.style
            .setStyleLayerProperty("discomforts-markers", 'text-field', json.encode(["get", "number"]));
      }
    });
    return "discomforts-layer";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    await mapController.style.styleSourceExists("discomforts").then((exists) async {
      if (exists) {
        final source = await mapController.style.getSource("discomforts");
        (source as mapbox.GeoJsonSource)
            .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
      }
    });
  }
}

class WaypointsLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  WaypointsLayer(BuildContext context) {
    final routing = Provider.of<Routing>(context, listen: false);
    final waypoints = routing.selectedWaypoints ?? [];
    for (MapEntry<int, Waypoint?> entry in waypoints.asMap().entries) {
      if (entry.value != null) {
        features.add(
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [entry.value!.lon, entry.value!.lat],
            },
            "properties": {
              "isFirst": entry.key == 0,
              "isLast": entry.key == waypoints.length - 1,
            },
          },
        );
      }
    }
  }

  /// Install the overlay on the map controller.
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 0.75, String? below}) async {
    await mapController.style.styleSourceExists("waypoints").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(id: "waypoints", data: json.encode({"type": "FeatureCollection", "features": features})),
        );
      } else {
        await update(mapController);
      }
    });
    await mapController.style.styleLayerExists("waypoints-icons").then((exists) async {
      if (!exists) {
        await mapController.style.addLayerAt(
            mapbox.SymbolLayer(
              sourceId: "waypoints",
              id: "waypoints-icons",
              iconSize: iconSize,
              textAllowOverlap: true,
              textIgnorePlacement: true,
              iconAllowOverlap: true
            ),
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
    });

    return "waypoints-icons";
  }

  /// Update the overlay on the layer controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    await mapController.style.styleSourceExists("waypoints").then((exists) async {
      if (exists) {
        final source = await mapController.style.getSource("waypoints");
        (source as mapbox.GeoJsonSource)
            .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
      }
    });
  }
}

class TrafficLightsLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  TrafficLightsLayer(BuildContext context, {hideBehindPosition = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showLabels = Provider.of<Settings>(context, listen: false).sgLabelsMode == SGLabelsMode.enabled;
    final routing = Provider.of<Routing>(context, listen: false);
    final userPosSnap = Provider.of<Positioning>(context, listen: false).snap;
    if (routing.selectedRoute == null) return;
    for (int i = 0; i < routing.selectedRoute!.signalGroups.length; i++) {
      final sg = routing.selectedRoute!.signalGroups[i];
      final sgDistanceOnRoute = routing.selectedRoute!.signalGroupsDistancesOnRoute[i];
      // Clamp the value to not unnecessarily update the source.
      final distanceToSgOnRoute = max(-5, min(0, sgDistanceOnRoute - (userPosSnap?.distanceOnRoute ?? 0)));
      features.add(
        {
          "id": "traffic-light",
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [sg.position.lon, sg.position.lat],
          },
          "properties": {
            "id": sg.id,
            "isDark": isDark,
            "showLabels": showLabels,
            "distanceToSgOnRoute": distanceToSgOnRoute,
            "hideBehindPosition": hideBehindPosition,
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 1.0, String? below}) async {
    await mapController.style.styleSourceExists("traffic-lights").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(
              id: "traffic-lights", data: json.encode({"type": "FeatureCollection", "features": features})),
        );
      } else {
        await update(mapController);
      }
    });

    await mapController.style.styleLayerExists("traffic-lights-icons").then((exists) async {
      if (!exists) {
        await mapController.style.addLayerAt(
            mapbox.SymbolLayer(
              sourceId: "traffic-lights",
              id: "traffic-lights-icons",
              iconSize: iconSize,
              textAllowOverlap: true,
              textIgnorePlacement: true,
              iconOpacity: 0,
            ),
            mapbox.LayerPosition(below: below));
        await mapController.style.setStyleLayerProperty(
            "traffic-lights-icons",
            'icon-image',
            json.encode([
              "case",
              ["get", "isDark"],
              "trafficlightonlinedarknocheck",
              "trafficlightonlinelightnocheck",
            ]));
        await mapController.style.setStyleLayerProperty(
            "traffic-lights-icons",
            'icon-opacity',
            json.encode(
              showAfter(zoom: 16, opacity: [
                "case",
                ["get", "hideBehindPosition"],
                [
                  "case",
                  [
                    "<",
                    ["get", "distanceToSgOnRoute"],
                    -5, // See above - this is clamped to [-5, 0]
                  ],
                  0,
                  // Interpolate between -5 (opacity=0) and 0 (opacity=1) meters
                  [
                    "interpolate",
                    ["linear"],
                    ["get", "distanceToSgOnRoute"],
                    -5, // See above - this is clamped to [-5, 0]
                    0,
                    0,
                    1
                  ],
                ],
                1
              ]),
            ));
        await mapController.style.setStyleLayerProperty(
            "traffic-lights-icons",
            'text-field',
            json.encode([
              "case",
              ["get", "showLabels"],
              ["get", "id"],
              ""
            ]));
      }
    });
    return "traffic-lights-icons";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    await mapController.style.styleSourceExists("traffic-lights").then((exists) async {
      if (exists) {
        final source = await mapController.style.getSource("traffic-lights");
        (source as mapbox.GeoJsonSource)
            .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
      }
    });
  }
}

class TrafficLightLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  TrafficLightLayer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ride = Provider.of<Ride>(context, listen: false);
    final sgQuality = ride.calcPredictionQuality;
    String sgIcon;
    switch (ride.calcCurrentSignalPhase) {
      case Phase.green:
        if (isDark) {
          sgIcon = "trafficlightonlinegreendark";
        } else {
          sgIcon = "trafficlightonlinegreenlight";
        }
        break;
      case Phase.amber:
        if (isDark) {
          sgIcon = "trafficlightonlineamberdark";
        } else {
          sgIcon = "trafficlightonlineamberlight";
        }
        break;
      case Phase.redAmber:
        if (isDark) {
          sgIcon = "trafficlightonlineamberdark";
        } else {
          sgIcon = "trafficlightonlineamberlight";
        }
        break;
      case Phase.red:
        if (isDark) {
          sgIcon = "trafficlightonlinereddark";
        } else {
          sgIcon = "trafficlightonlineredlight";
        }
        break;
      default:
        if (isDark) {
          sgIcon = "trafficlightonlinedarkdark";
        } else {
          sgIcon = "trafficlightonlinedarklight";
        }
        break;
    }
    final sgPos = ride.userSelectedSG?.position ?? ride.calcCurrentSG?.position;
    if (sgQuality == null || sgPos == null) return;
    if (sgQuality < Ride.qualityThreshold) return;

    features.add(
      {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [sgPos.lon, sgPos.lat],
        },
        "properties": {
          "sgIcon": sgIcon,
        },
      },
    );
  }

  /// Install the overlay on the map controller.
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 1.0, String? below}) async {
    await mapController.style.styleSourceExists("traffic-light").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(
              id: "traffic-light", data: json.encode({"type": "FeatureCollection", "features": features})),
        );
      } else {
        await update(mapController);
      }
    });

    await mapController.style.styleLayerExists("traffic-light-icon").then((exists) async {
      if (!exists) {
        await mapController.style.addLayerAt(
            mapbox.SymbolLayer(
              sourceId: "traffic-light",
              id: "traffic-light-icon",
              iconSize: iconSize,
              textAllowOverlap: true,
              textIgnorePlacement: true,
            ),
            mapbox.LayerPosition(below: below));
        await mapController.style
            .setStyleLayerProperty("traffic-light-icon", 'icon-image', json.encode(["get", "sgIcon"]));
      }
    });

    return "traffic-light-icon";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    await mapController.style.styleSourceExists("traffic-light").then((exists) async {
      if (exists) {
        final source = await mapController.style.getSource("traffic-light");
        (source as mapbox.GeoJsonSource)
            .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
      }
    });
  }
}

class OfflineCrossingsLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  OfflineCrossingsLayer(BuildContext context, {hideBehindPosition = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showLabels = Provider.of<Settings>(context, listen: false).sgLabelsMode == SGLabelsMode.enabled;
    final routing = Provider.of<Routing>(context, listen: false);
    final userPosSnap = Provider.of<Positioning>(context, listen: false).snap;
    if (routing.selectedRoute == null) return;
    for (int i = 0; i < routing.selectedRoute!.crossings.length; i++) {
      final crossing = routing.selectedRoute!.crossings[i];
      final crossingDistanceOnRoute = routing.selectedRoute!.crossingsDistancesOnRoute[i];
      if (crossing.connected) continue;
      // Clamp the value to not unnecessarily update the source.
      final distanceToCrossingOnRoute = max(-5, min(0, crossingDistanceOnRoute - (userPosSnap?.distanceOnRoute ?? 0)));
      features.add(
        {
          "id": "traffic-light",
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [crossing.position.lon, crossing.position.lat],
          },
          "properties": {
            "name": crossing.name,
            "isDark": isDark,
            "showLabels": showLabels,
            "distanceToCrossingOnRoute": distanceToCrossingOnRoute,
            "hideBehindPosition": hideBehindPosition,
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 1.0, String? below}) async {
    await mapController.style.styleSourceExists("offline-crossings").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(
              id: "offline-crossings", data: json.encode({"type": "FeatureCollection", "features": features})),
        );
      } else {
        await update(mapController);
      }
    });

    await mapController.style.styleLayerExists("offline-crossings-icons").then((exists) async {
      if (!exists) {
        await mapController.style.addLayerAt(
            mapbox.SymbolLayer(
              sourceId: "offline-crossings",
              id: "offline-crossings-icons",
              iconSize: iconSize,
              textAllowOverlap: true,
              textIgnorePlacement: true,
            ),
            mapbox.LayerPosition(below: below));
        await mapController.style.setStyleLayerProperty(
            "offline-crossings-icons",
            'icon-image',
            json.encode([
              "case",
              ["get", "isDark"],
              "trafficlightdisconnecteddark",
              "trafficlightdisconnectedlight",
            ]));
        await mapController.style.setStyleLayerProperty(
            "offline-crossings-icons",
            'icon-opacity',
            json.encode(
              showAfter(zoom: 16, opacity: [
                "case",
                ["get", "hideBehindPosition"],
                [
                  "case",
                  [
                    "<",
                    ["get", "distanceToCrossingOnRoute"],
                    -5, // See above - this is clamped to [-5, 0]
                  ],
                  0,
                  // Interpolate between -5 (opacity=0) and 0 (opacity=1) meters
                  [
                    "interpolate",
                    ["linear"],
                    ["get", "distanceToCrossingOnRoute"],
                    -5, // See above - this is clamped to [-5, 0]
                    0,
                    0,
                    1
                  ],
                ],
                1
              ]),
            ));
        await mapController.style.setStyleLayerProperty(
            "offline-crossings-icons",
            'text-field',
            json.encode([
              "case",
              ["get", "showLabels"],
              ["get", "name"],
              ""
            ]));
      }
    });

    return "offline-crossings-icons";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    await mapController.style.styleSourceExists("offline-crossings").then((exists) async {
      if (exists) {
        final source = await mapController.style.getSource("offline-crossings");
        (source as mapbox.GeoJsonSource)
            .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
      }
    });
  }
}

class DangersLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  DangersLayer(BuildContext context, {hideBehindPosition = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dangers = Provider.of<Dangers>(context, listen: false);
    final routing = Provider.of<Routing>(context, listen: false);
    final userPosSnap = Provider.of<Positioning>(context, listen: false).snap;
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
    await mapController.style.styleSourceExists("dangers").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(id: "dangers", data: json.encode({"type": "FeatureCollection", "features": features})),
        );
      } else {
        await update(mapController);
      }
    });

    await mapController.style.styleLayerExists("dangers-icons").then((exists) async {
      if (!exists) {
        await mapController.style.addLayerAt(
            mapbox.SymbolLayer(
              sourceId: "dangers",
              id: "dangers-icons",
              iconSize: iconSize,
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
    });

    return "dangers-icons";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    await mapController.style.styleSourceExists("dangers").then((exists) async {
      if (exists) {
        final source = await mapController.style.getSource("dangers");
        (source as mapbox.GeoJsonSource)
            .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
      }
    });
  }
}

class ParkingStationsLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  ParkingStationsLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    await mapController.style.styleSourceExists("parking-stations").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(id: "parking-stations", data: "https://$baseUrl/map-data/bicycle_parking.geojson"),
        );
      }
    });

    await mapController.style.styleLayerExists("parking-stations-icons").then((exists) async {
      if (!exists) {
        await mapController.style.addLayer(mapbox.SymbolLayer(
          sourceId: "parking-stations",
          id: "parking-stations-icons",
          iconImage: isDark ? "parkdark" : "parklight",
          iconSize: iconSize,
          iconOpacity: 0,
          iconAllowOverlap: true,
        ));
        await mapController.style.setStyleLayerProperty(
            "parking-stations-icons",
            'icon-opacity',
            json.encode(
              showAfter(zoom: 15),
            ));
      }
    });
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    await mapController.style.styleLayerExists("parking-stations-icons").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleLayer("parking-stations-icons");
      }
    });
    await mapController.style.styleSourceExists("parking-stations").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleSource("parking-stations");
      }
    });
  }
}

class RentalStationsLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  RentalStationsLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    await mapController.style.styleSourceExists("rental-stations").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(id: "rental-stations", data: "https://$baseUrl/map-data/bicycle_rental.geojson"),
        );
      }
    });

    await mapController.style.styleLayerExists("rental-stations-icons").then((exists) async {
      if (!exists) {
        await mapController.style.addLayer(mapbox.SymbolLayer(
          sourceId: "rental-stations",
          id: "rental-stations-icons",
          iconImage: isDark ? "rentdark" : "rentlight",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 0,
          textHaloColor: isDark ? const Color(0xFF000000).value : const Color(0xFFFFFFFF).value,
          textHaloWidth: 1,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textAnchor: mapbox.TextAnchor.CENTER,
          textColor: const Color(0xFF0075FF).value,
          textAllowOverlap: true,
          textOpacity: 0,
        ));
        await mapController.style.setStyleLayerProperty(
            "rental-stations-icons",
            'icon-opacity',
            json.encode(
              showAfter(zoom: 15),
            ));
        await mapController.style.setStyleLayerProperty(
            "rental-stations-icons",
            'text-offset',
            json.encode(
              [
                "literal",
                [0, 2]
              ],
            ));
        await mapController.style.setStyleLayerProperty(
            "rental-stations-icons",
            'text-field',
            json.encode([
              "case",
              ["has", "name"],
              [
                // Concatenate "Ausleihstation" with the name of the station.
                "concat",
                "Fahrradleihe ",
                ["get", "name"]
              ],
              "Fahrradleihe "
            ]));
        await mapController.style
            .setStyleLayerProperty("rental-stations-icons", 'text-opacity', json.encode(showAfter(zoom: 17)));
      }
    });
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    await mapController.style.styleLayerExists("rental-stations-icons").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleLayer("rental-stations-icons");
      }
    });
    await mapController.style.styleSourceExists("rental-stations").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleSource("rental-stations");
      }
    });
  }
}

class BikeShopLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  BikeShopLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    await mapController.style.styleSourceExists("bike-shop").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(id: "bike-shop", data: "https://$baseUrl/map-data/bicycle_shop.geojson"),
        );
      }
    });

    await mapController.style.styleLayerExists("bike-shop-icons").then((exists) async {
      if (!exists) {
        await mapController.style.addLayer(mapbox.SymbolLayer(
          sourceId: "bike-shop",
          id: "bike-shop-icons",
          iconImage: isDark ? "repairdark" : "repairlight",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 0,
          textHaloColor: isDark ? const Color(0xFF000000).value : const Color(0xFFFFFFFF).value,
          textHaloWidth: 1,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textAnchor: mapbox.TextAnchor.CENTER,
          textColor: const Color(0xFF0075FF).value,
          textAllowOverlap: true,
          textOpacity: 0,
        ));
        await mapController.style.setStyleLayerProperty(
            "bike-shop-icons",
            'icon-opacity',
            json.encode(
              showAfter(zoom: 15),
            ));
        await mapController.style.setStyleLayerProperty(
            "bike-shop-icons",
            'text-offset',
            json.encode(
              [
                "literal",
                [0, 2]
              ],
            ));
        await mapController.style.setStyleLayerProperty(
            "bike-shop-icons",
            'text-field',
            json.encode([
              "case",
              ["has", "name"],
              [
                // Check if name is empty and display "Fahrradladen" if it is.
                "case",
                [
                  "==",
                  ["get", "name"],
                  " "
                ],
                "Fahrradladen",
                ["get", "name"]
              ],
              "Fahrradladen"
            ]));
        await mapController.style
            .setStyleLayerProperty("bike-shop-icons", 'text-opacity', json.encode(showAfter(zoom: 17)));
      }
    });
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    await mapController.style.styleLayerExists("bike-shop-icons").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleLayer("bike-shop-icons");
      }
    });
    await mapController.style.styleSourceExists("bike-shop").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleSource("bike-shop");
      }
    });
  }
}

class BikeAirStationLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  final BuildContext context;

  BikeAirStationLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    await mapController.style.styleSourceExists("bike-air-station").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(id: "bike-air-station", data: "https://$baseUrl/map-data/bike_air_station.geojson"),
        );
      }
    });
    await mapController.style.styleLayerExists("bike-air-station-icons").then((exists) async {
      if (!exists) {
        await mapController.style.addLayer(mapbox.SymbolLayer(
          sourceId: "bike-air-station",
          id: "bike-air-station-icons",
          iconImage: isDark ? "airdark" : "airlight",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 0,
          textHaloColor: isDark ? const Color(0xFF000000).value : const Color(0xFFFFFFFF).value,
          textHaloWidth: 1,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textAnchor: mapbox.TextAnchor.CENTER,
          textColor: const Color(0xFF0075FF).value,
          textAllowOverlap: true,
          textOpacity: 0,
        ));
        await mapController.style.setStyleLayerProperty(
            "bike-air-station-icons",
            'icon-opacity',
            json.encode(
              showAfter(zoom: 15),
            ));
        await mapController.style.setStyleLayerProperty(
            "bike-air-station-icons",
            'text-offset',
            json.encode(
              [
                "literal",
                [0, 2]
              ],
            ));
        await mapController.style.setStyleLayerProperty(
            "bike-air-station-icons",
            'text-field',
            json.encode([
              "case",
              ["has", "anmerkungen"],
              [
                // Concate "Luftstation" and the anmerkungen.
                "concat",
                "Luftstation ",
                ["get", "anmerkungen"]
              ],
              "Luftstation"
            ]));
        await mapController.style
            .setStyleLayerProperty("bike-air-station-icons", 'text-opacity', json.encode(showAfter(zoom: 17)));
      }
    });
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    await mapController.style.styleLayerExists("bike-air-station-icons").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleLayer("bike-air-station-icons");
      }
    });
    await mapController.style.styleSourceExists("bike-air-station").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleSource("bike-air-station");
      }
    });
  }
}

class ConstructionSitesLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  ConstructionSitesLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    await mapController.style.styleSourceExists("construction-sites").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(id: "construction-sites", data: "https://$baseUrl/map-data/construction_sites.geojson"),
        );
      }
    });
    await mapController.style.styleLayerExists("construction-sites-icons").then((exists) async {
      if (!exists) {
        await mapController.style.addLayer(mapbox.SymbolLayer(
          sourceId: "construction-sites",
          id: "construction-sites-icons",
          iconImage: isDark ? "constructiondark" : "constructionlight",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 0,
          textHaloColor: isDark ? const Color(0xFF000000).value : const Color(0xFFFFFFFF).value,
          textHaloWidth: 1,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textAnchor: mapbox.TextAnchor.CENTER,
          textColor: const Color(0xFFE67E22).value,
          textAllowOverlap: true,
          textOpacity: 0,
        ));
        await mapController.style.setStyleLayerProperty(
            "construction-sites-icons",
            'icon-opacity',
            json.encode(
              showAfter(zoom: 12),
            ));
        await mapController.style.setStyleLayerProperty("construction-sites-icons", 'text-field', 'Baustelle');
        await mapController.style.setStyleLayerProperty(
            "construction-sites-icons",
            'text-offset',
            json.encode(
              [
                "literal",
                [0, 1]
              ],
            ));
        await mapController.style
            .setStyleLayerProperty("construction-sites-icons", 'text-opacity', json.encode(showAfter(zoom: 15)));
      }
    });
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    await mapController.style.styleLayerExists("construction-sites-icons").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleLayer("construction-sites-icons");
      }
    });
    await mapController.style.styleSourceExists("construction-sites").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleSource("construction-sites");
      }
    });
  }
}

class AccidentHotspotsLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// Build context of the widget
  final BuildContext context;

  AccidentHotspotsLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    await mapController.style.styleSourceExists("accident-hotspots").then((exists) async {
      if (!exists) {
        await mapController.style.addSource(
          mapbox.GeoJsonSource(id: "accident-hotspots", data: "https://$baseUrl/map-data/accident_hot_spots.geojson"),
        );
      }
    });
    await mapController.style.styleLayerExists("accident-hotspots-icons").then((exists) async {
      if (!exists) {
        await mapController.style.addLayer(mapbox.SymbolLayer(
          sourceId: "accident-hotspots",
          id: "accident-hotspots-icons",
          iconImage: isDark ? "accidentdark" : "accidentlight",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 0,
          textHaloColor: isDark ? const Color(0xFF000000).value : const Color(0xFFFFFFFF).value,
          textHaloWidth: 1,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textAnchor: mapbox.TextAnchor.CENTER,
          textColor: const Color(0xFFFF4757).value,
          textAllowOverlap: true,
          textOpacity: 0,
        ));
        await mapController.style.setStyleLayerProperty(
            "accident-hotspots-icons",
            'icon-opacity',
            json.encode(
              showAfter(zoom: 11),
            ));
        await mapController.style
            .setStyleLayerProperty("accident-hotspots-icons", 'text-field', 'Unfall-\nschwerpunkt');
        await mapController.style.setStyleLayerProperty(
            "accident-hotspots-icons",
            'text-offset',
            json.encode(
              [
                "literal",
                [0, 1]
              ],
            ));
        await mapController.style
            .setStyleLayerProperty("accident-hotspots-icons", 'text-opacity', json.encode(showAfter(zoom: 15)));
      }
    });
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    await mapController.style.styleLayerExists("accident-hotspots-icons").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleLayer("accident-hotspots-icons");
      }
    });
    await mapController.style.styleSourceExists("accident-hotspots").then((exists) async {
      if (exists) {
        await mapController.style.removeStyleSource("accident-hotspots");
      }
    });
  }
}
