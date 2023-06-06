import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/boundary.dart';

/// A layer that displays the boundary of the routable area.
class BoundaryLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "routing-boundary";

  /// The ID of the Mapbox fill layer.
  static const fillLayerId = "routing-boundary-fill";

  /// The ID of the Mapbox line layer.
  static const lineLayerId = "routing-boundary-line";

  /// If the layer should display a dark version of the icons.
  final bool isDark;

  BoundaryLayer(this.isDark);

  /// Install the source of the layer on the map controller.
  _installSource(mapbox.MapboxMap mapController) async {
    final boundary = getIt<Boundary>();
    final geojson = boundary.boundaryGeoJson;
    if (geojson == null) return;
    await mapController.style.addSource(mapbox.GeoJsonSource(id: sourceId, data: geojson!));
  }

  /// Install the layer on the map controller.
  install(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) await _installSource(mapController);

    final fillLayerExists = await mapController.style.styleLayerExists(fillLayerId);
    if (!fillLayerExists) {
      await mapController.style.addLayer(mapbox.FillLayer(
        sourceId: sourceId,
        id: fillLayerId,
        fillColor: Colors.black.value,
        fillOpacity: isDark ? 0.5 : 0.2,
      ));
    }

    final lineLayerExists = await mapController.style.styleLayerExists(lineLayerId);
    if (!lineLayerExists) {
      await mapController.style.addLayer(mapbox.LineLayer(
        sourceId: sourceId,
        id: lineLayerId,
        lineColor: isDark ? Colors.white.value : Colors.black.value,
        lineOpacity: isDark ? 0.5 : 0.1,
        lineWidth: 2,
        lineDasharray: [2, 2],
      ));
    }
  }

  /// Remove the layer from the map controller.
  static remove(mapbox.MapboxMap mapController) async {
    final fillLayerExists = await mapController.style.styleLayerExists(fillLayerId);
    if (fillLayerExists) {
      await mapController.style.removeStyleLayer(fillLayerId);
    }
    final lineLayerExists = await mapController.style.styleLayerExists(lineLayerId);
    if (lineLayerExists) {
      await mapController.style.removeStyleLayer(lineLayerId);
    }
  }
}
