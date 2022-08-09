import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

/// A loader for mapbox map symbols.
class SymbolLoader {
  /// The associated map controller.
  MapboxMapController mapController;

  /// Create a new symbol loader.
  SymbolLoader(this.mapController);

  /// Load all symbols into the map controller.
  /// Make sure that all symbols are added to the pubspec.yaml file.
  Future<void> loadSymbols() async {
    await addImageFromAsset("alert", "assets/images/alert.drawio.png");
    await addImageFromAsset("start", "assets/images/start.drawio.png");
    await addImageFromAsset("destination", "assets/images/destination.drawio.png");
    await addImageFromAsset("trafficlight", "assets/images/trafficlight.drawio.png");
    await addImageFromAsset("waypoint", "assets/images/waypoint.drawio.png");

    await addImageFromAsset("direction", "assets/images/direction.png");
  }

  /// Adds an asset image to the currently displayed style
  Future<void> addImageFromAsset(String name, String assetName) async {
    final ByteData bytes = await rootBundle.load(assetName);
    final Uint8List list = bytes.buffer.asUint8List();
    return mapController.addImage(name, list);
  }
}

/// A map layer which marks a discomfort location on the map.
class DiscomfortLocationMarker extends SymbolOptions {
  /// Create a new discomfort location marker.
  DiscomfortLocationMarker({
    required LatLng geo,
  }): super(
    geometry: geo,
    iconImage: "alert",
    iconSize: 0.75,
  );
}

/// A map layer which marks a traffic light on the map.
class TrafficLightMarker extends SymbolOptions {
  /// Create a new traffic light marker.
  TrafficLightMarker({
    required LatLng geo,
  }): super(
    geometry: geo,
    iconImage: "trafficlight",
    iconSize: 1,
    iconOffset: const Offset(0, -24),
  );
}

/// A map layer which marks the current position on the map.
class CurrentPositionMarker extends SymbolOptions {
  /// Create a new current position marker.
  CurrentPositionMarker({
    required LatLng geo,
  }): super(
    geometry: geo,
    iconImage: "direction",
    iconSize: 1,
  );
}

/// A map layer which marks the start position on the map.
class StartMarker extends SymbolOptions {
  /// Create a new start marker.
  StartMarker({
    required LatLng geo,
  }): super(
    geometry: geo,
    iconImage: "start",
    iconSize: 1,
  );
}

/// A map layer which marks the end position on the map.
class DestinationMarker extends SymbolOptions {
  /// Create a new destination marker.
  DestinationMarker({
    required LatLng geo,
  }): super(
    geometry: geo,
    iconImage: "destination",
    iconSize: 1,
  );
}

/// A map layer which marks an intermediate position on the map.
class WaypointMarker extends SymbolOptions {
  /// Create a new waypoint marker.
  WaypointMarker({
    required LatLng geo,
  }): super(
    geometry: geo,
    iconImage: "destination",
    iconSize: 1,
  );
}
