import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/map/geo.dart';
import 'package:priobike/common/map/layers.dart';
import 'package:priobike/common/map/markers.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/crossing.dart';
import 'package:priobike/routing/models/discomfort.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/messages/sg.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';

class RoutingMapView extends StatefulWidget {
  /// The stream that receives notifications when the bottom sheet is dragged.
  final Stream<DraggableScrollableNotification>? sheetMovement;

  const RoutingMapView({required this.sheetMovement, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> {
  static const viewId = "routing.views.map";

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated discomfort service, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated location service, which is injected by the provider.
  late Positioning positioning;

  /// The associated layers service, which is injected by the provider.
  late Layers layers;

  /// A lock for concurrent updates to map layers.
  var isUpdatingLayers = false;

  /// A map controller for the map.
  MapboxMapController? mapController;

  /// The geo feature loader for the map.
  GeoFeatureLoader? geoFeatureLoader;

  /// The stream that receives notifications when the bottom sheet is dragged.
  StreamSubscription<DraggableScrollableNotification>? sheetMovementSubscription;

  /// The default map insets.
  final defaultMapInsets = const EdgeInsets.only(
    top: 108,
    bottom: 80,
    left: 8,
    right: 8,
  );

  @override
  void initState() {
    super.initState();
    sheetMovementSubscription = widget.sheetMovement?.listen(onScrollBottomSheet);

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      await layers.loadPreferences();
    });
  }

  @override
  void didChangeDependencies() {
    routing = Provider.of<Routing>(context);
    discomforts = Provider.of<Discomforts>(context);
    if (routing.needsLayout[viewId] != false || discomforts.needsLayout[viewId] != false) {
      print("RoutingMapView: needs routing/discomforts");
      updateMapLayers();
      routing.needsLayout[viewId] = false;
      discomforts.needsLayout[viewId] = false;
    }

    positioning = Provider.of<Positioning>(context);
    if (positioning.needsLayout[viewId] != false) {
      print("RoutingMapView: needs positioning");
      onPositioningUpdate();
      positioning.needsLayout[viewId] = false;
    }

    layers = Provider.of<Layers>(context);
    if (layers.needsLayout[viewId] != false) {
      print("RoutingMapView: needs layers");
      loadGeoFeatures();
      layers.needsLayout[viewId] = false;
    }

    super.didChangeDependencies();
  }

  /// A callback that gets fired when the bottom sheet of the parent view is dragged.
  Future<void> onScrollBottomSheet(DraggableScrollableNotification n) async {
    final frame = MediaQuery.of(context);
    final maxBottomInset = frame.size.height - frame.padding.top - 300;
    final newBottomInset = min(maxBottomInset, n.extent * frame.size.height);
    mapController?.updateContentInsets(
        EdgeInsets.fromLTRB(defaultMapInsets.left, defaultMapInsets.top, defaultMapInsets.left, newBottomInset), false);
  }

  Future<void> updateMapLayers() async {
    if (isUpdatingLayers) return;
    isUpdatingLayers = true;
    await loadAllRouteLayers();
    await loadSelectedRouteLayer();
    await loadWaypointMarkers();
    await loadDiscomforts();
    await loadTrafficLightMarkers();
    await loadOfflineCrossingMarkers();
    await moveMap();
    isUpdatingLayers = false;
  }

  Future<void> onPositioningUpdate() async {
    await showUserLocation();
  }

  /// Load the route layerouting.
  Future<void> loadAllRouteLayers() async {
    // If we have no map controller, we cannot load the layerouting.
    if (mapController == null || !mounted) return;
    final features = List.empty(growable: true);
    for (final entry in routing.allRoutes?.asMap().entries.toList() ?? []) {
      final geometry = {
        "type": "LineString",
        "coordinates": entry.value.route.map((e) => [e.lon, e.lat]).toList(),
      };
      features.add({
        "id": "route-${entry.key}", // Required for click listener.
        "type": "Feature",
        "geometry": geometry,
      });
    }
    await mapController?.removeLayer("routes-layer");
    await mapController?.removeLayer("routes-clicklayer");
    await mapController?.removeSource("routes");
    await mapController?.addGeoJsonSource(
      "routes",
      {"type": "FeatureCollection", "features": features},
    );
    await mapController?.addLayer(
      "routes",
      "routes-layer",
      const LineLayerProperties(
        lineWidth: 9.0,
        lineColor: "#C6C6C6",
        lineJoin: "round",
      ),
      enableInteraction: false,
      belowLayerId: "discomforts-layer",
    );
    // Make it easier to click on the route.
    await mapController?.addLayer(
      "routes",
      "routes-clicklayer",
      const LineLayerProperties(
        lineWidth: 25.0,
        lineColor: "#000000",
        lineJoin: "round",
        lineOpacity: 0.001, // Not 0 to make the click listener work.
      ),
      enableInteraction: true,
      belowLayerId: "discomforts-layer",
    );
  }

  /// Load the current route layer.
  Future<void> loadSelectedRouteLayer() async {
    // If we have no map controller, we cannot load the route layer.
    if (mapController == null || !mounted) return;
    final geometry = {
      "type": "LineString",
      "coordinates": routing.selectedRoute?.route.map((e) => [e.lon, e.lat]).toList() ?? [],
    };
    final feature = {
      "type": "Feature",
      "properties": {},
      "geometry": geometry,
    };
    await mapController?.removeLayer("route-background-layer");
    await mapController?.removeLayer("route-layer");
    await mapController?.removeSource("route");
    await mapController?.addGeoJsonSource(
      "route",
      {
        "type": "FeatureCollection",
        "features": [feature]
      },
    );
    await mapController?.addLayer(
      "route",
      "route-background-layer",
      const LineLayerProperties(
        lineWidth: 9.0,
        lineColor: "#C6C6C6",
        lineJoin: "round",
      ),
      enableInteraction: false,
      belowLayerId: "discomforts-layer",
    );
    await mapController?.addLayer(
      "route",
      "route-layer",
      const LineLayerProperties(
        lineWidth: 7.0,
        lineColor: "#0073ff",
        lineJoin: "round",
      ),
      enableInteraction: false,
      belowLayerId: "discomforts-layer",
    );
  }

  /// Load the discomforts.
  Future<void> loadDiscomforts() async {
    // If we have no map controller, we cannot load the layerouting.
    if (mapController == null || !mounted) return;
    final features = List.empty(growable: true);
    final iconSize = MediaQuery.of(context).devicePixelRatio / 4;
    for (MapEntry<int, DiscomfortSegment> e in discomforts.foundDiscomforts?.asMap().entries ?? []) {
      if (e.value.coordinates.isEmpty) continue;
      // A section of the route.
      final geometry = {
        "type": "LineString",
        "coordinates": e.value.coordinates.map((e) => [e.longitude, e.latitude]).toList(),
      };
      features.add({
        "id": "discomfort-${e.key}", // Required for click listener.
        "type": "Feature",
        "properties": {
          "number": e.key + 1,
        },
        "geometry": geometry,
      });
    }
    await mapController?.removeLayer("discomforts-layer");
    await mapController?.removeLayer("discomforts-clicklayer");
    await mapController?.removeLayer("discomforts-markers");
    await mapController?.removeSource("discomforts");
    await mapController?.addGeoJsonSource(
      "discomforts",
      {"type": "FeatureCollection", "features": features},
    );
    await mapController?.addLayer(
      "discomforts",
      "discomforts-layer",
      const LineLayerProperties(
        lineWidth: 7.0,
        lineColor: "#e63328",
        lineCap: "round",
        lineJoin: "round",
      ),
      enableInteraction: false,
      belowLayerId: "discomforts-clicklayer",
    );
    await mapController?.addLayer(
      "discomforts",
      "discomforts-clicklayer",
      const LineLayerProperties(
        lineWidth: 30.0,
        lineColor: "#000000",
        lineCap: "round",
        lineJoin: "round",
        lineOpacity: 0.001, // Not 0 to make the click listener work.
      ),
      enableInteraction: true,
      belowLayerId: "discomforts-markers",
    );
    await mapController?.addLayer(
      "discomforts",
      "discomforts-markers",
      SymbolLayerProperties(
        iconImage: "alert",
        iconSize: iconSize,
        textField: ["get", "number"],
        textSize: 12,
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
      enableInteraction: true,
    );
  }

  /// Load the current traffic lights.
  Future<void> loadTrafficLightMarkers() async {
    // If we have no map controller, we cannot load the traffic lights.
    if (mapController == null || !mounted) return;
    // Check the prediction status of the traffic light.
    final statusProvider = Provider.of<PredictionSGStatus>(context, listen: false);
    final features = List.empty(growable: true);
    for (Sg sg in routing.selectedRoute?.signalGroups ?? []) {
      final status = statusProvider.cache[sg.id];
      final isOffline = status == null ||
          status.predictionState == SGPredictionState.offline ||
          status.predictionState == SGPredictionState.bad;
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [sg.position.lon, sg.position.lat],
        },
        "properties": {
          "id": sg.id,
          "isOffline": isOffline,
        },
      });
    }
    await mapController?.removeLayer("traffic-lights-icons");
    await mapController?.removeSource("traffic-lights");
    await mapController?.addGeoJsonSource(
      "traffic-lights",
      {"type": "FeatureCollection", "features": features},
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await mapController?.addLayer(
      "traffic-lights",
      "traffic-lights-icons",
      SymbolLayerProperties(
        iconImage: [
          "case",
          ["get", "isOffline"],
          isDark ? "trafficlightofflinedark" : "trafficlightofflinelight",
          isDark ? "trafficlightonlinedark" : "trafficlightonlinelight",
        ],
        iconSize: MediaQuery.of(context).devicePixelRatio / 2.5,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: LayerTools.showAfter(zoom: 13),
        symbolZOrder: 3,
        textField:
            Provider.of<Settings>(context, listen: false).sgLabelsMode == SGLabelsMode.enabled ? ["get", "id"] : null,
      ),
      enableInteraction: false,
    );
  }

