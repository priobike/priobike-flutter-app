import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/common/map/controller.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/sg_labels.dart';
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
      enableInteraction: false,
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
        iconImage: ["get", "sgIcon"],
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
      enableInteraction: false,
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

  /// BuildContext of the widget
  final BuildContext context;

  ParkingStationsLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    await layerController.addExternalGeoJsonSource(
      "parking-stations",
      "https://$baseUrl/map-data/bicycle_parking.geojson",
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

  /// BuildContext of the widget
  final BuildContext context;

  RentalStationsLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    await layerController.addExternalGeoJsonSource(
      "rental-stations",
      "https://$baseUrl/map-data/bicycle_rental.geojson",
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

  /// BuildContext of the widget
  final BuildContext context;

  BikeShopLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    await layerController.addExternalGeoJsonSource(
      "bike-shop",
      "https://$baseUrl/map-data/bicycle_shop.geojson",
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

  final BuildContext context;

  BikeAirStationLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    await layerController.addExternalGeoJsonSource(
      "bike-air-station",
      "https://$baseUrl/map-data/bike_air_station.geojson",
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

  /// BuildContext of the widget
  final BuildContext context;

  ConstructionSitesLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    await layerController.addExternalGeoJsonSource(
      "construction-sites",
      "https://$baseUrl/map-data/construction_sites.geojson",
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

  /// Build context of the widget
  final BuildContext context;

  AccidentHotspotsLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the overlay on the layer controller.
  install(LayerController layerController, {iconSize = 1.0}) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    await layerController.addExternalGeoJsonSource(
      "accident-hotspots",
      "https://$baseUrl/map-data/accident_hot_spots.geojson",
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
