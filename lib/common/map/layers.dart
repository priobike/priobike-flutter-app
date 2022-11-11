import 'dart:convert';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/controller.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';

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
      features.add({
        "id": "route-${entry.key}", // Required for click listener.
        "type": "Feature",
        "geometry": geometry,
      });
    }
  }

  /// Install the overlay on the layer controller.
  addTo(LayerController layerController, {lineWidth = 9.0, clickLineWidth = 25.0}) async {
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
      belowLayerId: "discomforts-layer",
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
      belowLayerId: "discomforts-layer",
    );
  }
}

class SelectedRouteLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  SelectedRouteLayer(BuildContext context) {
    final routing = Provider.of<Routing>(context, listen: false);
    final geometry = {
      "type": "LineString",
      "coordinates": routing.selectedRoute?.route.map((e) => [e.lon, e.lat]).toList() ?? [],
    };
    final feature = {
      "type": "Feature",
      "properties": {},
      "geometry": geometry,
    };
    features.add(feature);
  }

  /// Install the overlay on the layer controller.
  addTo(LayerController layerController, {bgLineWidth = 9.0, fgLineWidth = 7.0}) async {
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
      belowLayerId: "discomforts-layer",
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
      belowLayerId: "discomforts-layer",
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
      features.add({
        "id": "discomfort-${e.key}", // Required for click listener.
        "type": "Feature",
        "properties": {
          "number": e.key + 1,
        },
        "geometry": geometry,
      });
    }
  }

  /// Install the overlay on the layer controller.
  addTo(LayerController layerController, {iconSize = 0.25, lineWidth = 7.0, clickWidth = 35.0}) async {
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
      belowLayerId: "discomforts-clicklayer",
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
      belowLayerId: "discomforts-markers",
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
    );
  }
}

class WaypointsLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  WaypointsLayer(BuildContext context) {
    final routing = Provider.of<Routing>(context, listen: false);
    final waypoints = routing.selectedWaypoints ?? [];
    for (MapEntry<int, Waypoint> entry in waypoints.asMap().entries) {
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [entry.value.lon, entry.value.lat],
        },
        "properties": {
          "isFirst": entry.key == 0,
          "isLast": entry.key == waypoints.length - 1,
        },
      });
    }
  }

  /// Install the overlay on the layer controller.
  addTo(LayerController layerController, {iconSize = 0.75}) async {
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
    );
  }
}

class TrafficLightsLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// If the layer should display labels.
  final bool showLabels;

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  TrafficLightsLayer(BuildContext context)
      : isDark = Theme.of(context).brightness == Brightness.dark,
        showLabels = Provider.of<Settings>(context, listen: false).sgLabelsMode == SGLabelsMode.enabled {
    final statusProvider = Provider.of<PredictionSGStatus>(context, listen: false);
    final routing = Provider.of<Routing>(context, listen: false);
    for (final sg in routing.selectedRoute?.signalGroups ?? []) {
      final status = statusProvider.cache[sg.id];
      final isOffline = status == null ||
          status.predictionState == SGPredictionState.offline ||
          status.predictionState == SGPredictionState.bad;
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [sg.position.lon, sg.position.lat],
        },
        "properties": {
          "id": sg.id,
          "isOffline": isOffline,
        },
      });
    }
  }

  /// Install the overlay on the layer controller.
  addTo(LayerController layerController, {iconSize = 1.0}) async {
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
          isDark ? "trafficlightofflinedark" : "trafficlightofflinelight",
          isDark ? "trafficlightonlinedark" : "trafficlightonlinelight",
        ],
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: showAfter(zoom: 12),
        textField: showLabels ? ["get", "id"] : null,
      ),
      enableInteraction: false,
    );
  }
}

class OfflineCrossingsLayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// If the layer should display labels.
  final bool showLabels;

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  OfflineCrossingsLayer(BuildContext context)
      : isDark = Theme.of(context).brightness == Brightness.dark,
        showLabels = Provider.of<Settings>(context, listen: false).sgLabelsMode == SGLabelsMode.enabled {
    final routing = Provider.of<Routing>(context, listen: false);
    for (final crossing in routing.selectedRoute?.crossings ?? []) {
      if (crossing.connected) continue;
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [crossing.position.lon, crossing.position.lat],
        },
        "properties": {
          "name": crossing.name,
        },
      });
    }
  }

  /// Install the overlay on the layer controller.
  addTo(LayerController layerController, {iconSize = 1.0}) async {
    await layerController.addGeoJsonSource(
      "offline-crossings",
      {"type": "FeatureCollection", "features": features},
    );
    await layerController.addLayer(
      "offline-crossings",
      "offline-crossings-icons",
      SymbolLayerProperties(
        iconImage: isDark ? "trafficlightdisconnecteddark" : "trafficlightdisconnectedlight",
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: showAfter(zoom: 12),
        textField: showLabels ? ["get", "name"] : null,
      ),
      enableInteraction: false,
    );
  }
}

class AccidentHotspotsLayer {
  /// The geojson file to display.
  final String file;

  AccidentHotspotsLayer(BuildContext context, {this.file = "assets/geo/accident_black_spots.geojson"});

  /// Install the overlay on the layer controller.
  addTo(LayerController layerController) async {
    await layerController.addGeoJsonSource(
      "accident-hotspots",
      jsonDecode(await rootBundle.loadString(file)),
    );
    // Add a fill to the polygons.
    await layerController.addLayer(
      "accident-hotspots",
      "accident-hotspots-fill",
      const FillLayerProperties(fillOpacity: 0.25, fillColor: "#ff0000"),
      enableInteraction: false,
    );
    // Add a line to the polygons.
    await layerController.addLayer(
      "accident-hotspots",
      "accident-hotspots-line",
      LineLayerProperties(
        lineColor: "#ff0000",
        lineWidth: 2,
        lineOpacity: showAfter(zoom: 14),
      ),
      enableInteraction: false,
    );
    // Add a label to the polygons.
    await layerController.addLayer(
      "accident-hotspots",
      "accident-hotspots-label",
      SymbolLayerProperties(
        textField: "Erhöhte Unfallgefahr für Radfahrer",
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 14,
        textOffset: [
          Expressions.literal,
          [0, 5]
        ],
        textAnchor: "bottom",
        textColor: "#ff0000",
        textOpacity: showAfter(zoom: 15),
      ),
      enableInteraction: false,
    );
  }

  /// Remove the overlay from the layer controller.
  static removeFrom(LayerController layerController) async {
    await layerController.removeGeoJsonSourceAndLayers("accident-hotspots");
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
  addTo(LayerController layerController, {iconSize = 1.0}) async {
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
  addTo(LayerController layerController, {iconSize = 1.0}) async {
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
  addTo(LayerController layerController, {iconSize = 1.0}) async {
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
  addTo(LayerController layerController, {iconSize = 1.0}) async {
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
  addTo(LayerController layerController, {iconSize = 1.0}) async {
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
