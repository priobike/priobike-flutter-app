import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tracking/services/tracking.dart';

class LastTrackView extends StatefulWidget {
  const LastTrackView({Key? key}) : super(key: key);

  @override
  LastTrackViewState createState() => LastTrackViewState();
}

class LastTrackViewState extends State<LastTrackView> {
  /// The distance model.
  static const vincenty = Distance(roundResult: false);

  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The map controller.
  mapbox.MapboxMap? mapController;

  /// The navigation nodes of the driven route.
  List<NavigationNode> routeNodes = [];

  /// Called when a listener callback of a ChangeNotifier is fired.
  Future<void> update() async {
    await loadRoute();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    tracking = getIt<Tracking>();
    tracking.addListener(update);
    settings = getIt<Settings>();
    settings.addListener(update);

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        await tracking.loadPreviousTracks();
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    tracking.removeListener(update);
    settings.removeListener(update);
    super.dispose();
  }

  /// Called when the map is created.
  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(mapbox.MapboxMap controller) async {
    mapController = controller;
    mapController!.gestures.updateSettings(mapbox.GesturesSettings(
      doubleTapToZoomInEnabled: false,
      doubleTouchToZoomOutEnabled: false,
      pinchPanEnabled: false,
      pinchToZoomDecelerationEnabled: false,
      pinchToZoomEnabled: false,
      quickZoomEnabled: false,
      rotateDecelerationEnabled: false,
      rotateEnabled: false,
      scrollDecelerationEnabled: false,
      scrollEnabled: false,
      simultaneousRotateAndPinchToZoomEnabled: false,
    ));
  }

  Future<void> loadRoute() async {
    if (tracking.previousTracks == null) {
      return;
    }
    if (tracking.previousTracks!.isEmpty) {
      return;
    }
    if (mapController == null) {
      return;
    }

    routeNodes = getDrivenRoute(tracking.previousTracks!.last.routes);

    final lineGeoJSON = getRouteLineGeoJSON(routeNodes);
    final pointsGeoJSON = getRoutePointsGeoJSON(routeNodes);

    const lineSourceId = 'last-route-source';
    const lineLayerId = 'last-route-layer';

    final lineSourceExists = await mapController!.style.styleSourceExists(lineSourceId);
    if (!lineSourceExists) {
      await mapController!.style.addSource(
        mapbox.GeoJsonSource(
            id: lineSourceId, data: json.encode({"type": "FeatureCollection", "features": lineGeoJSON})),
      );
      await Future.delayed(const Duration(milliseconds: 1000));
    } else {
      final source = await mapController!.style.getSource(lineSourceId);
      (source as mapbox.GeoJsonSource)
          .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": lineGeoJSON}));
    }
    final routeLayerExists = await mapController!.style.styleLayerExists(lineLayerId);
    if (!routeLayerExists) {
      await mapController!.style.addLayer(
        mapbox.LineLayer(
          sourceId: lineSourceId,
          id: lineLayerId,
          lineColor: CI.blue.value,
          lineJoin: mapbox.LineJoin.ROUND,
          lineCap: mapbox.LineCap.ROUND,
          lineWidth: 4,
        ),
      );
    }

    const pointsSourceId = 'last-route-points-source';
    const pointsLayerId = 'last-route-points-layer';

    final pointSourceExists = await mapController!.style.styleSourceExists(pointsSourceId);
    if (!pointSourceExists) {
      await mapController!.style.addSource(
        mapbox.GeoJsonSource(
            id: pointsSourceId, data: json.encode({"type": "FeatureCollection", "features": pointsGeoJSON})),
      );
    } else {
      final source = await mapController!.style.getSource(pointsSourceId);
      (source as mapbox.GeoJsonSource)
          .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": pointsGeoJSON}));
    }
    final waypointsIconsLayerExists = await mapController!.style.styleLayerExists(pointsLayerId);
    if (!waypointsIconsLayerExists) {
      await mapController!.style.addLayer(
        mapbox.SymbolLayer(
            sourceId: pointsSourceId,
            id: pointsLayerId,
            iconSize: 0.2,
            textAllowOverlap: true,
            textIgnorePlacement: true,
            iconAllowOverlap: true),
      );
      await mapController!.style.setStyleLayerProperty(
          pointsLayerId,
          'icon-image',
          json.encode([
            "case",
            ["get", "isFirst"],
            "start",
            ["get", "isLast"],
            "destination",
            "waypoint",
          ]));
    }

    await fitCameraToRouteBounds(routeNodes);
  }

