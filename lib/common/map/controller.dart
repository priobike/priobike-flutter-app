import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/logging/logger.dart';
import 'package:collection/collection.dart';

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

  /// Notify the layer controller that a style has been loaded.
  notifyStyleLoaded() {
    layers.clear();
    sources.clear();
    layersBySource.clear();
  }

  /// Add a source to the map.
  addGeoJsonSource(String sourceId, Map<String, dynamic> properties) async {
    if (sources.containsKey(sourceId)) {
      // If the properties are the same, we don't need to do anything.
      if (const DeepCollectionEquality().equals(sources[sourceId], properties)) {
        log.i("Source $sourceId is already added with the same properties.");
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
    }
    log.i("Adding source $sourceId");
    await mapController.addGeoJsonSource(sourceId, properties);
    sources[sourceId] = properties;
    layersBySource[sourceId] = {};
  }

  /// Update a source on the map.
  updateGeoJsonSource(String sourceId, Map<String, dynamic> properties) async {
    if (sources.containsKey(sourceId)) {
      // If the properties are the same, we don't need to do anything.
      if (const DeepCollectionEquality().equals(sources[sourceId], properties)) {
        log.i("Source $sourceId is already up to date.");
        return;
      }
      log.i("Updating source $sourceId");
      await mapController.setGeoJsonSource(sourceId, properties);
      sources[sourceId] = properties;
    } else {
      // [addGeoJsonSource] should always be called before [updateGeoJsonSource].
      log.w("Skipping update of source $sourceId, because it is not added.");
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
    if (!sources.containsKey(sourceId)) {
      log.w("Cannot add layer $layerId to source $sourceId: Source does not exist.");
      return;
    }
    if (layers.containsKey(layerId)) {
      // If the properties are the same, we don't need to do anything.
      if (const DeepCollectionEquality().equals(layers[layerId], properties)) {
        log.i("Layer $layerId is already added with the same properties.");
        return;
      }
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
  }

  /// Remove a geojson source from the map, together with all layers that are associated with it.
  removeGeoJsonSourceAndLayers(String sourceId) async {
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
  }
}
