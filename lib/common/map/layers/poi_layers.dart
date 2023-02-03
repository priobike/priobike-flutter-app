import 'dart:convert';

import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

abstract class _POILayer {
  /// If the layer should display a dark version of the icons.
  final bool isDark;

  /// BuildContext of the widget
  final BuildContext context;

  String _getSourceId();
  String _getSourcePath();
  String _getLayerId();

  _POILayer(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: _getSourceId(), data: "https://$baseUrl${_getSourcePath()}"),
    );
  }

  /// Remove the layer from the map controller.
  remove(mapbox.MapboxMap mapController) async {
    final layerExists = await mapController.style.styleLayerExists(_getLayerId());
    if (layerExists) {
      await mapController.style.removeStyleLayer(_getLayerId());
    }
  }
}

class ParkingStationsLayer extends _POILayer {
  @override
  String _getSourceId() => "parking-stations";

  @override
  String _getSourcePath() => "/map-data/bicycle_parking.geojson";

  @override
  String _getLayerId() => "parking-stations-icons";

  ParkingStationsLayer(BuildContext context) : super(context);

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(_getSourceId());
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(_getLayerId());
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: _getSourceId(),
        id: _getLayerId(),
        iconImage: isDark ? "parkdark" : "parklight",
        iconSize: iconSize,
        iconOpacity: 0,
        iconAllowOverlap: true,
      ));
      await mapController.style.setStyleLayerProperty(
          _getLayerId(),
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
    }
  }
}

class RentalStationsLayer extends _POILayer {
  @override
  String _getSourceId() => "rental-stations";

  @override
  String _getSourcePath() => "/map-data/bicycle_rental.geojson";

  @override
  String _getLayerId() => "rental-stations-icons";

  RentalStationsLayer(BuildContext context) : super(context);

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(_getSourceId());
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(_getLayerId());
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: _getSourceId(),
        id: _getLayerId(),
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
          _getLayerId(),
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
      await mapController.style.setStyleLayerProperty(
          _getLayerId(),
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 2]
            ],
          ));
      await mapController.style.setStyleLayerProperty(
          _getLayerId(),
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
      await mapController.style.setStyleLayerProperty(_getLayerId(), 'text-opacity', json.encode(showAfter(zoom: 17)));
    }
  }
}

class BikeShopLayer extends _POILayer {
  @override
  String _getSourceId() => "bike-shop";

  @override
  String _getSourcePath() => "/map-data/bicycle_shop.geojson";

  @override
  String _getLayerId() => "bike-shop-icons";

  BikeShopLayer(BuildContext context) : super(context);

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(_getSourceId());
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(_getLayerId());
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: _getSourceId(),
        id: _getLayerId(),
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
          _getLayerId(),
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
      await mapController.style.setStyleLayerProperty(
          _getLayerId(),
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 2]
            ],
          ));
      await mapController.style.setStyleLayerProperty(
          _getLayerId(),
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
      await mapController.style.setStyleLayerProperty(_getLayerId(), 'text-opacity', json.encode(showAfter(zoom: 17)));
    }
  }
}

class BikeAirStationLayer extends _POILayer {
  @override
  String _getSourceId() => "bike-air-station";

  @override
  String _getSourcePath() => "/map-data/bike_air_station.geojson";

  @override
  String _getLayerId() => "bike-air-station-icons";

  BikeAirStationLayer(BuildContext context) : super(context);

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(_getSourceId());
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(_getLayerId());
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: _getSourceId(),
        id: _getLayerId(),
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
          _getLayerId(),
          'icon-opacity',
          json.encode(
            showAfter(zoom: 15),
          ));
      await mapController.style.setStyleLayerProperty(
          _getLayerId(),
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 2]
            ],
          ));
      await mapController.style.setStyleLayerProperty(
          _getLayerId(),
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
      await mapController.style.setStyleLayerProperty(_getLayerId(), 'text-opacity', json.encode(showAfter(zoom: 17)));
    }
  }
}

class ConstructionSitesLayer extends _POILayer {
  @override
  String _getSourceId() => "construction-sites";

  @override
  String _getSourcePath() => "/map-data/construction_sites.geojson";

  @override
  String _getLayerId() => "construction-sites-icons";

  ConstructionSitesLayer(BuildContext context) : super(context);

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(_getSourceId());
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(_getLayerId());
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: _getSourceId(),
        id: _getLayerId(),
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
          _getLayerId(),
          'icon-opacity',
          json.encode(
            showAfter(zoom: 12),
          ));
      await mapController.style.setStyleLayerProperty(_getLayerId(), 'text-field', 'Baustelle');
      await mapController.style.setStyleLayerProperty(
          _getLayerId(),
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 1]
            ],
          ));
      await mapController.style.setStyleLayerProperty(_getLayerId(), 'text-opacity', json.encode(showAfter(zoom: 15)));
    }
  }
}

class AccidentHotspotsLayer extends _POILayer {
  @override
  String _getSourceId() => "accident-hotspots";

  @override
  String _getSourcePath() => "/map-data/accident_hot_spots.geojson";

  @override
  String _getLayerId() => "accident-hotspots-icons";

  AccidentHotspotsLayer(BuildContext context) : super(context);

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.3}) async {
    final sourceExists = await mapController.style.styleSourceExists(_getSourceId());
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(_getLayerId());
    if (!layerExists) {
      await mapController.style.addLayer(mapbox.SymbolLayer(
        sourceId: _getSourceId(),
        id: _getLayerId(),
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
          _getLayerId(),
          'icon-opacity',
          json.encode(
            showAfter(zoom: 11),
          ));
      await mapController.style.setStyleLayerProperty(_getLayerId(), 'text-field', 'Unfall-\nschwerpunkt');
      await mapController.style.setStyleLayerProperty(
          _getLayerId(),
          'text-offset',
          json.encode(
            [
              "literal",
              [0, 1]
            ],
          ));
      await mapController.style.setStyleLayerProperty(_getLayerId(), 'text-opacity', json.encode(showAfter(zoom: 15)));
    }
  }
}
