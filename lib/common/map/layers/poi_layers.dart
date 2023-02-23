import 'dart:convert';

import 'package:flutter/material.dart' hide Route;
import 'package:get_it/get_it.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class ParkingStationsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "parking-stations";

  /// The ID of the Mapbox layer.
  static const layerId = "parking-stations-icons";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  ParkingStationsLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt.get<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/bicycle_parking.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: sourceId,
        id: layerId,
        iconImage: isDark ? "parkdark" : "parklight",
        iconSize: iconSize,
        iconOpacity: 0,
        iconAllowOverlap: true,
      ));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
    }
  }

  /// Remove the layer from the map controller.
  static remove(mapbox.MapboxMap mapController) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      await mapController.style.removeStyleLayer(layerId);
    }
  }
}

class RentalStationsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "rental-stations";

  /// The ID of the Mapbox layer.
  static const layerId = "rental-stations-icons";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  RentalStationsLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt.get<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/bicycle_rental.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: sourceId,
        id: layerId,
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
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 2]
            ],
          ));
      await mapController.style.setStyleLayerProperty(
          layerId,
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
      await mapController.style.setStyleLayerProperty(layerId, 'text-opacity', json.encode(showAfter(zoom: 17)));
    }
  }

  /// Remove the layer from the map controller.
  static remove(mapbox.MapboxMap mapController) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      await mapController.style.removeStyleLayer(layerId);
    }
  }
}

class BikeShopLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "bike-shop";

  /// The ID of the Mapbox layer.
  static const layerId = "bike-shop-icons";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  BikeShopLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt.get<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/bicycle_shop.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: sourceId,
        id: layerId,
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
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 2]
            ],
          ));
      await mapController.style.setStyleLayerProperty(
          layerId,
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
      await mapController.style.setStyleLayerProperty(layerId, 'text-opacity', json.encode(showAfter(zoom: 17)));
    }
  }

  /// Remove the layer from the map controller.
  static remove(mapbox.MapboxMap mapController) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      await mapController.style.removeStyleLayer(layerId);
    }
  }
}

class BikeAirStationLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "bike-air-station";

  /// The ID of the Mapbox layer.
  static const layerId = "bike-air-station-icons";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  BikeAirStationLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt.get<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/bike_air_station.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: sourceId,
        id: layerId,
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
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 2]
            ],
          ));
      await mapController.style.setStyleLayerProperty(
          layerId,
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
      await mapController.style.setStyleLayerProperty(layerId, 'text-opacity', json.encode(showAfter(zoom: 17)));
    }
  }

  /// Remove the layer from the map controller.
  static remove(mapbox.MapboxMap mapController) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      await mapController.style.removeStyleLayer(layerId);
    }
  }
}

class ConstructionSitesLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "construction-sites";

  /// The ID of the Mapbox layer.
  static const layerId = "construction-sites-icons";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  ConstructionSitesLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt.get<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/construction_sites.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: sourceId,
        id: layerId,
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
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 12),
          ));
      await mapController.style.setStyleLayerProperty(layerId, 'text-field', 'Baustelle');
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 1]
            ],
          ));
      await mapController.style.setStyleLayerProperty(layerId, 'text-opacity', json.encode(showAfter(zoom: 15)));
    }
  }

  /// Remove the layer from the map controller.
  static remove(mapbox.MapboxMap mapController) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      await mapController.style.removeStyleLayer(layerId);
    }
  }
}

class AccidentHotspotsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "accident-hotspots";

  /// The ID of the Mapbox layer.
  static const layerId = "accident-hotspots-icons";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  AccidentHotspotsLayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt.get<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/accident_hot_spots.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: sourceId,
        id: layerId,
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
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 11),
          ));
      await mapController.style.setStyleLayerProperty(layerId, 'text-field', 'Unfall-\nschwerpunkt');
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 1]
            ],
          ));
      await mapController.style.setStyleLayerProperty(layerId, 'text-opacity', json.encode(showAfter(zoom: 15)));
    }
  }

  /// Remove the layer from the map controller.
  static remove(mapbox.MapboxMap mapController) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      await mapController.style.removeStyleLayer(layerId);
    }
  }
}
