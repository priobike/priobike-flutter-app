import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/logging/logger.dart';

/// A wrapper around the Mapbox Map Controller.
/// This controller keeps track of which layers are currently
/// added to the map to provide safe layer management.
class LayerController {
  /// The log for this class.
  final log = Logger("LayerController");

  /// The map controller.
  MapboxMapController mapController;

  LayerController({required this.mapController});

  /// The layers that are currently added to the map, together with their geojson data.
  final Map<String, LayerProperties> layers = {};

  /// The sources that are currently added to the map, together with their geojson data.
  final Map<String, dynamic> sources = {};

  /// The sources together with their layers.
  final Map<String, Set<String>> layersBySource = {};

  /// A queue of waiting function calls.
  final List<Function> queue = [];

  /// Add a source to the map.
  addGeoJsonSource(String sourceId, Map<String, dynamic> properties) async {
    if (queue.isNotEmpty) {
      queue.add(() => addGeoJsonSource(sourceId, properties));
      return;
    }

    if (sources.containsKey(sourceId)) {
      // If the properties are the same, we don't need to do anything.
      if (sources[sourceId] == properties) return;
      // Remove all layers that are associated with this source.
      for (final layer in layersBySource[sourceId] ?? {}) {
        log.i("---- Removing layer $layer");
        await mapController.removeLayer(layer);
        layers.remove(layer);
      }
      // Remove the source.
      log.i("-- Removing source $sourceId");
      await mapController.removeSource(sourceId);
      sources.remove(sourceId);
      layersBySource.remove(sourceId);
    }
    log.i("Adding source $sourceId");
    await mapController.addGeoJsonSource(sourceId, properties);
    sources[sourceId] = properties;
    layersBySource[sourceId] = {};

    if (queue.isNotEmpty) {
      final next = queue.removeAt(0);
      next();
    }
  }

  /// Update a source on the map.
  updateGeoJsonSource(String sourceId, Map<String, dynamic> properties) async {
    if (queue.isNotEmpty) {
      queue.add(() => updateGeoJsonSource(sourceId, properties));
      return;
    }

    if (sources.containsKey(sourceId)) {
      // If the properties are the same, we don't need to do anything.
      if (sources[sourceId] == properties) return;
      log.i("Updating source $sourceId");
      await mapController.setGeoJsonSource(sourceId, properties);
      sources[sourceId] = properties;
    } else {
      log.i("Adding source $sourceId");
      await mapController.addGeoJsonSource(sourceId, properties);
      sources[sourceId] = properties;
      layersBySource[sourceId] = {};
    }

    if (queue.isNotEmpty) {
      final next = queue.removeAt(0);
      next();
    }
  }

  /// Add a layer to the map.
  addLayer(
    String sourceId,
    String layerId,
    LayerProperties properties, {
    String? belowLayerId,
    bool enableInteraction = true,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
  }) async {
    if (queue.isNotEmpty) {
      queue.add(
        () => addLayer(
          sourceId,
          layerId,
          properties,
          belowLayerId: belowLayerId,
          enableInteraction: enableInteraction,
          sourceLayer: sourceLayer,
          minzoom: minzoom,
          maxzoom: maxzoom,
          filter: filter,
        ),
      );
      return;
    }

    if (!sources.containsKey(sourceId)) {
      log.w("Cannot add layer $layerId to source $sourceId: Source does not exist.");
      return;
    }
    if (layers.containsKey(layerId)) {
      // If the properties are the same, we don't need to do anything.
      if (layers[layerId] == properties) return;
      // Remove the layer.
      log.i("-- Removing layer $layerId");
      await mapController.removeLayer(layerId);
      layers.remove(layerId);
      layersBySource[sourceId]?.remove(layerId);
    }
    log.i("Adding layer $layerId");
    await mapController.addLayer(
      sourceId,
      layerId,
      properties,
      belowLayerId: belowLayerId,
      enableInteraction: enableInteraction,
      sourceLayer: sourceLayer,
      minzoom: minzoom,
      maxzoom: maxzoom,
      filter: filter,
    );
    layers[layerId] = properties;
    layersBySource[sourceId]?.add(layerId);

    if (queue.isNotEmpty) {
      final next = queue.removeAt(0);
      next();
    }
  }

  /// Remove a geojson source from the map, together with all layers that are associated with it.
  removeGeoJsonSourceAndLayers(String sourceId) async {
    if (queue.isNotEmpty) {
      queue.add(() => removeGeoJsonSourceAndLayers(sourceId));
      return;
    }

    if (!sources.containsKey(sourceId)) {
      log.w("Cannot remove source $sourceId: Source does not exist.");
      return;
    }
    // Remove all layers that are associated with this source.
    for (final layer in layersBySource[sourceId] ?? {}) {
      log.i("---- Removing layer $layer");
      await mapController.removeLayer(layer);
      layers.remove(layer);
    }
    // Remove the source.
    log.i("-- Removing source $sourceId");
    await mapController.removeSource(sourceId);
    sources.remove(sourceId);
    layersBySource.remove(sourceId);

    if (queue.isNotEmpty) {
      final next = queue.removeAt(0);
      next();
    }
  }
}
