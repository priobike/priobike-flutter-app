import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

/// A loader for map features.
class GeoFeatureLoader {
  /// The associated map controller.
  MapboxMapController mapController;

  /// The build context.
  BuildContext context;

  /// Create a new geo feature loader.
  GeoFeatureLoader(this.mapController, this.context);

  /// Fade a layer out before a specific zoom level.
  static dynamic showAfter({required int zoom, double opacity = 1.0}) => [
    "interpolate",
    ["linear"],
    ["zoom"],
    0, 0,
    zoom - 1, 0,
    zoom, opacity,
  ];

  /// Load geo features into the map controller.
  Future<void> loadFeatures() async {
    await addAccidentHotspots("dresden", "assets/geo/accident_black_spots_dresden.geojson");
    await addAccidentHotspots("hamburg", "assets/geo/accident_black_spots.geojson");
    await addBikeParkingPoints("hamburg", "assets/geo/bicycle_parking.geojson");
    await addBikeRentalPoints("hamburg", "assets/geo/bicycle_rental.geojson");
    await addBikeShopPoints("hamburg", "assets/geo/bicycle_shop.geojson");
    await addBikeAirStations("hamburg", "assets/geo/bike_air_station.geojson");
    await addConstructionSites("hamburg", "assets/geo/construction_sides.geojson");
  }

  /// Add layers for accident hotspots.
  Future<void> addAccidentHotspots(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the accident hotspots to the map.
    await mapController.removeSource("$layerPrefix-accident-hotspots");
    await mapController.addSource(
      "$layerPrefix-accident-hotspots", 
      GeojsonSourceProperties(data: d)
    );
    // Add a fill to the polygons.
    await mapController.addLayer(
      "$layerPrefix-accident-hotspots", 
      "$layerPrefix-accident-hotspots-fill", 
      const FillLayerProperties(
        fillOpacity: 0.25,
        fillColor: "#ff0000"
      )
    );
    // Add a line to the polygons.
    await mapController.addLayer(
      "$layerPrefix-accident-hotspots", 
      "$layerPrefix-accident-hotspots-line", 
      LineLayerProperties(
        lineColor: "#ff0000",
        lineWidth: 2,
        lineOpacity: showAfter(zoom: 14),
      )
    );
    // Add a label to the polygons.
    await mapController.addLayer(
      "$layerPrefix-accident-hotspots", 
      "$layerPrefix-accident-hotspots-label", 
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
      )
    );
  }

  /// Add points for bike parking.
  Future<void> addBikeParkingPoints(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));

    await mapController.removeSource("$layerPrefix-bike-parking-points");
    await mapController.addSource(
      "$layerPrefix-bike-parking-points", 
      GeojsonSourceProperties(data: d)
    );
    await mapController.removeSource("$layerPrefix-bike-parking-polygons");
    await mapController.addSource(
      "$layerPrefix-bike-parking-polygons", 
      GeojsonSourceProperties(data: d)
    );
    for (final layer in ["$layerPrefix-bike-parking-points", "$layerPrefix-bike-parking-polygons"]) {
      await mapController.addLayer(layer, "$layer-$layerPrefix-bike-parking-points-label", 
        SymbolLayerProperties(
          iconImage: Theme.of(context).colorScheme.brightness == Brightness.light
            ? "parklight"
            : "parkdark",
          iconSize: 1.0,
          iconOpacity: showAfter(zoom: 15),
        ),
      );
    }
  }

  /// Add points for bike rental.
  Future<void> addBikeRentalPoints(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    await mapController.removeSource("$layerPrefix-bike-rental-points");
    await mapController.addSource(
      "$layerPrefix-bike-rental-points", 
      GeojsonSourceProperties(data: d)
    );
    await mapController.removeSource("$layerPrefix-bike-rental-polygons");
    await mapController.addSource(
      "$layerPrefix-bike-rental-polygons", 
      GeojsonSourceProperties(data: d)
    );
    for (final layer in ["$layerPrefix-bike-rental-points", "$layerPrefix-bike-rental-polygons"]) {
      await mapController.addLayer(layer, "$layer-$layerPrefix-bike-rental-points-label", 
        SymbolLayerProperties(
          iconImage: Theme.of(context).colorScheme.brightness == Brightness.light
            ? "rentlight"
            : "rentdark",
          iconSize: 1.0,
          iconAllowOverlap: true,
          iconOpacity: showAfter(zoom: 15),
          textHaloColor: Theme.of(context).colorScheme.brightness == Brightness.light
            ? "#ffffff"
            : "#000000",
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
        )
      );
    }
  }

  /// Add points for bike shops.
  Future<void> addBikeShopPoints(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the bike shop to the map.
    await mapController.removeSource("$layerPrefix-bike-shop-points");
    await mapController.addSource(
      "$layerPrefix-bike-shop-points", 
      GeojsonSourceProperties(data: d)
    );
    await mapController.removeSource("$layerPrefix-bike-shop-polygons");
    await mapController.addSource(
      "$layerPrefix-bike-shop-polygons", 
      GeojsonSourceProperties(data: d)
    );
    for (final layer in ["$layerPrefix-bike-shop-points", "$layerPrefix-bike-shop-polygons"]) {
      await mapController.addLayer(layer, "$layer-$layerPrefix-bike-shop-points-label", 
        SymbolLayerProperties(
          iconImage: Theme.of(context).colorScheme.brightness == Brightness.light
            ? "repairlight"
            : "repairdark",
          iconSize: 1.0,
          iconAllowOverlap: true,
          iconOpacity: showAfter(zoom: 15),
          textHaloColor: Theme.of(context).colorScheme.brightness == Brightness.light
            ? "#ffffff"
            : "#000000",
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
              ["==", ["get", "name"], " "],
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
        )
      );
    }
  }

  /// Add layers for bike air stations.
  Future<void> addBikeAirStations(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the bike air station to the map.
    await mapController.removeSource("$layerPrefix-bike-air-stations");
    await mapController.addSource(
      "$layerPrefix-bike-air-stations", 
      GeojsonSourceProperties(data: d)
    );
    await mapController.addLayer(
      "$layerPrefix-bike-air-stations", 
      "$layerPrefix-bike-air-stations-label", 
      SymbolLayerProperties(
        iconImage: Theme.of(context).colorScheme.brightness == Brightness.light
          ? "airlight"
          : "airdark",
        iconSize: 1.0,
        iconAllowOverlap: true,
        iconOpacity: showAfter(zoom: 15),
        textHaloColor: Theme.of(context).colorScheme.brightness == Brightness.light
          ? "#ffffff"
          : "#000000",
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
      )
    );
  }

  /// Add layers for construction sites.
  Future<void> addConstructionSites(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the construction sites to the map.
    await mapController.removeSource("$layerPrefix-construction-sites");
    await mapController.addSource(
      "$layerPrefix-construction-sites", 
      GeojsonSourceProperties(data: d)
    );
    // Add a label and a symbol to the polygons.
    await mapController.addLayer(
      "$layerPrefix-construction-sites", 
      "$layerPrefix-construction-sites-label", 
      SymbolLayerProperties(
        iconImage: Theme.of(context).colorScheme.brightness == Brightness.light
          ? "constructionlight"
          : "constructiondark",
        iconSize: 1.0,
        iconAllowOverlap: true,
        iconOpacity: showAfter(zoom: 14),
        textHaloColor: Theme.of(context).colorScheme.brightness == Brightness.light
          ? "#ffffff"
          : "#000000",
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
      )
    );
  }
}