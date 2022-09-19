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
    await addImageFromAsset("badsignal", "assets/images/bad-signal.drawio.png");
    await addImageFromAsset("offline", "assets/images/offline.drawio.png");
    await addImageFromAsset("online", "assets/images/online.drawio.png");
    await addImageFromAsset("alert", "assets/images/alert.drawio.png");
    await addImageFromAsset("start", "assets/images/start.drawio.png");
    await addImageFromAsset("destination", "assets/images/destination.drawio.png");
    await addImageFromAsset("trafficlightoff", "assets/images/trafficlight-off.drawio.png");
    await addImageFromAsset("trafficlightoffoffline", "assets/images/trafficlight-off-offline.drawio.png");
    await addImageFromAsset("trafficlightoffbadsignal", "assets/images/trafficlight-off-bad-signal.drawio.png");
    await addImageFromAsset("trafficlightoffonline", "assets/images/trafficlight-off-online.drawio.png");
    await addImageFromAsset("trafficlightred", "assets/images/trafficlight-red-countdown.drawio.png");
    await addImageFromAsset("trafficlightgreen", "assets/images/trafficlight-green-countdown.drawio.png");
    await addImageFromAsset("waypoint", "assets/images/waypoint.drawio.png");

    await addImageFromAsset("direction", "assets/images/direction.png");
  }

  /// Adds an asset image to the currently displayed style
  Future<void> addImageFromAsset(String name, String assetName) async {
    final bytes = await rootBundle.load(assetName);
    final bytesArr = bytes.buffer.asUint8List();
    return mapController.addImage(name, bytesArr);
  }
}

/// A map layer which marks a discomfort location on the map.
class DiscomfortLocationMarker extends SymbolOptions {
  /// Create a new discomfort location marker.
  DiscomfortLocationMarker({
    required LatLng geo,
    required int number,
    double iconSize = 0.5,
  }): super(
    geometry: geo,
    iconImage: "alert",
    iconSize: iconSize,
    textField: "$number",
    textSize: 12,
    zIndex: 1,
  );
}

/// A map layer which marks a traffic light on the map.
class TrafficLightOffMarker extends SymbolOptions {
  /// Create a new traffic light marker.
  TrafficLightOffMarker({
    required LatLng geo,
    double iconSize = 1,
    String iconImage = "trafficlightoff",
    String? label,
  }): super(
    geometry: geo,
    iconImage: iconImage,
    iconSize: iconSize,
    zIndex: 2,
    textField: label,
    textSize: 16,
    textOffset: const Offset(0, -3.5),
    textAnchor: "bottom",
    textJustify: "center",
    textHaloColor: "#ffffff",
    textHaloWidth: 1,
    textHaloBlur: 1,
  );
}

class TrafficLightOffOnlineMarker extends TrafficLightOffMarker {
  TrafficLightOffOnlineMarker({
    required LatLng geo,
    double iconSize = 1,
    String? label,
  }): super(
    geo: geo,
    iconSize: iconSize,
    iconImage: "trafficlightoffonline",
    label: label,
  );
}

class TrafficLightOffOfflineMarker extends TrafficLightOffMarker {
  TrafficLightOffOfflineMarker({
    required LatLng geo,
    double iconSize = 1,
    String? label,
  }): super(
    geo: geo,
    iconSize: iconSize,
    iconImage: "trafficlightoffoffline",
    label: label,
  );
}

class TrafficLightOffBadSignalMarker extends TrafficLightOffMarker {
  TrafficLightOffBadSignalMarker({
    required LatLng geo,
    double iconSize = 1,
    String? label,
  }): super(
    geo: geo,
    iconSize: iconSize,
    iconImage: "trafficlightoffbadsignal",
    label: label,
  );
}

/// A map layer which marks a traffic light on the map.
class TrafficLightGreenMarker extends SymbolOptions {
  /// Create a new traffic light marker.
  TrafficLightGreenMarker({
    required LatLng geo,
    double iconSize = 1,
  }): super(
    geometry: geo,
    iconImage: "trafficlightgreen",
    iconSize: iconSize,
    zIndex: 3,
  );
}

/// A map layer which marks a traffic light on the map.
class TrafficLightRedMarker extends SymbolOptions {
  /// Create a new traffic light marker.
  TrafficLightRedMarker({
    required LatLng geo,
    double iconSize = 1,
  }): super(
    geometry: geo,
    iconImage: "trafficlightred",
    iconSize: iconSize,
    zIndex: 3,
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
    iconSize: 2,
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
    iconSize: 0.75,
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
    iconSize: 0.75,
  );
}

/// A map layer which marks an intermediate position on the map.
class WaypointMarker extends SymbolOptions {
  /// Create a new waypoint marker.
  WaypointMarker({
    required LatLng geo,
  }): super(
    geometry: geo,
    iconImage: "waypoint",
    iconSize: 0.75,
    zIndex: 4,
  );
}
