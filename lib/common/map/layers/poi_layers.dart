import 'dart:convert';

import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class ParkingStationsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "parking-stations";

  /// The ID of the Mapbox layer.
  static const layerId = "parking-stations-icons";

  /// The ID of the Mapbox click layer.
  static const clickLayerId = "parking-stations-click";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  ParkingStationsLayer(this.isDark);

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/bicycle_parking_v2.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerId,
            iconImage: isDark ? "parkdark" : "parklight",
            iconSize: iconSize,
            iconOpacity: 0,
            iconAllowOverlap: true,
            minZoom: 12.0,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
    }

    final clickLayerExists = await mapController.style.styleLayerExists(clickLayerId);
    if (!clickLayerExists) {
      // Add the icon click layer to prevent clicking the invisible parts of the icon image.
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: clickLayerId,
          iconImage: "iconclicklayer",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 1,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
          // To disable clicking invisible icons.
          minZoom: 14.0,
        ),
        mapbox.LayerPosition(at: at),
      );
    }
  }

  /// Select/Unselect a specific POI.
  toggleSelect(mapbox.MapboxMap mapController, {String? selectedPOIId}) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      // Overwrite icon opacity to hide the unselected icon.
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-image',
          json.encode([
            "case",
            [
              "==",
              ["get", "id"],
              selectedPOIId ?? ""
            ],
            "parkselected",
            isDark ? "parkdark" : "parklight"
          ]));
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

  /// The ID of the Mapbox text layer.
  static const textLayerId = "rental-stations-text";

  /// The ID of the Mapbox click layer.
  static const clickLayerId = "rental-stations-click";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  RentalStationsLayer(this.isDark);

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/bicycle_rental_v2.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: layerId,
          iconImage: isDark ? "rentdark" : "rentlight",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 0,
          // To disable clicking invisible icons.
          minZoom: 14.0,
        ),
        mapbox.LayerPosition(at: at),
      );

      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
    }

    final textLayerExists = await mapController.style.styleLayerExists(textLayerId);
    if (!textLayerExists) {
      // Add the text layer separately to prevent clicking invisible text.
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: textLayerId,
          textHaloColor: isDark ? const Color(0xFF000000).value : const Color(0xFFFFFFFF).value,
          textHaloWidth: 1,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textAnchor: mapbox.TextAnchor.CENTER,
          textColor: CI.radkulturRed.value,
          textAllowOverlap: true,
          textOpacity: 0,
          // To disable clicking on invisible text.
          minZoom: 16.0,
        ),
        mapbox.LayerPosition(at: at),
      );

      await mapController.style.setStyleLayerProperty(
          textLayerId,
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 2]
            ],
          ));
      await mapController.style.setStyleLayerProperty(
          textLayerId,
          'text-field',
          json.encode([
            "case",
            ["has", "name"],
            [
              // Concatenate "Ausleihstation" with the name of the station.
              "concat",
              "Ausleihstation ",
              ["get", "name"]
            ],
            "Fahrradleihe "
          ]));
      await mapController.style.setStyleLayerProperty(textLayerId, 'text-opacity', json.encode(showAfter(zoom: 17)));
    }

    final clickLayerExists = await mapController.style.styleLayerExists(clickLayerId);
    if (!clickLayerExists) {
      // Add the icon click layer to prevent clicking the invisible parts of the icon image.
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: clickLayerId,
          iconImage: "iconclicklayer",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 1,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
          // To disable clicking invisible icons.
          minZoom: 14.0,
        ),
        mapbox.LayerPosition(at: at),
      );
    }
  }

  /// Select/Unselect a specific POI.
  toggleSelect(mapbox.MapboxMap mapController, {String? selectedPOIId}) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      // Overwrite icon opacity to hide the unselected icon.
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-image',
          json.encode([
            "case",
            [
              "==",
              ["get", "id"],
              selectedPOIId ?? ""
            ],
            "rentselected",
            isDark ? "rentdark" : "rentlight"
          ]));

      // Overwrite text opacity to hide the unselected icon text.
      await mapController.style.setStyleLayerProperty(
          textLayerId,
          'text-opacity',
          json.encode(showAfter(zoom: 17, opacity: [
            "case",
            [
              "==",
              ["get", "id"],
              selectedPOIId ?? ""
            ],
            0,
            1
          ])));
    }
  }

  /// Remove the layer from the map controller.
  static remove(mapbox.MapboxMap mapController) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      await mapController.style.removeStyleLayer(layerId);
    }
    final textLayerExists = await mapController.style.styleLayerExists(textLayerId);
    if (textLayerExists) {
      await mapController.style.removeStyleLayer(textLayerId);
    }
    final clickLayerExists = await mapController.style.styleLayerExists(clickLayerId);
    if (clickLayerExists) {
      await mapController.style.removeStyleLayer(clickLayerId);
    }
  }
}

class BikeShopLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  /// The ID of the Mapbox source.
  static const sourceId = "bike-shop";

  /// The ID of the Mapbox layer.
  static const layerId = "bike-shop-icons";

  /// The ID of the Mapbox text layer.
  static const textLayerId = "bike-shop-text";

  /// The ID of the Mapbox click layer.
  static const clickLayerId = "bike-shop-click";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  BikeShopLayer(this.isDark);

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/bicycle_shop_v2.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: layerId,
          iconImage: isDark ? "repairdark" : "repairlight",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 0,
          // To disable clicking on invisible icons.
          minZoom: 14.0,
        ),
        mapbox.LayerPosition(at: at),
      );

      // Add the text layer separately to prevent clicking invisible text.
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: textLayerId,
          textHaloColor: isDark ? const Color(0xFF000000).value : const Color(0xFFFFFFFF).value,
          textHaloWidth: 1,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textAnchor: mapbox.TextAnchor.CENTER,
          textColor: CI.radkulturRed.value,
          textAllowOverlap: true,
          textOpacity: 0,
          // To disable clicking on invisible text.
          minZoom: 16.0,
        ),
        mapbox.LayerPosition(at: at),
      );

      // Add the icon click layer to prevent clicking the invisible parts of the icon image.
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: clickLayerId,
          iconImage: "iconclicklayer",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 1,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
          // To disable clicking invisible icons.
          minZoom: 14.0,
        ),
        mapbox.LayerPosition(at: at),
      );

      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
      await mapController.style.setStyleLayerProperty(
          textLayerId,
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 2]
            ],
          ));
      await mapController.style.setStyleLayerProperty(
          textLayerId,
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
      await mapController.style.setStyleLayerProperty(textLayerId, 'text-opacity', json.encode(showAfter(zoom: 17)));
    }
  }

  /// Select/Unselect a specific POI.
  toggleSelect(mapbox.MapboxMap mapController, {String? selectedPOIId}) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      // Overwrite icon opacity to hide the unselected icon.
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-image',
          json.encode([
            "case",
            [
              "==",
              ["get", "id"],
              selectedPOIId ?? ""
            ],
            "repairselected",
            isDark ? "repairdark" : "repairlight"
          ]));

      // Overwrite text opacity to hide the unselected icon text.
      await mapController.style.setStyleLayerProperty(
          textLayerId,
          'text-opacity',
          json.encode(showAfter(zoom: 17, opacity: [
            "case",
            [
              "==",
              ["get", "id"],
              selectedPOIId ?? ""
            ],
            0,
            1
          ])));
    }
  }

  /// Remove the layer from the map controller.
  static remove(mapbox.MapboxMap mapController) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      await mapController.style.removeStyleLayer(layerId);
    }
    final textLayerExists = await mapController.style.styleLayerExists(textLayerId);
    if (textLayerExists) {
      await mapController.style.removeStyleLayer(textLayerId);
    }
    final clickLayerExists = await mapController.style.styleLayerExists(clickLayerId);
    if (clickLayerExists) {
      await mapController.style.removeStyleLayer(clickLayerId);
    }
  }
}

class BikeAirStationLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "bike-air-station";

  /// The ID of the Mapbox layer.
  static const layerId = "bike-air-station-icons";

  /// The ID of the Mapbox text layer.
  static const textLayerId = "bike-air-station-text";

  /// The ID of the Mapbox click layer.
  static const clickLayerId = "bike-air-station-click";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  BikeAirStationLayer(this.isDark);

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/bike_air_station_v2.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: layerId,
          iconImage: isDark ? "airdark" : "airlight",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 0,
          // To disable clicking on invisible icons.
          minZoom: 14.0,
        ),
        mapbox.LayerPosition(at: at),
      );

      // Add the text layer separately to prevent clicking invisible text.
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: textLayerId,
          textHaloColor: isDark ? const Color(0xFF000000).value : const Color(0xFFFFFFFF).value,
          textHaloWidth: 1,
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textAnchor: mapbox.TextAnchor.CENTER,
          textColor: CI.radkulturRed.value,
          textAllowOverlap: true,
          textOpacity: 0,
          // To disable clicking on invisible text.
          minZoom: 16.0,
        ),
        mapbox.LayerPosition(at: at),
      );

      // Add the icon click layer to prevent clicking the invisible parts of the icon image.
      await mapController.style.addLayerAt(
        mapbox.SymbolLayer(
          sourceId: sourceId,
          id: clickLayerId,
          iconImage: "iconclicklayer",
          iconSize: iconSize,
          iconAllowOverlap: true,
          iconOpacity: 1,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
          // To disable clicking invisible icons.
          minZoom: 14.0,
        ),
        mapbox.LayerPosition(at: at),
      );

      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
      await mapController.style.setStyleLayerProperty(
          textLayerId,
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 2]
            ],
          ));
      await mapController.style.setStyleLayerProperty(
          textLayerId,
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
      await mapController.style.setStyleLayerProperty(textLayerId, 'text-opacity', json.encode(showAfter(zoom: 17)));
    }
  }

  /// Select/Unselect a specific POI.
  toggleSelect(mapbox.MapboxMap mapController, {String? selectedPOIId}) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      // Overwrite icon opacity to hide the unselected icon.
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-image',
          json.encode([
            "case",
            [
              "==",
              ["get", "id"],
              selectedPOIId ?? ""
            ],
            "airselected",
            isDark ? "airdark" : "airlight"
          ]));

      // Overwrite text opacity to hide the unselected icon text.
      await mapController.style.setStyleLayerProperty(
          textLayerId,
          'text-opacity',
          json.encode(showAfter(zoom: 17, opacity: [
            "case",
            [
              "==",
              ["get", "id"],
              selectedPOIId ?? ""
            ],
            0,
            1
          ])));
    }
  }

  /// Remove the layer from the map controller.
  static remove(mapbox.MapboxMap mapController) async {
    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (layerExists) {
      await mapController.style.removeStyleLayer(layerId);
    }
    final textLayerExists = await mapController.style.styleLayerExists(textLayerId);
    if (textLayerExists) {
      await mapController.style.removeStyleLayer(textLayerId);
    }
    final clickLayerExists = await mapController.style.styleLayerExists(clickLayerId);
    if (clickLayerExists) {
      await mapController.style.removeStyleLayer(clickLayerId);
    }
  }
}

class TrafficLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "traffic-layer";

  /// The ID of the Mapbox layer.
  static const layerId = "traffic-layer-lines";

  /// If the dark mode is enabled.
  final bool isDark;

  TrafficLayer(this.isDark);

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    await mapController.style.addSource(
      mapbox.VectorSource(id: sourceId, url: "mapbox://mapbox.mapbox-traffic-v1"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.15, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayerAt(
        mapbox.LineLayer(
          sourceId: sourceId,
          sourceLayer: "traffic",
          id: layerId,
          lineJoin: mapbox.LineJoin.ROUND,
          lineCap: mapbox.LineCap.ROUND,
          lineWidth: 1.9,
          minZoom: 8.0,
        ),
        mapbox.LayerPosition(at: at),
      );
      await mapController.style.setStyleLayerProperty(
          layerId,
          'line-color',
          json.encode(
            [
              "case",
              [
                "==",
                "low",
                ["get", "congestion"]
              ],
              "transparent",
              [
                "==",
                "moderate",
                ["get", "congestion"]
              ],
              "transparent",
              [
                "==",
                "heavy",
                ["get", "congestion"]
              ],
              "#FFDC00",
              [
                "==",
                "severe",
                ["get", "congestion"]
              ],
              "#FFDC00",
              "#000000"
            ],
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
