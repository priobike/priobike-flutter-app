import 'dart:convert';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/controller.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routingNew/messages/graphhopper.dart';
import 'package:priobike/routingNew/models/route.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routingNew/services/discomfort.dart';
import 'package:priobike/routingNew/services/mapcontroller.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as LatLng2;
import 'package:priobike/routingNew/models/route.dart' as r;

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
dynamic showAfter({required int zoom, double opacity = 1.0}) {
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

  /// Install the overlay on the layer controller.
  Future<String> install(
    LayerController layerController, {
    lineWidth = 9.0,
    clickLineWidth = 25.0,
    String? below,
  }) async {
    await layerController.addGeoJsonSource(
      "routes",
      {"type": "FeatureCollection", "features": features},
    );
    await layerController.addLayer(
      "routes",
      "routes-layer",
      LineLayerProperties(
        lineWidth: lineWidth,
        lineColor: "#C6C6C6",
        lineJoin: "round",
      ),
      enableInteraction: false,
      belowLayerId: below,
    );
    // Make it easier to click on the route.
    await layerController.addLayer(
      "routes",
      "routes-clicklayer",
      LineLayerProperties(
        lineWidth: clickLineWidth,
        lineColor: "#000000",
        lineJoin: "round",
        lineOpacity: 0.001, // Not 0 to make the click listener work.
      ),
      enableInteraction: true,
      belowLayerId: below,
    );
    return "routes-layer";
  }

  /// Update the overlay on the layer controller (without updating the layers).
  update(LayerController layerController) async {
    await layerController.updateGeoJsonSource(
      "routes",
      {"type": "FeatureCollection", "features": features},
    );
  }
}

class SelectedRouteLayer {
  /// The features to display.
  final List<dynamic> features = List.filled(1, null, growable: false); // For optmization.

  SelectedRouteLayer(BuildContext context) {
    final routing = Provider.of<Routing>(context, listen: false);
    final route = routing.selectedRoute?.route ?? [];
    final waypoints = routing.selectedWaypoints ?? [];
    final coordinates = route.map((e) => [e.lon, e.lat]).toList();
    if (waypoints.length > 1) {
      final geometry = {
        "type": "LineString",
        "coordinates": coordinates,
      };
      features[0] = {
        "id": "selected-route",
        "type": "Feature",
        "properties": {},
        "geometry": geometry,
      };
    } else {
      final geometry = {
        "type": "MultiPoint",
        "coordinates": coordinates,
      };
      features[0] = {
        "id": "selected-route",
        "type": "Feature",
        "properties": {},
        "geometry": geometry,
      };
    }
  }

  /// Install the overlay on the layer controller.
  Future<String> install(LayerController layerController, {bgLineWidth = 9.0, fgLineWidth = 7.0, String? below}) async {
    await layerController.addGeoJsonSource(
      "route",
      {"type": "FeatureCollection", "features": features},
    );
    await layerController.addLayer(
      "route",
      "route-background-layer",
      LineLayerProperties(
        lineWidth: bgLineWidth,
        lineColor: "#C6C6C6",
        lineJoin: "round",
      ),
      enableInteraction: false,
      belowLayerId: below,
    );
    await layerController.addLayer(
      "route",
      "route-layer",
      LineLayerProperties(
        lineWidth: fgLineWidth,
        lineColor: "#0073ff",
        lineJoin: "round",
      ),
      enableInteraction: false,
      belowLayerId: below,
    );
    return "route-layer";
  }

  update(LayerController layerController, {String? below}) async {
    await layerController.updateGeoJsonSource(
      "route",
      {"type": "FeatureCollection", "features": features},
    );
  }
}

class RouteLabelLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  RouteLabelLayer(BuildContext context) {
    final routing = Provider.of<Routing>(context, listen: false);
    final mapController = Provider.of<MapController>(context, listen: false);