  /// A callback which is executed when the map style was (re-)loaded.
  Future<void> onStyleLoaded(mapbox.StyleLoadedEventData styleLoadedEventData) async {
    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // Load the route.
    await loadRoute();
  }

  /// Calculate the padded bounds of this route.
  mapbox.CoordinateBounds getPaddedBounds(List<NavigationNode> navigationNodes) {
    var maxNorth = 0.0;
    var maxEast = 0.0;
    var maxSouth = double.infinity;
    var maxWest = double.infinity;

    for (final node in navigationNodes) {
      final lat = node.lat;
      final lon = node.lon;
      if (lat > maxNorth) {
        maxNorth = lat;
      }
      if (lat < maxSouth) {
        maxSouth = lat;
      }
      if (lon > maxEast) {
        maxEast = lon;
      }
      if (lon < maxWest) {
        maxWest = lon;
      }
    }

    const pad = 0.003;
    return mapbox.CoordinateBounds(
        southwest: mapbox.Point(
            coordinates: mapbox.Position(
          maxWest - pad,
          maxSouth - pad,
        )).toJson(),
        northeast: mapbox.Point(
            coordinates: mapbox.Position(
          maxEast + pad,
          maxNorth + pad,
        )).toJson(),
        infiniteBounds: false);
  }

  Future<void> fitCameraToRouteBounds(List<NavigationNode> navigationNodes) async {
    if (mapController == null || !mounted) return;
    final frame = MediaQuery.of(context);
    final currentCameraOptions = await mapController?.getCameraState();
    if (currentCameraOptions == null) return;

    mapbox.MbxEdgeInsets padding = mapbox.MbxEdgeInsets(
      top: 20 * frame.devicePixelRatio,
      left: 0,
      bottom: 0,
      right: 0,
    );

    final cameraOptionsForBounds = await mapController?.cameraForCoordinateBounds(
      getPaddedBounds(navigationNodes),
      padding,
      currentCameraOptions.bearing,
      currentCameraOptions.pitch,
    );
    if (cameraOptionsForBounds == null) return;
    await mapController?.flyTo(
      cameraOptionsForBounds,
      mapbox.MapAnimationOptions(duration: 1000),
    );
  }

  List<NavigationNode> getDrivenRoute(Map<int, Route> routes) {
    List<NavigationNode> drivenRoute = [];

    // Find reroute locations
    List<int> rerouteNodeIndices = [];
    if (routes.values.length > 1) {
      for (var routeIdx = 0; routeIdx < routes.values.length; routeIdx++) {
        if (routeIdx >= routes.values.length - 1) {
          // If it's the last route, we can stop here.
          break;
        }
        final navigationNodes = routes.values.toList()[routeIdx].route;
        final nextRoutesFirstNavigationNode = routes.values.toList()[routeIdx + 1].route[0];
        var currentShortestDistance = double.infinity;
        var currentShortestDistanceIdx = -1;
        for (var navigationNodeIdx = 0; navigationNodeIdx < navigationNodes.length; navigationNodeIdx++) {
          final distance = vincenty.distance(
            LatLng(navigationNodes[navigationNodeIdx].lat, navigationNodes[navigationNodeIdx].lon),
            LatLng(nextRoutesFirstNavigationNode.lat, nextRoutesFirstNavigationNode.lon),
          );
          if (distance < currentShortestDistance) {
            currentShortestDistance = distance;
            currentShortestDistanceIdx = navigationNodeIdx;
          }
        }
        rerouteNodeIndices.add(currentShortestDistanceIdx);
      }
    }

    // Add points
    for (var routeIdx = 0; routeIdx < routes.values.length; routeIdx++) {
      final navigationNodes = routes.values.toList()[routeIdx].route;
      for (var navigationNodeIdx = 0; navigationNodeIdx < navigationNodes.length; navigationNodeIdx++) {
        // If it's the last route, add all navigation nodes
        if (routeIdx >= routes.values.length - 1) {
          drivenRoute.add(navigationNodes[navigationNodeIdx]);
        } else {
          if (navigationNodeIdx == rerouteNodeIndices[routeIdx]) {
            // Go to next route.
            break;
          }
          drivenRoute.add(navigationNodes[navigationNodeIdx]);
        }
      }
    }

    return drivenRoute;
  }

