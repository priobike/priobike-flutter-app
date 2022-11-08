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
    await addImageFromAsset("trafficlightdisconnecteddark", "assets/images/trafficlights/disconnected-dark.png");
    await addImageFromAsset("trafficlightdisconnectedlight", "assets/images/trafficlights/disconnected-light.png");
    await addImageFromAsset("trafficlightofflinedark", "assets/images/trafficlights/offline-dark.png");
    await addImageFromAsset("trafficlightofflinelight", "assets/images/trafficlights/offline-light.png");
    await addImageFromAsset("trafficlightonlinedark", "assets/images/trafficlights/online-dark.png");
    await addImageFromAsset("trafficlightonlinelight", "assets/images/trafficlights/online-light.png");
    await addImageFromAsset("trafficlightonlinegreendark", "assets/images/trafficlights/online-green-dark.png");
    await addImageFromAsset("trafficlightonlinegreenlight", "assets/images/trafficlights/online-green-light.png");
    await addImageFromAsset("trafficlightonlinereddark", "assets/images/trafficlights/online-red-dark.png");
    await addImageFromAsset("trafficlightonlineredlight", "assets/images/trafficlights/online-red-light.png");

    await addImageFromAsset("alert", "assets/images/alert.drawio.png");
    await addImageFromAsset("start", "assets/images/start.drawio.png");
    await addImageFromAsset("destination", "assets/images/destination.drawio.png");
    await addImageFromAsset("waypoint", "assets/images/waypoint.drawio.png");

    await addImageFromAsset("airdark", "assets/images/air-dark.png");
    await addImageFromAsset("airlight", "assets/images/air-light.png");
    await addImageFromAsset("constructiondark", "assets/images/construction-dark.png");
    await addImageFromAsset("constructionlight", "assets/images/construction-light.png");
    await addImageFromAsset("parkdark", "assets/images/park-dark.png");
    await addImageFromAsset("parklight", "assets/images/park-light.png");
    await addImageFromAsset("positiondark", "assets/images/position-dark.png");
    await addImageFromAsset("positionlight", "assets/images/position-light.png");
    await addImageFromAsset("rentdark", "assets/images/rent-dark.png");
    await addImageFromAsset("rentlight", "assets/images/rent-light.png");
    await addImageFromAsset("repairdark", "assets/images/repair-dark.png");
    await addImageFromAsset("repairlight", "assets/images/repair-light.png");
  }

  /// Adds an asset image to the currently displayed style
  Future<void> addImageFromAsset(String name, String assetName) async {
    final bytes = await rootBundle.load(assetName);
    final bytesArr = bytes.buffer.asUint8List();
    return mapController.addImage(name, bytesArr);
  }
}

class DiscomfortLocationMarker extends SymbolOptions {
  DiscomfortLocationMarker({
    required LatLng geo,
    required int number,
    double iconSize = 0.5,
  }) : super(
          geometry: geo,
          iconImage: "alert",
          iconSize: iconSize,
          textField: "$number",
          textSize: 12,
          zIndex: 1,
        );
}

class TrafficLightMarker extends SymbolOptions {
  TrafficLightMarker({
    required LatLng geo,
    double iconSize = 1,
    int zIndex = 2,
    required String iconImage,
    String? label,
  }) : super(
          geometry: geo,
          iconImage: iconImage,
          iconSize: iconSize,
          zIndex: zIndex,
        );
}

class OnlineMarker extends TrafficLightMarker {
  OnlineMarker({
    required LatLng geo,
    double iconSize = 1,
    String? label,
    Brightness? brightness,
  }) : super(
          geo: geo,
          iconSize: iconSize,
          iconImage: brightness == Brightness.dark ? "trafficlightonlinedark" : "trafficlightonlinelight",
          zIndex: 3,
          label: label,
        );
}

class DisconnectedMarker extends TrafficLightMarker {
  DisconnectedMarker({
    required LatLng geo,
    double iconSize = 1,
    String? label,
    Brightness? brightness,
  }) : super(
          geo: geo,
          iconSize: iconSize,
          iconImage: brightness == Brightness.dark ? "trafficlightdisconnecteddark" : "trafficlightdisconnectedlight",
          zIndex: 3,
          label: label,
        );
}

class OfflineMarker extends TrafficLightMarker {
  OfflineMarker({
    required LatLng geo,
    double iconSize = 1,
    String? label,
    Brightness? brightness,
  }) : super(
          geo: geo,
          iconSize: iconSize,
          iconImage: brightness == Brightness.dark ? "trafficlightofflinedark" : "trafficlightofflinelight",
          zIndex: 3,
          label: label,
        );
}

class TrafficLightGreenMarker extends SymbolOptions {
  TrafficLightGreenMarker({
    required LatLng geo,
    double iconSize = 1,
    double iconOpacity = 1,
    Brightness? brightness,
  }) : super(
          geometry: geo,
          iconImage: brightness == Brightness.dark ? "trafficlightonlinegreendark" : "trafficlightonlinegreenlight",
          iconSize: iconSize,
          iconOpacity: iconOpacity,
          zIndex: 5,
        );
}

class TrafficLightRedMarker extends SymbolOptions {
  TrafficLightRedMarker({
    required LatLng geo,
    double iconSize = 1,
    double iconOpacity = 1,
    Brightness? brightness,
  }) : super(
          geometry: geo,
          iconImage: brightness == Brightness.dark ? "trafficlightonlinereddark" : "trafficlightonlineredlight",
          iconSize: iconSize,
          iconOpacity: iconOpacity,
          zIndex: 5,
        );
}

/// A map layer which marks the current position on the map.
class CurrentPositionMarker extends SymbolOptions {
  /// Create a new current position marker.
  CurrentPositionMarker({
    required LatLng geo,
    required double orientation,
  }) : super(
          geometry: geo,
          iconRotate: orientation,
          iconImage: "direction",
          iconSize: 4,
        );
}

/// A map layer which marks the start position on the map.
class StartMarker extends SymbolOptions {
  /// Create a new start marker.
  StartMarker({
    required LatLng geo,
  }) : super(
          geometry: geo,
          iconImage: "start",
          iconSize: 0.75,
        );
}

/// A map layer which marks the end position on the map.
class DestinationMarker extends SymbolOptions {
  /// Create a new destination marker.
  DestinationMarker({
    required LatLng geo,
  }) : super(
          geometry: geo,
          iconImage: "destination",
          iconSize: 0.75,
        );
}

/// A map layer which marks an intermediate position on the map.
class WaypointMarker extends SymbolOptions {
  /// Create a new waypoint marker.
  WaypointMarker({
    required LatLng geo,
  }) : super(
          geometry: geo,
          iconImage: "waypoint",
          iconSize: 0.75,
          zIndex: 5,
        );
}
