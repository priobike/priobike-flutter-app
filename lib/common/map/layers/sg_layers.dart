import 'dart:convert';
import 'dart:math';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/layers/utils.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/status/services/sg.dart';

class TrafficLightsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "traffic-lights";

  /// The ID of the Mapbox layer.
  static const layerId = "traffic-lights-icons";

  /// The ID of the touch indicators Mapbox layer.
  static const touchIndicatorsLayerId = "traffic-lights-touch-indicators";

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
      bool showTouchIndicator = true;
      final ride = getIt<Ride>();
      if (ride.userSelectedSG != null) {
        showTouchIndicator = ride.userSelectedSG!.id != sg.id;
      } else if (ride.calcCurrentSG != null) {
        showTouchIndicator = ride.calcCurrentSG!.id != sg.id;
      }
      features.add(
        {
          "id": "traffic-light-$i", // Required for the click listener.
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
            "showTouchIndicators": showTouchIndicator,
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {iconSize = 1.0, at = 0, showTouchIndicator = false}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final trafficLightIconsLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!trafficLightIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerId,
            iconSize: iconSize,
            iconAllowOverlap: true,
            textAllowOverlap: true,
            textIgnorePlacement: true,
            iconOpacity: 0.4,
            minZoom: 13.0,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-image',
          json.encode([
            "case",
            ["get", "isDark"],
            "trafficlightonlinedarknocheck",
            "trafficlightonlinelightnocheck",
          ]));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 16, opacity: [
              "case",
              ["get", "hideBehindPosition"],
              [
                "case",
                [
                  "<=",
                  ["get", "distanceToSgOnRoute"],
                  -5,
                ],
                0.4,
                1
              ],
              1
            ]),
          ));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-field',
          json.encode([
            "case",
            ["get", "showLabels"],
            ["get", "id"],
            ""
          ]));
    }

    if (showTouchIndicator) {
      final trafficLightTouchIndicatorsLayerExists = await mapController.style.styleLayerExists(touchIndicatorsLayerId);
      if (!trafficLightTouchIndicatorsLayerExists) {
        await mapController.style.addLayerAt(
            mapbox.SymbolLayer(
              sourceId: sourceId,
              id: touchIndicatorsLayerId,
              iconSize: iconSize,
              iconAllowOverlap: true,
              textAllowOverlap: true,
              textIgnorePlacement: true,
              iconOpacity: 0,
            ),
            mapbox.LayerPosition(at: at));
        await mapController.style.setStyleLayerProperty(
            touchIndicatorsLayerId,
            'icon-image',
            json.encode([
              "case",
              ["get", "isDark"],
              "trafficlighttouchindicatordark",
              "trafficlighttouchindicatorlight",
            ]));
        await mapController.style.setStyleLayerProperty(
            touchIndicatorsLayerId,
            'icon-opacity',
            json.encode(
              showAfter(zoom: 16, opacity: [
                "case",
                ["get", "showTouchIndicators"],
                [
                  "case",
                  ["get", "hideBehindPosition"],
                  [
                    "case",
                    [
                      "<=",
                      ["get", "distanceToSgOnRoute"],
                      -5,
                    ],
                    0.4,
                    1
                  ],
                  1,
                ],
                0
              ]),
            ));
      }
    }
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class TrafficLightsLayerClickable {
  /// The ID of the Mapbox source.
  static const sourceId = "traffic-lights-clickable";

  /// The ID of the Mapbox layer.
  static const layerId = "traffic-lights-icons-clickable";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  TrafficLightsLayerClickable() {
    final routing = getIt<Routing>();
    if (routing.selectedRoute == null) return;
    for (int i = 0; i < routing.selectedRoute!.signalGroups.length; i++) {
      final sg = routing.selectedRoute!.signalGroups[i];
      // Clamp the value to not unnecessarily update the source.

      features.add(
        {
          "id": "traffic-light-clickable-$i", // Required for the click listener.
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [sg.position.lon, sg.position.lat],
          },
          "properties": {
            "id": sg.id,
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {iconSize = 1.0, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final trafficLightIconsLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!trafficLightIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerId,
            iconSize: iconSize,
            iconAllowOverlap: true,
            iconAnchor: mapbox.IconAnchor.BOTTOM,
            iconOpacity: 1,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(layerId, 'icon-image', 'trafficlightclicklayer');
    }
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class TrafficLightLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "traffic-light";

  /// The ID of the Mapbox layer.
  static const layerId = "traffic-light-icon";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  TrafficLightLayer(bool isDark) {
    final ride = getIt<Ride>();
    String sgIcon;
    switch (ride.predictionProvider?.recommendation?.calcCurrentSignalPhase) {
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
    if (sgPos == null) return;

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
  Future<void> install(mapbox.MapboxMap mapController, {iconSize = 1.0, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final trafficLightIconsLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!trafficLightIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerId,
            iconSize: iconSize,
            iconAllowOverlap: true,
            textAllowOverlap: true,
            textIgnorePlacement: true,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(layerId, 'icon-image', json.encode(["get", "sgIcon"]));
    }
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class OfflineCrossingsLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "offline-crossings";

  /// The ID of the Mapbox layer.
  static const layerId = "offline-crossings-icons";

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
  Future<void> install(mapbox.MapboxMap mapController, {iconSize = 1.0, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final offlineCrossingsIconsLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!offlineCrossingsIconsLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.SymbolLayer(
            sourceId: sourceId,
            id: layerId,
            iconSize: iconSize,
            iconOpacity: 0.4,
            iconAllowOverlap: true,
            textAllowOverlap: true,
            textIgnorePlacement: true,
            minZoom: 13.0,
          ),
          mapbox.LayerPosition(at: at));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-image',
          json.encode([
            "case",
            ["get", "isDark"],
            "trafficlightdisconnecteddark",
            "trafficlightdisconnectedlight",
          ]));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'icon-opacity',
          json.encode(
            showAfter(zoom: 16, opacity: [
              "case",
              ["get", "hideBehindPosition"],
              [
                "case",
                [
                  "<=",
                  ["get", "distanceToCrossingOnRoute"],
                  -5,
                ],
                0.4,
                1
              ],
              1
            ]),
          ));
      await mapController.style.setStyleLayerProperty(
          layerId,
          'text-field',
          json.encode([
            "case",
            ["get", "showLabels"],
            ["get", "name"],
            ""
          ]));
    }
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class RouteCrossingsCircleLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "route-crossings-circle";

  /// The ID of the Mapbox layer.
  static const layerId = "route-crossing-circles";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  RouteCrossingsCircleLayer() {
    final routing = getIt<Routing>();
    if (routing.selectedRoute == null) return;
    if (routing.allRoutes == null) return;

    for (Route route in routing.allRoutes!) {
      if (route.idx == routing.selectedRoute!.idx) continue;

      // Add all crossings that are not connected. (grey circles)
      for (int i = 0; i < route.crossings.length; i++) {
        final crossing = route.crossings[i];
        if (crossing.connected) continue;

        features.add(
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [crossing.position.lon, crossing.position.lat],
            },
            "properties": {
              "circle-color": "#D9D9D9",
              "circle-stroke-color": "#989898",
            },
          },
        );
      }

      // Add all sgs. (blue and green circles)
      final status = getIt<PredictionSGStatus>();
      for (int i = 0; i < route.signalGroups.length; i++) {
        final sg = route.signalGroups[i];
        final sgStatus = status.cache[sg.id];

        features.add(
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [sg.position.lon, sg.position.lat],
            },
            "properties": {
              "circle-color": sgStatus?.predictionState == SGPredictionState.ok ? "#00FF6A" : "#0073FF",
              "circle-stroke-color": sgStatus?.predictionState == SGPredictionState.ok ? "#00B34A" : "#004596",
            },
          },
        );
      }
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {iconSize = 1.0, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final crossingCircleLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!crossingCircleLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.CircleLayer(sourceId: sourceId, id: layerId, circleRadius: 6, circleStrokeWidth: 1, minZoom: 8.0),
          mapbox.LayerPosition(at: at));
    }

    await mapController.style.setStyleLayerProperty(
        layerId,
        'circle-opacity',
        json.encode(
          showAfter(zoom: 10),
        ));

    await mapController.style.setStyleLayerProperty(
        layerId,
        'circle-stroke-opacity',
        json.encode(
          showAfter(zoom: 10),
        ));

    await mapController.style.setStyleLayerProperty(
      layerId,
      'circle-color',
      json.encode(["get", "circle-color"]),
    );

    await mapController.style.setStyleLayerProperty(
      layerId,
      'circle-stroke-color',
      json.encode(["get", "circle-stroke-color"]),
    );

    await mapController.style.setStyleLayerProperty(
        layerId,
        'circle-radius',
        json.encode(
          reduceRadius(zoom: 14, radius: 6),
        ));
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}

class SelectedRouteCrossingsCircleLayer {
  /// The ID of the Mapbox source.
  static const sourceId = "selected-route-crossings-circle";

  /// The ID of the Mapbox layer.
  static const layerId = "selected-route-crossing-circles";

  /// The features to display.
  final List<dynamic> features = List.empty(growable: true);

  SelectedRouteCrossingsCircleLayer() {
    final routing = getIt<Routing>();
    if (routing.selectedRoute == null) return;

    // Add all crossings that are not connected. (grey circles)
    for (int i = 0; i < routing.selectedRoute!.crossings.length; i++) {
      final crossing = routing.selectedRoute!.crossings[i];
      if (crossing.connected) continue;

      features.add(
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [crossing.position.lon, crossing.position.lat],
          },
          "properties": {
            "circle-color": "#D9D9D9",
            "circle-stroke-color": "#989898",
          },
        },
      );
    }

    // Add all sgs. (blue and green circles)
    final status = getIt<PredictionSGStatus>();
    for (int i = 0; i < routing.selectedRoute!.signalGroups.length; i++) {
      final sg = routing.selectedRoute!.signalGroups[i];
      final sgStatus = status.cache[sg.id];

      features.add(
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [sg.position.lon, sg.position.lat],
          },
          "properties": {
            "circle-color": sgStatus?.predictionState == SGPredictionState.ok ? "#00FF6A" : "#0073FF",
            "circle-stroke-color": sgStatus?.predictionState == SGPredictionState.ok ? "#00B34A" : "#004596",
          },
        },
      );
    }
  }

  /// Install the overlay on the map controller.
  Future<void> install(mapbox.MapboxMap mapController, {iconSize = 1.0, at = 0}) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (!sourceExists) {
      await mapController.style.addSource(
        mapbox.GeoJsonSource(id: sourceId, data: json.encode({"type": "FeatureCollection", "features": features})),
      );
    } else {
      await update(mapController);
    }

    final crossingCircleLayerExists = await mapController.style.styleLayerExists(layerId);
    if (!crossingCircleLayerExists) {
      await mapController.style.addLayerAt(
          mapbox.CircleLayer(sourceId: sourceId, id: layerId, circleRadius: 6, circleStrokeWidth: 1, minZoom: 8.0),
          mapbox.LayerPosition(at: at));
    }

    await mapController.style.setStyleLayerProperty(
        layerId,
        'circle-opacity',
        json.encode(
          showAfter(zoom: 10),
        ));

    await mapController.style.setStyleLayerProperty(
        layerId,
        'circle-stroke-opacity',
        json.encode(
          showAfter(zoom: 10),
        ));

    await mapController.style.setStyleLayerProperty(
      layerId,
      'circle-color',
      json.encode(["get", "circle-color"]),
    );

    await mapController.style.setStyleLayerProperty(
      layerId,
      'circle-stroke-color',
      json.encode(["get", "circle-stroke-color"]),
    );

    await mapController.style.setStyleLayerProperty(
        layerId,
        'circle-radius',
        json.encode(
          reduceRadius(zoom: 14, radius: 6),
        ));
  }

  /// Update the overlay on the map controller (without updating the layers).
  update(mapbox.MapboxMap mapController) async {
    final sourceExists = await mapController.style.styleSourceExists(sourceId);
    if (sourceExists) {
      final source = await mapController.style.getSource(sourceId);
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }
  }
}
