import 'dart:convert';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class GreenWaveLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "green-wave-lsas";

  /// The ID of the Mapbox layer.
  static const layerId = "green-wave-lsas-icons";

  /// If the dark mode is enabled.
  final bool isDark;

  GreenWaveLayer(this.isDark);

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/static_green_waves.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.15}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerId,
            iconImage: isDark ? "trafficlightgreenwavedark" : "trafficlightgreenwavelight",
            iconSize: iconSize,
            iconOpacity: 0,
            iconAllowOverlap: true,
          ),
          mapbox.LayerPosition(below: "offline-crossings-icons"));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 12),
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

class VeloRoutesLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "velo-routes";

  /// The ID of the Mapbox layer.
  static const layerId = "velo-routes-lines";

  /// If the dark mode is enabled.
  final bool isDark;

  VeloRoutesLayer(this.isDark);

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    await mapController.style.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/velo_routes.geojson"),
    );
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController, {iconSize = 0.15}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final layerExists = await mapController.style.styleLayerExists(layerId);
    if (!layerExists) {
      await mapController.style.addLayerAt(
          mapbox.LineLayer(
              sourceId: sourceId,
              id: layerId,
              lineJoin: mapbox.LineJoin.ROUND,
              lineCap: mapbox.LineCap.ROUND,
              lineColor: CI.lightBlue.value,
              lineWidth: 1.9),
          mapbox.LayerPosition(below: "user-location-puck"));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 12),
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