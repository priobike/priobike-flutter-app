import 'dart:convert';
import 'dart:ui';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
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
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/static_green_waves_v2.geojson"),
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
            iconImage: isDark ? "greenwavedark" : "greenwavelight",
            iconSize: iconSize,
            iconOpacity: 0,
            iconAllowOverlap: true,
            minZoom: 9.0,
          ),
          mapbox.LayerPosition(at: at));
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
      mapbox.GeoJsonSource(id: sourceId, data: "https://$baseUrl/map-data/velo_routes_v2.geojson", tolerance: 1),
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
            id: layerId,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineColor: const Color.fromARGB(255, 64, 192, 240).value,
            lineWidth: 1.9,
            minZoom: 5.0,
          ),
          mapbox.LayerPosition(at: at));
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