    // Conditions for having route labels.
    if (mapController.controller != null &&
        mapController.controller!.cameraPosition != null &&
        routing.allRoutes != null &&
        routing.allRoutes!.length >= 2 &&
        routing.selectedRoute != null) {
      var distance = const LatLng2.Distance();

      double width = MediaQuery.of(context).size.width;
      double height = MediaQuery.of(context).size.height;
      double meterPerPixel = zoomToGeographicalDistance[mapController.controller!.cameraPosition!.zoom.toInt()] ?? 0;
      double cameraPosLat = mapController.controller!.cameraPosition!.target.latitude;
      double cameraPosLong = mapController.controller!.cameraPosition!.target.longitude;

      // Cast to LatLng2 format.
      LatLng2.LatLng cameraPos = LatLng2.LatLng(cameraPosLat, cameraPosLong);

      // Getting the bounds north, east, south, west.
      // Calculation of Bounding Points: Distance between camera position and the distance to the edge of the screen.
      LatLng2.LatLng north = distance.offset(cameraPos, height / 2 * meterPerPixel, 0);
      LatLng2.LatLng east = distance.offset(cameraPos, width / 2 * meterPerPixel, 90);
      LatLng2.LatLng south = distance.offset(cameraPos, height / 2 * meterPerPixel, 180);
      LatLng2.LatLng west = distance.offset(cameraPos, width / 2 * meterPerPixel, 270);

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
    LayerController layerController, {
    iconSize = 0.25,
    lineWidth = 7.0,
    clickWidth = 35.0,
    String? below,
  }) async {
    await layerController.addGeoJsonSource(
      "discomforts",
      {"type": "FeatureCollection", "features": features},
    );
    await layerController.addLayer(
      "discomforts",
      "discomforts-layer",
      LineLayerProperties(
        lineWidth: lineWidth,
        lineColor: "#e63328",
        lineCap: "round",
        lineJoin: "round",
      ),
      enableInteraction: false,
      belowLayerId: below,
    );
    await layerController.addLayer(
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
    );
    await layerController.addLayer(
      "discomforts",
      "discomforts-markers",
      SymbolLayerProperties(
        iconImage: "alert",
        iconSize: iconSize,
        textField: ["get", "number"],
        textSize: 12,
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
      enableInteraction: true,
      belowLayerId: below,
    );
    return "discomforts-layer";
  }

  /// Update the overlay on the layer controller (without updating the layers).
  update(LayerController layerController) async {
    await layerController.updateGeoJsonSource(
      "discomforts",
      {"type": "FeatureCollection", "features": features},
    );
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

  /// Install the overlay on the layer controller.
  Future<String> install(LayerController layerController, {iconSize = 0.75, String? below}) async {
    await layerController.addGeoJsonSource(
      "waypoints",
      {"type": "FeatureCollection", "features": features},
    );
    await layerController.addLayer(
      "waypoints",
      "waypoints-icons",
      SymbolLayerProperties(
        iconImage: [
          "case",
          ["get", "isFirst"],
          "start",
          ["get", "isLast"],
          "destination",
          "waypoint",
        ],
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      enableInteraction: false,
      belowLayerId: below,
    );
    return "waypoints-icons";
  }

  /// Update the overlay on the layer controller (without updating the layers).
  update(LayerController layerController) async {
    await layerController.updateGeoJsonSource(
      "waypoints",
      {"type": "FeatureCollection", "features": features},
    );
  }
}

class TrafficLightsLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  TrafficLightsLayer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showLabels = Provider.of<Settings>(context, listen: false).sgLabelsMode == SGLabelsMode.enabled;
    final statusProvider = Provider.of<PredictionSGStatus>(context, listen: false);
    final routing = Provider.of<Routing>(context, listen: false);
    for (final sg in routing.selectedRoute?.signalGroups ?? []) {
      final status = statusProvider.cache[sg.id];
      final isOffline = status == null ||
          status.predictionState == SGPredictionState.offline ||
          status.predictionState == SGPredictionState.bad;
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
            "isOffline": isOffline,
            "isDark": isDark,
            "showLabels": showLabels,
          },
        },
      );
    }
  }

  /// Install the overlay on the layer controller.
  Future<String> install(LayerController layerController, {iconSize = 1.0, String? below}) async {
    await layerController.addGeoJsonSource(
      "traffic-lights",
      {"type": "FeatureCollection", "features": features},
    );
    await layerController.addLayer(
      "traffic-lights",
      "traffic-lights-icons",
      SymbolLayerProperties(
        iconImage: [
          "case",
          ["get", "isOffline"],
          [
            "case",
            ["get", "isDark"],
            "trafficlightofflinedark",
            "trafficlightofflinelight",
          ],
          [
            "case",
            ["get", "isDark"],
            "trafficlightonlinedark",
            "trafficlightonlinelight",
          ],
        ],
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: showAfter(zoom: 12),
        textField: [
          "case",
          ["get", "showLabels"],
          ["get", "id"],
          ""
        ],
      ),
      enableInteraction: true,
      belowLayerId: below,
    );
    return "traffic-lights-icons";
  }

  /// Update the overlay on the layer controller (without updating the layers).
  update(LayerController layerController) async {
    await layerController.updateGeoJsonSource(
      "traffic-lights",
      {"type": "FeatureCollection", "features": features},
    );
  }
}

class TrafficLightLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  TrafficLightLayer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ride = Provider.of<Ride>(context, listen: false);
    final sgRec = ride.currentRecommendation;
    final sgIsGreen = ride.calcCurrentSignalIsGreen; // Computed by the app for higher precision.
    final sgPos = ride.currentRecommendation?.sg?.position;
    if (sgRec == null || sgIsGreen == null || sgPos == null) return;
    if (sgRec.error) return;
    if ((sgRec.quality ?? 0) < Ride.qualityThreshold) return;
    features.add(
      {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [sgPos.lon, sgPos.lat],
        },
        "properties": {
          "isGreen": sgIsGreen,
          "isDark": isDark,
        },
      },
    );
  }

  /// Install the overlay on the layer controller.
  Future<String> install(LayerController layerController, {iconSize = 1.0, String? below}) async {
    await layerController.addGeoJsonSource(
      "traffic-light",
      {"type": "FeatureCollection", "features": features},
    );
    await layerController.addLayer(
      "traffic-light",
      "traffic-light-icon",
      SymbolLayerProperties(
        iconImage: [
          "case",
          ["get", "isGreen"],
          [
            "case",
            ["get", "isDark"],
            "trafficlightonlinegreendark",
            "trafficlightonlinegreenlight",
          ],
          [
            "case",
            ["get", "isDark"],
            "trafficlightonlinereddark",
            "trafficlightonlineredlight",
          ],
        ],
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      enableInteraction: false,
      belowLayerId: below,
    );
    return "traffic-light-icon";
  }

  /// Update the overlay on the layer controller (without updating the layers).
  update(LayerController layerController) async {
    await layerController.updateGeoJsonSource(
      "traffic-light",
      {"type": "FeatureCollection", "features": features},
    );
  }
}

class OfflineCrossingsLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  OfflineCrossingsLayer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showLabels = Provider.of<Settings>(context, listen: false).sgLabelsMode == SGLabelsMode.enabled;
    final routing = Provider.of<Routing>(context, listen: false);
    for (final crossing in routing.selectedRoute?.crossings ?? []) {
      if (crossing.connected) continue;
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
          },
        },
      );
    }
  }

  /// Install the overlay on the layer controller.
  Future<String> install(LayerController layerController, {iconSize = 1.0, String? below}) async {
    await layerController.addGeoJsonSource(
      "offline-crossings",
      {"type": "FeatureCollection", "features": features},
    );
    await layerController.addLayer(
      "offline-crossings",
      "offline-crossings-icons",
      SymbolLayerProperties(
        iconImage: [
          "case",
          ["get", "isDark"],
          "trafficlightdisconnecteddark",
          "trafficlightdisconnectedlight",
        ],
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: showAfter(zoom: 12),
        textField: [
          "case",
          ["get", "showLabels"],
          ["get", "name"],
          ""
        ],
      ),
      enableInteraction: true,
      belowLayerId: below,
    );
    return "offline-crossings-icons";
  }

  /// Update the overlay on the layer controller (without updating the layers).
  update(LayerController layerController) async {
    await layerController.updateGeoJsonSource(
      "offline-crossings",
      {"type": "FeatureCollection", "features": features},
    );
  }
}

class ParkingStationsLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// The geojson file to display.
  final String file;

  ParkingStationsLayer(BuildContext context, {this.file = "assets/geo/bicycle_parking.geojson"})
      : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    await layerController.addGeoJsonSource(
      "parking-stations",
      jsonDecode(await rootBundle.loadString(file)),
    );
    await layerController.addLayer(
      "parking-stations",
      "parking-stations-icons",
      SymbolLayerProperties(
        iconImage: isDark ? "parkdark" : "parklight",
        iconSize: iconSize,
        iconOpacity: showAfter(zoom: 15),
      ),
    );
  }

  /// Remove the overlay from the layer controller.
  static removeFrom(LayerController layerController) async {
    await layerController.removeGeoJsonSourceAndLayers("parking-stations");
  }
}

class RentalStationsLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// The geojson file to display.
  final String file;

  RentalStationsLayer(BuildContext context, {this.file = "assets/geo/bicycle_rental.geojson"})
      : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    await layerController.addGeoJsonSource(
      "rental-stations",
      jsonDecode(await rootBundle.loadString(file)),
    );
    await layerController.addLayer(
      "rental-stations",
      "rental-stations-icons",
      SymbolLayerProperties(
        iconImage: isDark ? "rentdark" : "rentlight",
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconOpacity: showAfter(zoom: 15),
        textHaloColor: isDark ? "#000000" : "#ffffff",
        textHaloWidth: 1,
        textOffset: [
          Expressions.literal,
          [0, 2]
        ],
        textField: [
          "case",
          ["has", "name"],
          [
            // Concatenate "Ausleihstation" with the name of the station.
            "concat",
            "Fahrradleihe ",
            ["get", "name"]
          ],
          "Fahrradleihe "
        ],
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 12,
        textAnchor: "center",
        textColor: "#0075FF",
        textOpacity: showAfter(zoom: 17),
      ),
    );
  }

  /// Remove the overlay from the layer controller.
  static removeFrom(LayerController layerController) async {
    await layerController.removeGeoJsonSourceAndLayers("rental-stations");
  }
}

class BikeShopLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// The geojson file to display.
  final String file;

  BikeShopLayer(BuildContext context, {this.file = "assets/geo/bicycle_shop.geojson"})
      : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    await layerController.addGeoJsonSource(
      "bike-shop",
      jsonDecode(await rootBundle.loadString(file)),
    );
    await layerController.addLayer(
      "bike-shop",
      "bike-shop-icons",
      SymbolLayerProperties(
        iconImage: isDark ? "repairdark" : "repairlight",
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconOpacity: showAfter(zoom: 15),
        textHaloColor: isDark ? "#000000" : "#ffffff",
        textHaloWidth: 1,
        textOffset: [
          Expressions.literal,
          [0, 2]
        ],
        textField: [
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
        ],
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 12,
        textAnchor: "center",
        textColor: "#0075FF",
        textOpacity: showAfter(zoom: 17),
      ),
    );
  }

  /// Remove the overlay from the layer controller.
  static removeFrom(LayerController layerController) async {
    await layerController.removeGeoJsonSourceAndLayers("bike-shop");
  }
}

class BikeAirStationLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// The geojson file to display.
  final String file;

  BikeAirStationLayer(BuildContext context, {this.file = "assets/geo/bike_air_station.geojson"})
      : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    await layerController.addGeoJsonSource(
      "bike-air-station",
      jsonDecode(await rootBundle.loadString(file)),
    );
    await layerController.addLayer(
      "bike-air-station",
      "bike-air-station-icons",
      SymbolLayerProperties(
        iconImage: isDark ? "airdark" : "airlight",
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconOpacity: showAfter(zoom: 15),
        textHaloColor: isDark ? "#000000" : "#ffffff",
        textHaloWidth: 1,
        textOffset: [
          Expressions.literal,
          [0, 1]
        ],
        textField: [
          "case",
          ["has", "anmerkungen"],
          [
            // Concate "Luftstation" and the anmerkungen.
            "concat",
            "Luftstation ",
            ["get", "anmerkungen"]
          ],
          "Luftstation"
        ],
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 12,
        textAnchor: "center",
        textColor: "#0075FF",
        textOpacity: showAfter(zoom: 17),
      ),
    );
  }

  /// Remove the overlay from the layer controller.
  static removeFrom(LayerController layerController) async {
    await layerController.removeGeoJsonSourceAndLayers("bike-air-station");
  }
}

class ConstructionSitesLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// The geojson file to display.
  final String file;

  ConstructionSitesLayer(BuildContext context, {this.file = "assets/geo/construction_sides.geojson"})
      : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    await layerController.addGeoJsonSource(
      "construction-sites",
      jsonDecode(await rootBundle.loadString(file)),
    );
    await layerController.addLayer(
      "construction-sites",
      "construction-sites-icons",
      SymbolLayerProperties(
        iconImage: isDark ? "constructiondark" : "constructionlight",
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconOpacity: showAfter(zoom: 14),
        textHaloColor: isDark ? "#000000" : "#ffffff",
        textHaloWidth: 1,
        textOffset: [
          Expressions.literal,
          [0, 1]
        ],
        textField: "Baustelle",
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 12,
        textAnchor: "center",
        textColor: "#e67e22",
        textOpacity: showAfter(zoom: 15),
      ),
    );
  }

  /// Remove the overlay from the layer controller.
  static removeFrom(LayerController layerController) async {
    await layerController.removeGeoJsonSourceAndLayers("construction-sites");
  }
}

class AccidentHotspotsLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// The geojson file to display.
  final String file;

  AccidentHotspotsLayer(BuildContext context, {this.file = "assets/geo/accident_hot_spots.geojson"})
      : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    await layerController.addGeoJsonSource(
      "accident-hotspots",
      jsonDecode(await rootBundle.loadString(file)),
    );
    await layerController.addLayer(
      "accident-hotspots",
      "accident-hotspots-icons",
      SymbolLayerProperties(
        iconImage: isDark ? "accidentdark" : "accidentlight",
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconOpacity: showAfter(zoom: 13),
        textHaloColor: isDark ? "#000000" : "#ffffff",
        textHaloWidth: 1,
        textOffset: [
          Expressions.literal,
          [0, 1]
        ],
        textField: "Unfallschwerpunkt",
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 12,
        textAnchor: "center",
        textColor: "#ff4757",
        textOpacity: showAfter(zoom: 14),
      ),
    );
  }

  /// Remove the overlay from the layer controller.
  static removeFrom(LayerController layerController) async {
    await layerController.removeGeoJsonSourceAndLayers("accident-hotspots");
  }
}
