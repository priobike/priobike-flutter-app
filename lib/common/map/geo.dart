import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:provider/provider.dart';

/// A loader for map features.
class GeoFeatureLoader {
  /// The associated map controller.
  MapboxMapController mapController;

  /// Create a new geo feature loader.
  GeoFeatureLoader(this.mapController);

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
  Future<void> loadFeatures(BuildContext context) async {
    await addAccidentHotspots(context, "dresden", "assets/geo/accident_black_spots_dresden.geojson");
    await addAccidentHotspots(context, "hamburg", "assets/geo/accident_black_spots.geojson");

    final layers = Provider.of<Layers>(context, listen: false);
    if (layers.showParkingStations) {
      await addBikeParkingPoints(context, "hamburg", "assets/geo/bicycle_parking.geojson");
    }
    if (layers.showRentalStations) {
      await addBikeRentalPoints(context, "hamburg", "assets/geo/bicycle_rental.geojson");
    }
    if (layers.showRepairStations) {
      await addBikeShopPoints(context, "hamburg", "assets/geo/bicycle_shop.geojson");
    }
    if (layers.showAirStations) {
      await addBikeAirStations(context, "hamburg", "assets/geo/bike_air_station.geojson");
    }
    if (layers.showConstructionSites) {
      await addConstructionSites(context, "hamburg", "assets/geo/construction_sides.geojson");
    }
  }

  /// Remove all geo features from the map controller.
  Future<void> removeFeatures() async {
    await removeAccidentHotspots("dresden");
    await removeAccidentHotspots("hamburg");
    await removeBikeParkingPoints("hamburg");
    await removeBikeRentalPoints("hamburg");
    await removeBikeShopPoints("hamburg");
    await removeBikeAirStations("hamburg");
    await removeConstructionSites("hamburg");
  }

  /// Add layers for accident hotspots.
  Future<void> addAccidentHotspots(BuildContext context, String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the accident hotspots to the map.
    await mapController.setGeoJsonSource("$layerPrefix-accident-hotspots", d);
    // Add a fill to the polygons.
    await mapController.addLayer(
      "$layerPrefix-accident-hotspots", 
      "$layerPrefix-accident-hotspots-fill", 
      const FillLayerProperties(
        fillOpacity: 0.25,
        fillColor: "#ff0000"
      ),
      enableInteraction: false,
    );
    // Add a line to the polygons.
    await mapController.addLayer(
      "$layerPrefix-accident-hotspots", 
      "$layerPrefix-accident-hotspots-line", 
      LineLayerProperties(
        lineColor: "#ff0000",
        lineWidth: 2,
        lineOpacity: showAfter(zoom: 14),
      ),
      enableInteraction: false,
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
      ),
      enableInteraction: false,
    );
  }

  /// Remove layers for accident hotspots.
  Future<void> removeAccidentHotspots(String layerPrefix) async {
    await mapController.removeLayer("$layerPrefix-accident-hotspots-fill");
    await mapController.removeLayer("$layerPrefix-accident-hotspots-line");
    await mapController.removeLayer("$layerPrefix-accident-hotspots-label");
    await mapController.removeSource("$layerPrefix-accident-hotspots");
  }

  /// Add points for bike parking.
  Future<void> addBikeParkingPoints(BuildContext context, String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));

    await mapController.setGeoJsonSource("$layerPrefix-bike-parking-points", d);
    await mapController.setGeoJsonSource("$layerPrefix-bike-parking-polygons", d);
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

  /// Remove points for bike parking.
  Future<void> removeBikeParkingPoints(String layerPrefix) async {
    for (final layer in ["$layerPrefix-bike-parking-points", "$layerPrefix-bike-parking-polygons"]) {
      await mapController.removeLayer("$layer-$layerPrefix-bike-parking-points-label");
    }
    await mapController.removeSource("$layerPrefix-bike-parking-points");
    await mapController.removeSource("$layerPrefix-bike-parking-polygons");
  }

  /// Add points for bike rental.
  Future<void> addBikeRentalPoints(BuildContext context, String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    await mapController.setGeoJsonSource("$layerPrefix-bike-rental-points", d);
    await mapController.setGeoJsonSource("$layerPrefix-bike-rental-polygons", d);
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

  /// Remove points for bike rental.
  Future<void> removeBikeRentalPoints(String layerPrefix) async {
    for (final layer in ["$layerPrefix-bike-rental-points", "$layerPrefix-bike-rental-polygons"]) {
      await mapController.removeLayer("$layer-$layerPrefix-bike-rental-points-label");
    }
    await mapController.removeSource("$layerPrefix-bike-rental-points");
    await mapController.removeSource("$layerPrefix-bike-rental-polygons");
  }

  /// Add points for bike shops.
  Future<void> addBikeShopPoints(BuildContext context, String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the bike shop to the map.
    await mapController.setGeoJsonSource("$layerPrefix-bike-shop-points", d);
    await mapController.setGeoJsonSource("$layerPrefix-bike-shop-polygons", d);
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

  /// Remove points for bike shops.
  Future<void> removeBikeShopPoints(String layerPrefix) async {
    for (final layer in ["$layerPrefix-bike-shop-points", "$layerPrefix-bike-shop-polygons"]) {
      await mapController.removeLayer("$layer-$layerPrefix-bike-shop-points-label");
    }
    await mapController.removeSource("$layerPrefix-bike-shop-points");
    await mapController.removeSource("$layerPrefix-bike-shop-polygons");
  }

  /// Add layers for bike air stations.
  Future<void> addBikeAirStations(BuildContext context, String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the bike air station to the map.
    await mapController.setGeoJsonSource("$layerPrefix-bike-air-stations", d);
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

  /// Remove layers for bike air stations.
  Future<void> removeBikeAirStations(String layerPrefix) async {
    await mapController.removeLayer("$layerPrefix-bike-air-stations-label");
    await mapController.removeSource("$layerPrefix-bike-air-stations");
  }

  /// Add layers for construction sites.
  Future<void> addConstructionSites(BuildContext context, String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the construction sites to the map.
    await mapController.setGeoJsonSource("$layerPrefix-construction-sites", d);
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

  /// Remove layers for construction sites.
  Future<void> removeConstructionSites(String layerPrefix) async {
    await mapController.removeLayer("$layerPrefix-construction-sites-label");
    await mapController.removeSource("$layerPrefix-construction-sites");
  }
}