  /// Load the current crossings.
  Future<void> loadOfflineCrossingMarkers() async {
    // If we have no map controller, we cannot load the crossings.
    if (mapController == null || !mounted) return;
    final features = List.empty(growable: true);
    for (Crossing crossing in routing.selectedRoute?.crossings ?? []) {
      if (crossing.connected) continue;
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [crossing.position.lon, crossing.position.lat],
        },
        "properties": {
          "name": crossing.name,
        },
      });
    }
    await mapController?.removeLayer("offline-crossings-icons");
    await mapController?.removeSource("offline-crossings");
    await mapController?.addGeoJsonSource(
      "offline-crossings",
      {"type": "FeatureCollection", "features": features},
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await mapController?.addLayer(
      "offline-crossings",
      "offline-crossings-icons",
      SymbolLayerProperties(
        iconImage: isDark ? "trafficlightdisconnecteddark" : "trafficlightdisconnectedlight",
        iconSize: MediaQuery.of(context).devicePixelRatio / 2.5,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: LayerTools.showAfter(zoom: 13),
        symbolZOrder: 3,
        textField:
            Provider.of<Settings>(context, listen: false).sgLabelsMode == SGLabelsMode.enabled ? ["get", "name"] : null,
      ),
      enableInteraction: false,
    );
  }

  /// Load the current waypoint markerouting.
  Future<void> loadWaypointMarkers() async {
    // If we have no map controller, we cannot load the waypoint layer.
    if (mapController == null || !mounted) return;
    final features = List.empty(growable: true);
    final iconSize = MediaQuery.of(context).devicePixelRatio / 4;
    for (MapEntry<int, Waypoint> entry in routing.selectedWaypoints?.asMap().entries ?? []) {
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [entry.value.lon, entry.value.lat],
        },
        "properties": {
          "isFirst": entry.key == 0,
          "isLast": entry.key == routing.selectedWaypoints!.length - 1,
        },
      });
    }
    await mapController?.removeLayer("waypoints-icons");
    await mapController?.removeSource("waypoints");
    await mapController?.addGeoJsonSource(
      "waypoints",
      {"type": "FeatureCollection", "features": features},
    );
    await mapController?.addLayer(
      "waypoints",
      "waypoints-icons",
      SymbolLayerProperties(
        iconImage: [
          "case",
          ["get", "isFirst"],
          "start",
          ["get", "isLast"],
          "destination",
          "waypoint",
        ],
        iconSize: iconSize,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      enableInteraction: false,
    );
  }

  /// Adapt the map controller.
  Future<void> moveMap() async {
    if (mapController == null || !mounted) return;
    if (routing.selectedRoute != null && !mapController!.isCameraMoving) {
      // The delay is necessary, otherwise sometimes the camera won't move.
      await Future.delayed(const Duration(milliseconds: 500));
      await mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(routing.selectedRoute!.paddedBounds),
        duration: const Duration(milliseconds: 1000),
      );
    }
  }

  /// Show the user location on the map.
  Future<void> showUserLocation() async {
    if (mapController == null || !mounted) return;
    if (positioning.lastPosition == null) return;

    await mapController?.updateUserLocation(
      lat: positioning.lastPosition!.latitude,
      lon: positioning.lastPosition!.longitude,
      alt: positioning.lastPosition!.altitude,
      acc: positioning.lastPosition!.accuracy,
      heading: positioning.lastPosition!.heading,
      speed: positioning.lastPosition!.speed,
    );
  }

  /// Load the map layers.
  Future<void> loadGeoFeatures() async {
    if (mapController == null || !mounted) return;

    // Load the map features.
    geoFeatureLoader = GeoFeatureLoader(mapController!);
    await geoFeatureLoader!.removeFeatures();
    await geoFeatureLoader!.initSources();
    await geoFeatureLoader!.loadFeatures(context);
  }

  /// A callback that is called when the user taps a feature.
  Future<void> onFeatureTapped(dynamic id, Point<double> point, LatLng coordinates) async {
    if (id is! String) return;
    if (id.startsWith("route-")) {
      final routeIdx = int.tryParse(id.split("-")[1]);
      if (routeIdx == null) return;
      routing.switchToRoute(context, routeIdx);
    } else if (id.startsWith("discomfort-")) {
      final discomfortIdx = int.tryParse(id.split("-")[1]);
      if (discomfortIdx == null) return;
      discomforts.selectDiscomfort(discomfortIdx);
    }
  }

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(MapboxMapController controller) async {
    mapController = controller;

    // Bind the interaction callbacks.
    controller.onFeatureTapped.add(onFeatureTapped);

    // Dont call any line/symbol/... removal/add operations here.
    // The mapcontroller won't have the necessary line/symbol/...manager.
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(BuildContext context) async {
    if (mapController == null || !mounted) return;

    // Remove all previously existing layers from the map.
    await mapController?.clearFills();
    await mapController?.clearCircles();
    await mapController?.clearLines();
    await mapController?.clearSymbols();

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // Fit the content below the top and the bottom stuff.
    await mapController!.updateContentInsets(defaultMapInsets);

    // Allow overlaps so that important symbols and texts are not hidden.
    await mapController!.setSymbolIconAllowOverlap(true);
    await mapController!.setSymbolIconIgnorePlacement(true);
    await mapController!.setSymbolTextAllowOverlap(true);
    await mapController!.setSymbolTextIgnorePlacement(true);

    // Force adapt the map.
    await updateMapLayers();
    await onPositioningUpdate();
    await loadGeoFeatures();
  }

  /// A callback that is executed when the map was longclicked.
  Future<void> onMapLongClick(BuildContext context, LatLng coord) async {
    final geocoding = Provider.of<Geocoding>(context, listen: false);
    String fallback = "Wegpunkt ${(routing.selectedWaypoints?.length ?? 0) + 1}";
    String address = await geocoding.reverseGeocode(context, coord) ?? fallback;
    await routing.addWaypoint(Waypoint(coord.latitude, coord.longitude, address: address));
    await routing.loadRoutes(context);
  }

  @override
  void dispose() {
    // Unbind the sheet movement listener.
    sheetMovementSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppMap(
      puckImage: Theme.of(context).brightness == Brightness.dark
          ? 'assets/images/position-static-dark.png'
          : 'assets/images/position-static-light.png',
      puckSize: 64,
      onMapCreated: onMapCreated,
      onStyleLoaded: () => onStyleLoaded(context),
      onMapLongClick: (_, coord) => onMapLongClick(context, coord),
    );
  }
}