  List<dynamic> getRoutePointsGeoJSON(List<NavigationNode> navigationNodes) {
    List<dynamic> features = List.empty(growable: true);

    features.add(
      {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [navigationNodes.first.lon, navigationNodes.first.lat],
        },
        "properties": {
          "isFirst": true,
          "isLast": false,
        },
      },
    );

    features.add(
      {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [navigationNodes.last.lon, navigationNodes.last.lat],
        },
        "properties": {
          "isFirst": false,
          "isLast": true,
        },
      },
    );

    return features;
  }

  List<dynamic> getRouteLineGeoJSON(List<NavigationNode> navigationNodes) {
    List<dynamic> features = [
      {
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": [],
        },
      }
    ];
    for (int i = navigationNodes.length - 1; i >= 0; i--) {
      final navNode = navigationNodes[i];
      features[0]["geometry"]["coordinates"].add([navNode.lon, navNode.lat]);
    }
    return features;
  }

  String formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 60) {
      return "$seconds Sekunden";
    }
    if (seconds < 3600) {
      final minutes = seconds / 60;
      return "$minutes Minuten";
    }
    final hours = seconds / 3600;
    return "$hours Stunden";
  }

  @override
  Widget build(BuildContext context) {
    if (tracking.previousTracks == null) {
      return Container();
    }
    if (tracking.previousTracks!.isEmpty) {
      return Container();
    }

    final lastTrackDate = DateTime.fromMillisecondsSinceEpoch(tracking.previousTracks!.last.startTime);
    final lastTrackDateFormatted = DateFormat.yMMMMd("de").format(lastTrackDate);
    final lastTrackDuration = tracking.previousTracks!.last.endTime != null
        ? Duration(milliseconds: tracking.previousTracks!.last.endTime! - tracking.previousTracks!.last.startTime)
        : null;
    final lastTrackDurationFormatted = lastTrackDuration != null ? formatDuration(lastTrackDuration) : null;

    // Required when we change the app theme in the settings and afterwards return to this widget
    // (build method called second time there).
    // Commented out for now until we have proper minimalistic styles for light and dark mode for this map.
    /*if (mapController != null) {
      final mapDesigns = getIt<MapDesigns>();
      mapController!.style.setStyleURI(Theme.of(context).colorScheme.brightness == Brightness.light
          ? mapDesigns.mapDesign.lightStyle
          : mapDesigns.mapDesign.darkStyle);
    }*/

    return HPad(
      child: Tile(
        fill: Theme.of(context).colorScheme.background,
        content: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35,
              height: MediaQuery.of(context).size.width * 0.35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppMap(
                  onMapCreated: onMapCreated,
                  onStyleLoaded: onStyleLoaded,
                  logoViewOrnamentPosition: mapbox.OrnamentPosition.BOTTOM_LEFT,
                  logoViewMargins: const Point(10, 10),
                  attributionButtonOrnamentPosition: mapbox.OrnamentPosition.BOTTOM_RIGHT,
                  attributionButtonMargins: const Point(0, 5),
                  styleUri: "mapbox://styles/snrmtths/clg0tmmn2004501p6fv3i6lnp",
                ),
              ),
            ),
            const SmallHSpace(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BoldContent(
                  text: "Deine letzte Fahrt",
                  context: context,
                ),
                const SmallVSpace(),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Content(
                          text: "🗓",
                          context: context,
                        ),
                        if (lastTrackDurationFormatted != null) ...[
                          const SmallVSpace(),
                          Content(
                            text: "⏱️",
                            context: context,
                          ),
                        ],
                      ],
                    ),
                    const SmallHSpace(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Content(
                          text: lastTrackDateFormatted,
                          context: context,
                        ),
                        if (lastTrackDurationFormatted != null) ...[
                          const SmallVSpace(),
                          Content(
                            text: lastTrackDurationFormatted,
                            context: context,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const VSpace(),
                IconTextButton(
                  iconColor: Colors.white,
                  icon: Icons.arrow_right_alt_rounded,
                  label: "Erneut fahren",
                  boxConstraints: const BoxConstraints(minWidth: 170),
                  onPressed: () {
                    HapticFeedback.mediumImpact();

                    List<dynamic> waypoints = List.generate(routeNodes.length, (index) {
                      final routeNode = routeNodes[index];

                      // Add first and last waypoint.
                      if (index == 0 || index == routeNodes.length - 1) {
                        return Waypoint(
                          routeNode.lat,
                          routeNode.lon,
                          address: "Wegpunkt",
                        );
                      }

                      // Only add those where the direction of the route changes significantly.
                      // This is to avoid too many waypoints.
                      const directionThreshold = 50.0;
                      if (index > 1) {
                        final previousRouteNode = routeNodes[index - 1];
                        final previousPreviousRouteNode = routeNodes[index - 2];
                        final direction = vincenty.bearing(
                          LatLng(previousRouteNode.lat, previousRouteNode.lon),
                          LatLng(routeNode.lat, routeNode.lon),
                        );
                        final previousDirection = vincenty.bearing(
                          LatLng(previousPreviousRouteNode.lat, previousPreviousRouteNode.lon),
                          LatLng(previousRouteNode.lat, previousRouteNode.lon),
                        );
                        final directionDifference = (direction - previousDirection).abs();
                        if (directionDifference > directionThreshold) {
                          return Waypoint(
                            routeNode.lat,
                            routeNode.lon,
                            address: "Wegpunkt",
                          );
                        }
                      }

                      // Skip those where the distance to the previous waypoint is too small.
                      const distanceThreshold = 500.0;
                      if (index > 0) {
                        final previousRouteNode = routeNodes[index - 1];
                        final distance = vincenty.distance(
                          LatLng(previousRouteNode.lat, previousRouteNode.lon),
                          LatLng(routeNode.lat, routeNode.lon),
                        );
                        if (distance > distanceThreshold) {
                          return Waypoint(
                            routeNode.lat,
                            routeNode.lon,
                            address: "Wegpunkt",
                          );
                        }
                      }
                      return null;
                    });

                    // Remove null values from the list.
                    List<Waypoint> filteredWaypoints = [];
                    for (var waypoint in waypoints) {
                      if (waypoint != null) {
                        filteredWaypoints.add(waypoint);
                      }
                    }

                    getIt<Routing>().selectWaypoints(filteredWaypoints);

                    // Pushes the routing view.
                    // Also handles the reset of services if the user navigates back to the home view after the routing view instead of starting a ride.
                    // If the routing view is popped after the user navigates to the ride view do not reset the services, because they are being used in the ride view.
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutingView())).then(
                        (comingNotFromRoutingView) {
                          if (comingNotFromRoutingView == null) {
                            getIt<Routing>().reset();
                            getIt<Discomforts>().reset();
                            getIt<PredictionSGStatus>().reset();
                          }
                        },
                      );
                    }
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
