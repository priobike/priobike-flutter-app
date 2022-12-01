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
    await addImageFromAsset("disconnected", "assets/images/disconnected.drawio.png");
    await addImageFromAsset("disconnectedtilted", "assets/images/disconnected-tilted.drawio.png");
    await addImageFromAsset("badsignal", "assets/images/bad-signal.drawio.png");
    await addImageFromAsset("badsignaltilted", "assets/images/bad-signal-tilted.drawio.png");
    await addImageFromAsset("offline", "assets/images/offline.drawio.png");
    await addImageFromAsset("offlinetilted", "assets/images/offline-tilted.drawio.png");
    await addImageFromAsset("online", "assets/images/online.drawio.png");
    await addImageFromAsset("onlinetilted", "assets/images/online-tilted.drawio.png");
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

    await addImageFromAsset("routeLabelSMM", "assets/images/route-label-smm.png");
    await addImageFromAsset("routeLabelPMM", "assets/images/route-label-pmm.png");
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
    int zIndex = 1,
  }) : super(
          geometry: geo,
          iconImage: "alert",
          iconSize: iconSize,
          textField: "$number",
          textSize: 12,
          zIndex: zIndex,
        );
}

/// A map layer which is a label for the Route with time.
class RouteLabel extends SymbolOptions {
  /// Create a new discomfort location marker.
  RouteLabel({
    required LatLng geo,
    required int number,
    double iconSize = 0.5,
    required bool primary,
  }) : super(
          geometry: geo,
          iconImage: primary ? "routeLabelPMM" : "routeLabelSMM",
          iconSize: iconSize,
          iconOffset: const Offset(0, -10),
          textField: "$number min",
          textOffset: const Offset(0, -1.25),
          textSize: 12,
          textColor: primary ? "#ffffff" : "#000000",
          zIndex: primary ? 7 : 6,
        );
}

/// A map layer which marks a traffic light on the map.
class TrafficLightOffMarker extends SymbolOptions {
  /// Create a new traffic light marker.
  TrafficLightOffMarker({
    required LatLng geo,
    double iconSize = 1,
    int zIndex = 2,
    String iconImage = "trafficlightoff",
    String? label,
  }) : super(
          geometry: geo,
          iconImage: iconImage,
          iconSize: iconSize,
          zIndex: zIndex,
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

class OnlineMarker extends TrafficLightOffMarker {
  OnlineMarker({
    required LatLng geo,
    double iconSize = 1,
    String? label,
    bool tilted = false,
  }) : super(
          geo: geo,
          iconSize: iconSize,
          iconImage: tilted ? "onlinetilted" : "online",
          zIndex: 3,
          label: label,
        );
}

class DisconnectedMarker extends TrafficLightOffMarker {
  DisconnectedMarker({
    required LatLng geo,
    double iconSize = 1,
    String? label,
    bool tilted = false,
  }) : super(
          geo: geo,
          iconSize: iconSize,
          iconImage: tilted ? "disconnectedtilted" : "disconnected",
          zIndex: 3,
          label: label,
        );
}

class OfflineMarker extends TrafficLightOffMarker {
  OfflineMarker({
    required LatLng geo,
    double iconSize = 1,
    String? label,
    bool tilted = false,
  }) : super(
          geo: geo,
          iconSize: iconSize,
          iconImage: tilted ? "offlinetilted" : "offline",
          zIndex: 3,
          label: label,
        );
}

class BadSignalMarker extends TrafficLightOffMarker {
  BadSignalMarker({
    required LatLng geo,
    double iconSize = 1,
    String? label,
    bool tilted = false,
  }) : super(
          geo: geo,
          iconSize: iconSize,
          iconImage: tilted ? "badsignaltilted" : "badsignal",
          zIndex: 3,
          label: label,
        );
}

/// A map layer which marks a traffic light on the map.
class TrafficLightGreenMarker extends SymbolOptions {
  /// Create a new traffic light marker.
  TrafficLightGreenMarker({required LatLng geo, double iconSize = 1, double iconOpacity = 1})
      : super(
          geometry: geo,
          iconImage: "trafficlightgreen",
          iconSize: iconSize,
          iconOpacity: iconOpacity,
          zIndex: 5,
        );
}

/// A map layer which marks a traffic light on the map.
class TrafficLightRedMarker extends SymbolOptions {
  /// Create a new traffic light marker.
  TrafficLightRedMarker({
    required LatLng geo,
    double iconSize = 1,
    double iconOpacity = 1,
  }) : super(
          geometry: geo,
          iconImage: "trafficlightred",
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
