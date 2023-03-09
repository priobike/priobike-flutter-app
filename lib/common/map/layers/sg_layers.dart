import 'dart:convert';
import 'dart:math';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/services/positioning_multi_lane.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/ride/services/ride_multi_lane.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/services/routing_multi_lane.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';

class TrafficLightsLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  TrafficLightsLayer(bool isDark, {hideBehindPosition = false}) {
    final showLabels = getIt<Settings>().sgLabelsMode == SGLabelsMode.enabled;
    final routing = getIt<Routing>();
    final userPosSnap = getIt<Positioning>().snap;
    if (routing.selectedRoute == null) return;
    for (int i = 0; i < routing.selectedRoute!.signalGroups.length; i++) {
      final sg = routing.selectedRoute!.signalGroups[i];
      final sgDistanceOnRoute = routing.selectedRoute!.signalGroupsDistancesOnRoute[i];
      // Clamp the value to not unnecessarily update the source.
      final distanceToSgOnRoute = max(-5, min(0, sgDistanceOnRoute - (userPosSnap?.distanceOnRoute ?? 0)));
      features.add(
        {
          "id": "traffic-light",
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [sg.position.lon, sg.position.lat],
          },
          "properties": {
            "id": sg.id,
            "isDark": isDark,
            "showLabels": showLabels,
            "distanceToSgOnRoute": distanceToSgOnRoute,
            "hideBehindPosition": hideBehindPosition,
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 1.0, String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists("traffic-lights");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(
            id: "traffic-lights", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final trafficLightIconsLayerExists = await mapController.style.styleLayerExists("traffic-lights-icons");
    if (!trafficLightIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: "traffic-lights",
            id: "traffic-lights-icons",
            iconSize: iconSize,
            iconAllowOverlap: true,
            textAllowOverlap: true,
            textIgnorePlacement: true,
            iconOpacity: 0,
          ),
          mapbox.LayerPosition(below: below));
      await mapController.style.setStyleLayerProperty(
          "traffic-lights-icons",
          'icon-image',
          json.encode([
            "case",
            ["get", "isDark"],
            "trafficlightonlinedarknocheck",
            "trafficlightonlinelightnocheck",
          ]));
      await mapController.style.setStyleLayerProperty(
          "traffic-lights-icons",
          'icon-opacity',
          json.encode(
            showAfter(zoom: 16, opacity: [
              "case",
              ["get", "hideBehindPosition"],
              [
                "case",
                [
                  "<",
                  ["get", "distanceToSgOnRoute"],
                  -5, // See above - this is clamped to [-5, 0]
                ],
                0,
                // Interpolate between -5 (opacity=0) and 0 (opacity=1) meters
                [
                  "interpolate",
                  ["linear"],
                  ["get", "distanceToSgOnRoute"],
                  -5, // See above - this is clamped to [-5, 0]
                  0,
                  0,
                  1
                ],
              ],
              1
            ]),
          ));
      await mapController.style.setStyleLayerProperty(
          "traffic-lights-icons",
          'text-field',
          json.encode([
            "case",
            ["get", "showLabels"],
            ["get", "id"],
            ""
          ]));
    }
    return "traffic-lights-icons";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists("traffic-lights");
    if (sourceExists) {
      final source = await mapController.style.getSource("traffic-lights");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class MultiLaneTrafficLightsLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  MultiLaneTrafficLightsLayer(bool isDark, {hideBehindPosition = false}) {
    final showLabels = getIt<Settings>().sgLabelsMode == SGLabelsMode.enabled;
    final routing = getIt<RoutingMultiLane>();
    final userPosSnap = getIt<PositioningMultiLane>().snap;

    if (routing.selectedRoute == null) return;
    for (int i = 0; i < routing.selectedRoute!.signalGroups.length; i++) {
      final sg = routing.selectedRoute!.signalGroups[i];
      final sgDistanceOnRoute = sg.distanceOnRoute;
      // Clamp the value to not unnecessarily update the source.
      final distanceToSgOnRoute = max(-5, min(0, sgDistanceOnRoute - (userPosSnap?.distanceOnRoute ?? 0)));
      features.add(
        {
          "id": "traffic-light",
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [sg.position.lon, sg.position.lat],
          },
          "properties": {
            "id": sg.id,
            "isDark": isDark,
            "showLabels": showLabels,
            "distanceToSgOnRoute": distanceToSgOnRoute,
            "hideBehindPosition": hideBehindPosition,
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 1.0, String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists("crossings");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: "crossings", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final trafficLightIconsLayerExists = await mapController.style.styleLayerExists("crossing-icons");
    if (!trafficLightIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: "crossings",
            id: "crossing-icons",
            iconSize: iconSize,
            iconAllowOverlap: true,
            textAllowOverlap: true,
            textIgnorePlacement: true,
            iconOpacity: 0,
          ),
          mapbox.LayerPosition(below: below));
      await mapController.style.setStyleLayerProperty(
          "crossing-icons",
          'icon-image',
          json.encode([
            "case",
            ["get", "isDark"],
            "trafficlightonlinedarknocheck",
            "trafficlightonlinelightnocheck",
          ]));
      await mapController.style.setStyleLayerProperty(
          "crossing-icons",
          'icon-opacity',
          json.encode(
            showAfter(zoom: 16, opacity: [
              "case",
              ["get", "hideBehindPosition"],
              [
                "case",
                [
                  "<",
                  ["get", "distanceToSgOnRoute"],
                  -5, // See above - this is clamped to [-5, 0]
                ],
                0,
                // Interpolate between -5 (opacity=0) and 0 (opacity=1) meters
                [
                  "interpolate",
                  ["linear"],
                  ["get", "distanceToSgOnRoute"],
                  -5, // See above - this is clamped to [-5, 0]
                  0,
                  0,
                  1
                ],
              ],
              1
            ]),
          ));
      await mapController.style.setStyleLayerProperty(
          "crossing-icons",
          'text-field',
          json.encode([
            "case",
            ["get", "showLabels"],
            ["get", "id"],
            ""
          ]));
    }
    return "crossing-icons";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists("crossings");
    if (sourceExists) {
      final source = await mapController.style.getSource("crossings");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class TrafficLightMultiLaneLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  TrafficLightMultiLaneLayer(bool isDark) {
    final ride = getIt<RideMultiLane>();
    final currentSgs = ride.currentSignalGroups;

    for (final sg in currentSgs) {
      String sgIcon;
      switch (ride.predictionServiceMultiLane?.recommendations[sg.id]?.calcCurrentSignalPhase) {
        case Phase.green:
          if (isDark) {
            sgIcon = "trafficlightonlinegreendark";
          } else {
            sgIcon = "trafficlightonlinegreenlight";
          }
          break;
        case Phase.amber:
          if (isDark) {
            sgIcon = "trafficlightonlineamberdark";
          } else {
            sgIcon = "trafficlightonlineamberlight";
          }
          break;
        case Phase.redAmber:
          if (isDark) {
            sgIcon = "trafficlightonlineamberdark";
          } else {
            sgIcon = "trafficlightonlineamberlight";
          }
          break;
        case Phase.red:
          if (isDark) {
            sgIcon = "trafficlightonlinereddark";
          } else {
            sgIcon = "trafficlightonlineredlight";
          }
          break;
        default:
          if (isDark) {
            sgIcon = "trafficlightonlinedarkdark";
          } else {
            sgIcon = "trafficlightonlinedarklight";
          }
          break;
      }

      if (ride.predictionServiceMultiLane?.predictions[sg.id]?.predictionQuality == null) return;
      if (ride.predictionServiceMultiLane!.predictions[sg.id]!.predictionQuality < Ride.qualityThreshold) return;

      final sgPos = sg.position;

      features.add(
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [sgPos.lon, sgPos.lat],
          },
          "properties": {
            "sgIcon": sgIcon,
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 1.0, String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists("traffic-light");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(
            id: "traffic-light", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final trafficLightIconsLayerExists = await mapController.style.styleLayerExists("traffic-light-icon");
    if (!trafficLightIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: "traffic-light",
            id: "traffic-light-icon",
            iconSize: iconSize,
            iconAllowOverlap: true,
            textAllowOverlap: true,
            textIgnorePlacement: true,
          ),
          mapbox.LayerPosition(below: below));
      await mapController.style
          .setStyleLayerProperty("traffic-light-icon", 'icon-image', json.encode(["get", "sgIcon"]));
    }

    return "traffic-light-icon";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists("traffic-light");
    if (sourceExists) {
      final source = await mapController.style.getSource("traffic-light");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class TrafficLightLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  TrafficLightLayer(bool isDark) {
    final ride = getIt<Ride>();
    final sgQuality = ride.predictionComponent?.prediction?.predictionQuality;
    String sgIcon;
    switch (ride.predictionComponent?.recommendation?.calcCurrentSignalPhase) {
      case Phase.green:
        if (isDark) {
          sgIcon = "trafficlightonlinegreendark";
        } else {
          sgIcon = "trafficlightonlinegreenlight";
        }
        break;
      case Phase.amber:
        if (isDark) {
          sgIcon = "trafficlightonlineamberdark";
        } else {
          sgIcon = "trafficlightonlineamberlight";
        }
        break;
      case Phase.redAmber:
        if (isDark) {
          sgIcon = "trafficlightonlineamberdark";
        } else {
          sgIcon = "trafficlightonlineamberlight";
        }
        break;
      case Phase.red:
        if (isDark) {
          sgIcon = "trafficlightonlinereddark";
        } else {
          sgIcon = "trafficlightonlineredlight";
        }
        break;
      default:
        if (isDark) {
          sgIcon = "trafficlightonlinedarkdark";
        } else {
          sgIcon = "trafficlightonlinedarklight";
        }
        break;
    }
    final sgPos = ride.userSelectedSG?.position ?? ride.calcCurrentSG?.position;
    if (sgQuality == null || sgPos == null) return;
    if (sgQuality < Ride.qualityThreshold) return;

    features.add(
      {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [sgPos.lon, sgPos.lat],
        },
        "properties": {
          "sgIcon": sgIcon,
        },
      },
    );
  }

  /// Install the overlay on the map controller.
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 1.0, String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists("traffic-light");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(
            id: "traffic-light", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final trafficLightIconsLayerExists = await mapController.style.styleLayerExists("traffic-light-icon");
    if (!trafficLightIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: "traffic-light",
            id: "traffic-light-icon",
            iconSize: iconSize,
            iconAllowOverlap: true,
            textAllowOverlap: true,
            textIgnorePlacement: true,
          ),
          mapbox.LayerPosition(below: below));
      await mapController.style
          .setStyleLayerProperty("traffic-light-icon", 'icon-image', json.encode(["get", "sgIcon"]));
    }

    return "traffic-light-icon";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists("traffic-light");
    if (sourceExists) {
      final source = await mapController.style.getSource("traffic-light");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class OfflineCrossingsLayer {
  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  OfflineCrossingsLayer(bool isDark, {hideBehindPosition = false}) {
    final showLabels = getIt<Settings>().sgLabelsMode == SGLabelsMode.enabled;
    final routing = getIt<Routing>();
    final userPosSnap = getIt<Positioning>().snap;
    if (routing.selectedRoute == null) return;
    for (int i = 0; i < routing.selectedRoute!.crossings.length; i++) {
      final crossing = routing.selectedRoute!.crossings[i];
      final crossingDistanceOnRoute = routing.selectedRoute!.crossingsDistancesOnRoute[i];
      if (crossing.connected) continue;
      // Clamp the value to not unnecessarily update the source.
      final distanceToCrossingOnRoute = max(-5, min(0, crossingDistanceOnRoute - (userPosSnap?.distanceOnRoute ?? 0)));
      features.add(
        {
          "id": "traffic-light",
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [crossing.position.lon, crossing.position.lat],
          },
          "properties": {
            "name": crossing.name,
            "isDark": isDark,
            "showLabels": showLabels,
            "distanceToCrossingOnRoute": distanceToCrossingOnRoute,
            "hideBehindPosition": hideBehindPosition,
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<String> install(mapbox.MapboxMap mapController, {iconSize = 1.0, String? below}) async {
    final sourceExists = await mapController.style.styleSourceExists("offline-crossings");
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(
            id: "offline-crossings", data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final offlineCrossingsIconsLayerExists = await mapController.style.styleLayerExists("offline-crossings-icons");
    if (!offlineCrossingsIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: "offline-crossings",
            id: "offline-crossings-icons",
            iconSize: iconSize,
            iconOpacity: 0.0,
            iconAllowOverlap: true,
            textAllowOverlap: true,
            textIgnorePlacement: true,
          ),
          mapbox.LayerPosition(below: below));
      await mapController.style.setStyleLayerProperty(
          "offline-crossings-icons",
          'icon-image',
          json.encode([
            "case",
            ["get", "isDark"],
            "trafficlightdisconnecteddark",
            "trafficlightdisconnectedlight",
          ]));
      await mapController.style.setStyleLayerProperty(
          "offline-crossings-icons",
          'icon-opacity',
          json.encode(
            showAfter(zoom: 16, opacity: [
              "case",
              ["get", "hideBehindPosition"],
              [
                "case",
                [
                  "<",
                  ["get", "distanceToCrossingOnRoute"],
                  -5, // See above - this is clamped to [-5, 0]
                ],
                0,
                // Interpolate between -5 (opacity=0) and 0 (opacity=1) meters
                [
                  "interpolate",
                  ["linear"],
                  ["get", "distanceToCrossingOnRoute"],
                  -5, // See above - this is clamped to [-5, 0]
                  0,
                  0,
                  1
                ],
              ],
              1
            ]),
          ));
      await mapController.style.setStyleLayerProperty(
          "offline-crossings-icons",
          'text-field',
          json.encode([
            "case",
            ["get", "showLabels"],
            ["get", "name"],
            ""
          ]));
    }

    return "offline-crossings-icons";
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists("offline-crossings");
    if (sourceExists) {
      final source = await mapController.style.getSource("offline-crossings");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}
