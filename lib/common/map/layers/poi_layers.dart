import 'dart:convert';

import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

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

    final sourceExists = await mapController.style.styleSourceExists("parking-stations");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "parking-stations", data: "https://$baseUrl/map-data/bicycle_parking.geojson"),
      );
    }

    final parkingStationsIconsLayerExists = await mapController.style.styleLayerExists("parking-stations-icons");
    if (!parkingStationsIconsLayerExists) {
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
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    final parkingStationIconsLayerExists = await mapController.style.styleLayerExists("parking-stations-icons");
    if (parkingStationIconsLayerExists) {
      await mapController.style.removeStyleLayer("parking-stations-icons");
    }
    final sourceExists = await mapController.style.styleSourceExists("parking-stations");
    if (sourceExists) {
      await mapController.style.removeStyleSource("parking-stations");
    }
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

    final sourceExists = await mapController.style.styleSourceExists("rental-stations");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "rental-stations", data: "https://$baseUrl/map-data/bicycle_rental.geojson"),
      );
    }

    final rentalStationIconsLayerExists = await mapController.style.styleLayerExists("rental-stations-icons");
    if (!rentalStationIconsLayerExists) {
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
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    final rentalStationIconsLayerExists = await mapController.style.styleLayerExists("rental-stations-icons");
    if (rentalStationIconsLayerExists) {
      await mapController.style.removeStyleLayer("rental-stations-icons");
    }
    final sourceExists = await mapController.style.styleSourceExists("rental-stations");
    if (sourceExists) {
      await mapController.style.removeStyleSource("rental-stations");
    }
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

    final sourceExists = await mapController.style.styleSourceExists("bike-shop");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "bike-shop", data: "https://$baseUrl/map-data/bicycle_shop.geojson"),
      );
    }

    final bikeShopIconsLayerExists = await mapController.style.styleLayerExists("bike-shop-icons");
    if (!bikeShopIconsLayerExists) {
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
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    final bikeShopIconsLayerExists = await mapController.style.styleLayerExists("bike-shop-icons");
    if (bikeShopIconsLayerExists) {
      await mapController.style.removeStyleLayer("bike-shop-icons");
    }
    final sourceExists = await mapController.style.styleSourceExists("bike-shop");
    if (sourceExists) {
      await mapController.style.removeStyleSource("bike-shop");
    }
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

    final sourceExists = await mapController.style.styleSourceExists("bike-air-station");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "bike-air-station", data: "https://$baseUrl/map-data/bike_air_station.geojson"),
      );
    }
    final bikeAirStationIconsLayer = await mapController.style.styleLayerExists("bike-air-station-icons");
    if (!bikeAirStationIconsLayer) {
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
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    final bikeAirStationIconsLayer = await mapController.style.styleLayerExists("bike-air-station-icons");
    if (bikeAirStationIconsLayer) {
      await mapController.style.removeStyleLayer("bike-air-station-icons");
    }
    final sourceExists = await mapController.style.styleSourceExists("bike-air-station");
    if (sourceExists) {
      await mapController.style.removeStyleSource("bike-air-station");
    }
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
    final sourceExists = await mapController.style.styleSourceExists("construction-sites");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "construction-sites", data: "https://$baseUrl/map-data/construction_sites.geojson"),
      );
    }
    final constructionSitesIconsLayerExists = await mapController.style.styleLayerExists("construction-sites-icons");
    if (!constructionSitesIconsLayerExists) {
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
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    final constructionSitesIconsLayerExists = await mapController.style.styleLayerExists("construction-sites-icons");
    if (constructionSitesIconsLayerExists) {
      await mapController.style.removeStyleLayer("construction-sites-icons");
    }
    final sourceExists = await mapController.style.styleSourceExists("construction-sites");
    if (sourceExists) {
      await mapController.style.removeStyleSource("construction-sites");
    }
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
    final sourceExists = await mapController.style.styleSourceExists("accident-hotspots");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "accident-hotspots", data: "https://$baseUrl/map-data/accident_hot_spots.geojson"),
      );
    }
    final accidentHotspotsIconsLayerExists = await mapController.style.styleLayerExists("accident-hotspots-icons");
    if (!accidentHotspotsIconsLayerExists) {
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
      await mapController.style.setStyleLayerProperty("accident-hotspots-icons", 'text-field', 'Unfall-\nschwerpunkt');
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
  }

  /// Remove the overlay from the map controller.
  static removeFrom(mapbox.MapboxMap mapController) async {
    final accidentHotspotsIconsLayerExists = await mapController.style.styleLayerExists("accident-hotspots-icons");
    if (accidentHotspotsIconsLayerExists) {
      await mapController.style.removeStyleLayer("accident-hotspots-icons");
    }
    final sourceExists = await mapController.style.styleSourceExists("accident-hotspots");
    if (sourceExists) {
      await mapController.style.removeStyleSource("accident-hotspots");
    }
  }
}
