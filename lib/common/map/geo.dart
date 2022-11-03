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
        0,
        0,
        zoom - 1,
        0,
        zoom,
        opacity,
      ];

  /// Load geo features into the map controller.
  Future<void> initSources() async {
    await initAccidentHotspots("dresden", "assets/geo/accident_black_spots_dresden.geojson");
    await initAccidentHotspots("hamburg", "assets/geo/accident_black_spots.geojson");
    await initBikeParkingPoints("hamburg", "assets/geo/bicycle_parking.geojson");
    await initBikeRentalPoints("hamburg", "assets/geo/bicycle_rental.geojson");
    await initBikeShopPoints("hamburg", "assets/geo/bicycle_shop.geojson");
    await initBikeAirStations("hamburg", "assets/geo/bike_air_station.geojson");
    await initConstructionSites("hamburg", "assets/geo/construction_sides.geojson");
  }

  /// Load geo features into the map controller.
  Future<void> loadFeatures(BuildContext context) async {
    await addAccidentHotspots(context, "dresden");
    await addAccidentHotspots(context, "hamburg");

    final layers = Provider.of<Layers>(context, listen: false);
    if (layers.showParkingStations) {
      await addBikeParkingPoints(context, "hamburg");
    }
    if (layers.showRentalStations) {
      await addBikeRentalPoints(context, "hamburg");
    }
    if (layers.showRepairStations) {
      await addBikeShopPoints(context, "hamburg");
    }
    if (layers.showAirStations) {
      await addBikeAirStations(context, "hamburg");
    }
    if (layers.showConstructionSites) {
      await addConstructionSites(context, "hamburg");
    }
  }

  /// Remove all geo features from the map controller.
  Future<void> removeFeatures(bool dispose) async {
    await removeAccidentHotspots("dresden", dispose);
    await removeAccidentHotspots("hamburg", dispose);
    await removeBikeParkingPoints("hamburg", dispose);
    await removeBikeRentalPoints("hamburg", dispose);
    await removeBikeShopPoints("hamburg", dispose);
    await removeBikeAirStations("hamburg", dispose);
    await removeConstructionSites("hamburg", dispose);
  }

  /// Add layers for accident hotspots.
  Future<void> addAccidentHotspots(BuildContext context, String layerPrefix) async {
    // Add a fill to the polygons.
    await mapController.addLayer(
      "$layerPrefix-accident-hotspots",
      "$layerPrefix-accident-hotspots-fill",
      const FillLayerProperties(fillOpacity: 0.25, fillColor: "#ff0000"),
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

  /// Add sources for bike parking.
  Future<void> initAccidentHotspots(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the bike shop to the map.
    await mapController.addSource("$layerPrefix-accident-hotspots", GeojsonSourceProperties(data: d));
  }

  /// Remove layers for accident hotspots.
  Future<void> removeAccidentHotspots(String layerPrefix, bool dispose) async {
    if (dispose) {
      // await mapController.removeSource("$layerPrefix-accident-hotspots");
    } else {
      await mapController.removeLayer("$layerPrefix-accident-hotspots-fill");
      await mapController.removeLayer("$layerPrefix-accident-hotspots-line");
      await mapController.removeLayer("$layerPrefix-accident-hotspots-label");
    }
  }

  /// Add points for bike parking.
  Future<void> addBikeParkingPoints(BuildContext context, String layerPrefix) async {
    for (final layer in ["$layerPrefix-bike-parking-points", "$layerPrefix-bike-parking-polygons"]) {
      await mapController.addLayer(
        layer,
        "$layer-$layerPrefix-bike-parking-points-label",
        SymbolLayerProperties(
          iconImage: Theme.of(context).colorScheme.brightness == Brightness.light ? "parklight" : "parkdark",
          iconSize: 1.0,
          iconOpacity: showAfter(zoom: 15),
        ),
      );
    }
  }

  /// Add sources for bike parking.
  Future<void> initBikeParkingPoints(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the bike shop to the map.
    await mapController.addSource("$layerPrefix-bike-parking-points", GeojsonSourceProperties(data: d));
    await mapController.addSource("$layerPrefix-bike-parking-polygons", GeojsonSourceProperties(data: d));
  }

  /// Remove points for bike parking.
  Future<void> removeBikeParkingPoints(String layerPrefix, bool dispose) async {
    if (dispose) {
      // await mapController.removeSource("$layerPrefix-bike-parking-points");
      // await mapController.removeSource("$layerPrefix-bike-parking-polygons");
    } else {
      for (final layer in ["$layerPrefix-bike-parking-points", "$layerPrefix-bike-parking-polygons"]) {
        await mapController.removeLayer("$layer-$layerPrefix-bike-parking-points-label");
      }
    }
  }

  /// Add points for bike rental.
  Future<void> addBikeRentalPoints(BuildContext context, String layerPrefix) async {
    for (final layer in ["$layerPrefix-bike-rental-points", "$layerPrefix-bike-rental-polygons"]) {
      await mapController.addLayer(
          layer,
          "$layer-$layerPrefix-bike-rental-points-label",
          SymbolLayerProperties(
            iconImage: Theme.of(context).colorScheme.brightness == Brightness.light ? "rentlight" : "rentdark",
            iconSize: 1.0,
            iconAllowOverlap: true,
            iconOpacity: showAfter(zoom: 15),
            textHaloColor: Theme.of(context).colorScheme.brightness == Brightness.light ? "#ffffff" : "#000000",
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
          ));
    }
  }

  /// Add sources for bike rental.
  Future<void> initBikeRentalPoints(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the bike shop to the map.
    await mapController.addSource("$layerPrefix-bike-rental-points", GeojsonSourceProperties(data: d));
    await mapController.addSource("$layerPrefix-bike-rental-polygons", GeojsonSourceProperties(data: d));
  }

  /// Remove points for bike rental.
  Future<void> removeBikeRentalPoints(String layerPrefix, bool dispose) async {
    if (dispose) {
      // await mapController.removeSource("$layerPrefix-bike-rental-points");
      // await mapController.removeSource("$layerPrefix-bike-rental-polygons");
    } else {
      for (final layer in ["$layerPrefix-bike-rental-points", "$layerPrefix-bike-rental-polygons"]) {
        await mapController.removeLayer("$layer-$layerPrefix-bike-rental-points-label");
      }
    }
  }

  /// Add points for bike shops.
  Future<void> addBikeShopPoints(BuildContext context, String layerPrefix) async {
    for (final layer in ["$layerPrefix-bike-shop-points", "$layerPrefix-bike-shop-polygons"]) {
      await mapController.addLayer(
          layer,
          "$layer-$layerPrefix-bike-shop-points-label",
          SymbolLayerProperties(
            iconImage: Theme.of(context).colorScheme.brightness == Brightness.light ? "repairlight" : "repairdark",
            iconSize: 1.0,
            iconAllowOverlap: true,
            iconOpacity: showAfter(zoom: 15),
            textHaloColor: Theme.of(context).colorScheme.brightness == Brightness.light ? "#ffffff" : "#000000",
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
          ));
    }
  }

  /// Add layers for construction sites.
  Future<void> initBikeShopPoints(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the bike shop to the map.
    await mapController.addSource("$layerPrefix-bike-shop-points", GeojsonSourceProperties(data: d));
    await mapController.addSource("$layerPrefix-bike-shop-polygons", GeojsonSourceProperties(data: d));
  }

  /// Remove points for bike shops.
  Future<void> removeBikeShopPoints(String layerPrefix, dispose) async {
    if (dispose) {
      // await mapController.removeSource("$layerPrefix-bike-shop-points");
      // await mapController.removeSource("$layerPrefix-bike-shop-polygons");
    } else {
      for (final layer in ["$layerPrefix-bike-shop-points", "$layerPrefix-bike-shop-polygons"]) {
        await mapController.removeLayer("$layer-$layerPrefix-bike-shop-points-label");
      }
    }
  }

  /// Add layers for bike air stations.
  Future<void> addBikeAirStations(BuildContext context, String layerPrefix) async {
    await mapController.addLayer(
        "$layerPrefix-bike-air-stations",
        "$layerPrefix-bike-air-stations-label",
        SymbolLayerProperties(
          iconImage: Theme.of(context).colorScheme.brightness == Brightness.light ? "airlight" : "airdark",
          iconSize: 1.0,
          iconAllowOverlap: true,
          iconOpacity: showAfter(zoom: 15),
          textHaloColor: Theme.of(context).colorScheme.brightness == Brightness.light ? "#ffffff" : "#000000",
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
        ));
  }

  /// Add layers for construction sites.
  Future<void> initBikeAirStations(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the bike air station to the map.
    await mapController.addSource("$layerPrefix-bike-air-stations", GeojsonSourceProperties(data: d));
  }

  /// Remove layers for bike air stations.
  Future<void> removeBikeAirStations(String layerPrefix, bool dispose) async {
    if (dispose) {
      // await mapController.removeSource("$layerPrefix-bike-air-stations");
    } else {
      await mapController.removeLayer("$layerPrefix-bike-air-stations-label");
    }
  }

  /// Add layers for construction sites.
  Future<void> addConstructionSites(BuildContext context, String layerPrefix) async {
    // Add a label and a symbol to the polygons.
    await mapController.addLayer(
        "$layerPrefix-construction-sites",
        "$layerPrefix-construction-sites-label",
        SymbolLayerProperties(
          iconImage:
              Theme.of(context).colorScheme.brightness == Brightness.light ? "constructionlight" : "constructiondark",
          iconSize: 1.0,
          iconAllowOverlap: true,
          iconOpacity: showAfter(zoom: 14),
          textHaloColor: Theme.of(context).colorScheme.brightness == Brightness.light ? "#ffffff" : "#000000",
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
        ));
  }

  /// Add layers for construction sites.
  Future<void> initConstructionSites(String layerPrefix, String file) async {
    final d = jsonDecode(await rootBundle.loadString(file));
    // Add the construction sites to the map.
    // await mapController.setGeoJsonSource("$layerPrefix-construction-sites", d);
    await mapController.addSource("$layerPrefix-construction-sites", GeojsonSourceProperties(data: d));
  }

  /// Remove layers for construction sites.
  Future<void> removeConstructionSites(String layerPrefix, bool dispose) async {
    if (dispose) {
      // This seems not to work currently. The question is if it gets garbage collected automatically?
      // await mapController.removeSource("$layerPrefix-construction-sites");
    } else {
      await mapController.removeLayer("$layerPrefix-construction-sites-label");
    }
  }
}
