import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/common/lock.dart';
import 'package:priobike/common/map/layers/boundary_layers.dart';
import 'package:priobike/common/map/layers/poi_layers.dart';
import 'package:priobike/common/map/layers/prio_layers.dart';
import 'package:priobike/common/map/layers/route_layers.dart';
import 'package:priobike/common/map/layers/sg_layers.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/map_values.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/status/services/sg.dart';

class RoutingMapView extends StatefulWidget {
  /// The stream that receives notifications when the bottom sheet is dragged.
  final Stream<DraggableScrollableNotification>? sheetMovement;

  const RoutingMapView({required this.sheetMovement, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> with TickerProviderStateMixin {
  static const viewId = "routing.views.map";

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated discomfort service, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated location service, which is injected by the provider.
  late Positioning positioning;

  /// The associated layers service, which is injected by the provider.
  late Layers layers;

  /// The associated map designs service, which is injected by the provider.
  late MapDesigns mapDesigns;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  /// The associated mapFunctions service, which is injected by the provider.
  late MapFunctions mapFunctions;

  /// The associated mapValues service, which is injected by the provider.
  late MapValues mapValues;

  /// A map controller for the map.
  MapboxMap? mapController;

  /// The stream that receives notifications when the bottom sheet is dragged.
  StreamSubscription<DraggableScrollableNotification>? sheetMovementSubscription;

  /// Where the user is currently tapping.
  Offset? tapPosition;

  /// The animation controller for the on-tap animation.
  late AnimationController animationController;

  /// The animation for the on-tap animation.
  late Animation<double> animation;

  /// The default map insets.
  final defaultMapInsets = const EdgeInsets.only(
    top: 108,
    bottom: 130,
  );

  /// The extra distance between the bottom sheet and the attribution.
  final sheetPadding = 16.0;

  /// The current mode (dark/light).
  bool isDark = false;

  /// The route label coordinates.
  List<Map> routeLabelCoordinates = [];

  /// A lock that avoids rapid relocating of route labels.
  final lock = Lock(milliseconds: 500);

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    updateMap();
    setState(() {});
  }

  /// Updates the map.
  void updateMap() {
    // Check if the selected map layers have changed.
    if (layers.needsLayout[viewId] != false) {
      loadGeoLayers();
      layers.needsLayout[viewId] = false;
    }

    // Check if the selected map design has changed.
    if (mapDesigns.needsLayout[viewId] != false) {
      loadMapDesign();
      mapDesigns.needsLayout[viewId] = false;
    }

    // Check if the position has changed.
    if (positioning.needsLayout[viewId] != false) {
      displayCurrentUserLocation();
      positioning.needsLayout[viewId] = false;
    }

    // Check if route-related stuff has changed.
    if (routing.needsLayout[viewId] != false) {
      updateRouteMapLayers(); // Update all layers to keep them in z-order.
      fitCameraToRouteBounds();
      routing.needsLayout[viewId] = false;
    }

    // Check if the discomforts have changed.
    if (discomforts.needsLayout[viewId] != false) {
      updateRouteMapLayers(); // Update all layers to keep them in z-order.
      discomforts.needsLayout[viewId] = false;
    }

    // Check if the status has changed.
    if (status.needsLayout[viewId] != false) {
      updateRouteMapLayers(); // Update all layers to keep them in z-order.
      status.needsLayout[viewId] = false;
    }

    if (mapFunctions.needsCentering) {
      displayCurrentUserLocation();
      fitCameraToUserPosition();
      mapFunctions.needsCentering = false;
    }

    if (mapFunctions.needsCenteringNorth) {
      centerCameraToNorth();
      mapFunctions.needsCenteringNorth = false;
    }
  }

  @override
  void initState() {
    super.initState();

    // Connect the sheet movement listener to adapt the map insets.
    sheetMovementSubscription = widget.sheetMovement?.listen(
      (n) => fitAttributionPosition(sheetHeightRelative: n.extent),
    );

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      reverseDuration: const Duration(milliseconds: 0),
    )..addListener(() => setState(() {}));
    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubicEmphasized,
    );

    layers = getIt<Layers>();
    layers.addListener(update);
    mapDesigns = getIt<MapDesigns>();
    mapDesigns.addListener(update);
    positioning = getIt<Positioning>();
    positioning.addListener(update);
    routing = getIt<Routing>();
    routing.addListener(update);
    discomforts = getIt<Discomforts>();
    discomforts.addListener(update);
    status = getIt<PredictionSGStatus>();
    status.addListener(update);
    mapFunctions = getIt<MapFunctions>();
    mapFunctions.addListener(update);
    mapValues = getIt<MapValues>();
  }

  @override
  void dispose() {
    // Unbind the sheet movement listener.
    sheetMovementSubscription?.cancel();
    animationController.dispose();
    layers.removeListener(update);
    mapDesigns.removeListener(update);
    positioning.removeListener(update);
    routing.removeListener(update);
    discomforts.removeListener(update);
    status.removeListener(update);
    mapFunctions.removeListener(update);
    super.dispose();
  }

  /// Fit the camera to the current user position.
  fitCameraToUserPosition() async {
    if (mapController == null || !mounted) return;
    // Animation duration.
    const duration = 1000;
    await mapController?.flyTo(
      CameraOptions(
        center: Point(
            coordinates: Position(
          positioning.lastPosition!.longitude,
          positioning.lastPosition!.latitude,
        )).toJson(),
      ),
      MapAnimationOptions(duration: duration),
    );
  }

  /// Center the camera to north.
  centerCameraToNorth() async {
    if (mapController == null || !mounted) return;
    mapController?.flyTo(CameraOptions(bearing: 0), MapAnimationOptions(duration: 1000));
  }

  /// Fit the camera to the current route.
  fitCameraToRouteBounds() async {
    if (mapController == null || !mounted) return;
    if (routing.selectedRoute == null) return;
    // The delay is necessary, otherwise sometimes the camera won't move.
    await Future.delayed(const Duration(milliseconds: 500));
    final currentCameraOptions = await mapController?.getCameraState();
    if (currentCameraOptions == null) return;
    final cameraOptionsForBounds = await mapController?.cameraForCoordinateBounds(
      routing.selectedRoute!.paddedBounds,
      currentCameraOptions.padding,
      currentCameraOptions.bearing,
      currentCameraOptions.pitch,
    );
    if (cameraOptionsForBounds == null) return;
    await mapController?.flyTo(
      cameraOptionsForBounds,
      MapAnimationOptions(duration: 1000),
    );
  }

  /// Show the user location on the map.
  displayCurrentUserLocation() async {
    if (mapController == null || !mounted) return;
    if (positioning.lastPosition == null) return;

    await mapController?.style.styleLayerExists("user-location-puck").then((value) async {
      if (!value) {
        await mapController!.style.addLayer(
          LocationIndicatorLayer(
            id: "user-location-puck",
            bearingImage:
                Theme.of(context).brightness == Brightness.dark ? "positionstaticdark" : "positionstaticlight",
            bearingImageSize: 0.15,
            accuracyRadiusColor: const Color(0x00000000).value,
            accuracyRadiusBorderColor: const Color(0x00000000).value,
            bearing: positioning.lastPosition!.heading,
            location: [
              positioning.lastPosition!.latitude,
              positioning.lastPosition!.longitude,
              positioning.lastPosition!.altitude
            ],
            accuracyRadius: positioning.lastPosition!.accuracy,
          ),
        );
        await mapController!.style
            .setStyleTransition(TransitionOptions(duration: 1000, enablePlacementTransitions: false));
      } else {
        await mapController!.style.updateLayer(
          LocationIndicatorLayer(
            id: "user-location-puck",
            bearing: positioning.lastPosition!.heading,
            location: [
              positioning.lastPosition!.latitude,
              positioning.lastPosition!.longitude,
              positioning.lastPosition!.altitude
            ],
            accuracyRadius: positioning.lastPosition!.accuracy,
          ),
        );
      }
    });
  }

  /// Load the map design.
  loadMapDesign() async {
    if (mapController == null) return;

    await mapController!.style.setStyleURI(
      Theme.of(context).colorScheme.brightness == Brightness.light
          ? mapDesigns.mapDesign.lightStyle
          : mapDesigns.mapDesign.darkStyle,
    );
  }

  /// Load the map layers.
  loadGeoLayers() async {
    if (mapController == null || !mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Load the map features.
    if (layers.showVeloRoutesLayer) {
      if (!mounted) return;
      await VeloRoutesLayer(isDark).install(mapController!);
    } else {
      if (!mounted) return;
      await VeloRoutesLayer.remove(mapController!);
    }
    if (layers.showAirStations) {
      if (!mounted) return;
      await BikeAirStationLayer(isDark).install(mapController!);
    } else {
      if (!mounted) return;
      await BikeAirStationLayer.remove(mapController!);
    }
    if (layers.showConstructionSites) {
      if (!mounted) return;
      await ConstructionSitesLayer(isDark).install(mapController!);
    } else {
      if (!mounted) return;
      await ConstructionSitesLayer.remove(mapController!);
    }
    if (layers.showParkingStations) {
      if (!mounted) return;
      await ParkingStationsLayer(isDark).install(mapController!);
    } else {
      if (!mounted) return;
      await ParkingStationsLayer.remove(mapController!);
    }
    if (layers.showRentalStations) {
      if (!mounted) return;
      await RentalStationsLayer(isDark).install(mapController!);
    } else {
      if (!mounted) return;
      await RentalStationsLayer.remove(mapController!);
    }
    if (layers.showRepairStations) {
      if (!mounted) return;
      await BikeShopLayer(isDark).install(mapController!);
    } else {
      if (!mounted) return;
      await BikeShopLayer.remove(mapController!);
    }
    if (layers.showAccidentHotspots) {
      if (!mounted) return;
      await AccidentHotspotsLayer(isDark).install(mapController!);
    } else {
      if (!mounted) return;
      await AccidentHotspotsLayer.remove(mapController!);
    }
    if (layers.showGreenWaveLayer) {
      if (!mounted) return;
      await GreenWaveLayer(isDark).install(mapController!);
    } else {
      if (!mounted) return;
      await GreenWaveLayer.remove(mapController!);
    }
    if (layers.showTrafficLayer) {
      if (!mounted) return;
      await TrafficLayer(isDark).install(mapController!);
    } else {
      if (!mounted) return;
      await TrafficLayer.remove(mapController!);
    }
  }

  /// Update all route map layers.
  updateRouteMapLayers() async {
    if (mapController == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!mounted) return;
    await OfflineCrossingsLayer(isDark).update(mapController!);
    if (!mounted) return;
    await TrafficLightsLayer(isDark).update(mapController!);
    if (!mounted) return;
    await WaypointsLayer().update(mapController!);
    if (!mounted) return;
    await DiscomfortsLayer().update(mapController!);
    if (!mounted) return;
    await SelectedRouteLayer().update(mapController!);
    if (!mounted) return;
    await AllRoutesLayer().update(mapController!);
    if (!mounted) return;
    routeLabelCoordinates = await getCoordinatesForRouteLabels();
    await (RouteLabelLayer(routeLabelCoordinates)).update(mapController!);
  }

  /// Load all route map layers.
  loadRouteMapLayers() async {
    if (mapController == null) return;
    final ppi = MediaQuery.of(context).devicePixelRatio;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!mounted) return;
    final offlineCrossings = await OfflineCrossingsLayer(isDark).install(
      mapController!,
      iconSize: ppi / 10,
    );
    if (!mounted) return;
    final trafficLights = await TrafficLightsLayer(isDark).install(
      mapController!,
      iconSize: ppi / 10,
      below: offlineCrossings,
    );
    if (!mounted) return;
    final waypoints = await WaypointsLayer().install(
      mapController!,
      iconSize: 0.2,
      below: trafficLights,
    );
    if (!mounted) return;
    final discomforts = await DiscomfortsLayer().install(
      mapController!,
      iconSize: ppi / 8,
      below: waypoints,
    );
    if (!mounted) return;
    final selectedRoute = await SelectedRouteLayer().install(
      mapController!,
      below: discomforts,
    );
    if (!mounted) return;
    await AllRoutesLayer().install(
      mapController!,
      below: selectedRoute,
    );
    if (!mounted) return;
    routeLabelCoordinates = await getCoordinatesForRouteLabels();
    await RouteLabelLayer(routeLabelCoordinates).install(
      mapController!,
    );
  }

  /// A callback that is called when the user taps a feature.
  onFeatureTapped(QueriedFeature queriedFeature) async {
    // Map the id of the layer to the corresponding feature.
    final id = queriedFeature.feature['id'];
    if ((id as String).startsWith("route-")) {
      final routeIdx = int.tryParse(id.split("-")[1]);
      if (routeIdx == null) return;
      routing.switchToRoute(routeIdx);
    } else if (id.startsWith("discomfort-")) {
      final discomfortIdx = int.tryParse(id.split("-")[1]);
      if (discomfortIdx == null) return;
      discomforts.selectDiscomfort(discomfortIdx);
    } else if (id.startsWith("routeLabel-")) {
      final routeLabelIdx = int.tryParse(id.split("-")[1]);
      if (routeLabelIdx == null || (routing.selectedRoute != null && routeLabelIdx == routing.selectedRoute!.id)) {
        return;
      }
      routing.switchToRoute(routeLabelIdx);
    }
  }

  /// Fit the attribution position to the position of the bottom sheet.
  fitAttributionPosition({double? sheetHeightRelative}) {
    if (mapController == null) return;
    final frame = MediaQuery.of(context);
    final sheetHeightAbs = sheetHeightRelative == null
        ? 124 + frame.padding.bottom + sheetPadding // Default value.
        : sheetHeightRelative * frame.size.height + sheetPadding;
    final maxBottomInset = frame.size.height - frame.padding.top - 100;
    double newBottomInset = math.min(maxBottomInset, sheetHeightAbs);
    mapController!.setCamera(
      CameraOptions(
        padding: MbxEdgeInsets(
            bottom: newBottomInset,
            left: defaultMapInsets.left,
            top: defaultMapInsets.top,
            right: defaultMapInsets.left),
      ),
    );
    final ppi = frame.devicePixelRatio;
    final attributionMargins =
        math.Point(20 * ppi, 116 / frame.size.height + (frame.padding.bottom / frame.size.height) + 130 * ppi);
    mapController!.attribution.updateSettings(AttributionSettings(
        marginBottom: attributionMargins.y.toDouble(),
        marginRight: attributionMargins.x.toDouble(),
        position: OrnamentPosition.BOTTOM_RIGHT));
    mapController!.logo.updateSettings(LogoSettings(
        marginBottom: attributionMargins.y.toDouble(),
        marginLeft: attributionMargins.x.toDouble(),
        position: OrnamentPosition.BOTTOM_LEFT));
  }

  /// A callback which is executed when the map was created.
  onMapCreated(MapboxMap controller) async {
    mapController = controller;
  }

  /// A callback which is executed when the map style was (re-)loaded.
  onStyleLoaded(StyleLoadedEventData styleLoadedEventData) async {
    if (mapController == null || !mounted) return;

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    await displayCurrentUserLocation();

    // Fit the content below the top and the bottom stuff.
    fitAttributionPosition();

    // Load the boundary layer.
    await BoundaryLayer(isDark).install(mapController!);

    await fitCameraToRouteBounds();
    await loadRouteMapLayers();
    // The delay is necessary to make sure that the user location indicator is completely loaded
    // (the veloroutes layers needs to be below the user location indicator layer and to provide the id of
    // the user location indicator layer to the velo routes layer it needs to be loaded completely).
    await Future.delayed(const Duration(milliseconds: 500));
    await loadGeoLayers();
  }

  /// A callback which is executed when a tap on the map is registered.
  /// This also resolves if a certain feature is being tapped on. This function
  /// should get screen coordinates. However, at the moment (mapbox_maps_flutter version 0.4.0)
  /// there is a bug causing this to get world coordinates in the form of a ScreenCoordinate.
  Future<void> onMapTap(ScreenCoordinate screenCoordinate) async {
    if (mapController == null || !mounted) return;

    // Because of the bug in the plugin we need to calculate the actual screen coordinates to query
    // for the features in dependence of the tapped on screenCoordinate afterwards. If the bug is
    // fixed in an upcoming version we need to remove this conversion.
    final ScreenCoordinate actualScreenCoordinate = await mapController!.pixelForCoordinate(
      Point(
        coordinates: Position(
          screenCoordinate.y,
          screenCoordinate.x,
        ),
      ).toJson(),
    );

    final List<QueriedFeature?> features = await mapController!.queryRenderedFeatures(
      RenderedQueryGeometry(
        value: json.encode(actualScreenCoordinate.encode()),
        type: Type.SCREEN_COORDINATE,
      ),
      RenderedQueryOptions(
        layerIds: [AllRoutesLayer.layerIdClick, DiscomfortsLayer.layerIdClick, RouteLabelLayer.layerId],
      ),
    );

    if (features.isNotEmpty) {
      // Prioritize discomforts if there are multiple features.
      final discomfortFeature =
          features.firstWhereOrNull((element) => element?.feature['id']?.toString().startsWith("discomfort-") ?? false);
      if (discomfortFeature != null) {
        onFeatureTapped(discomfortFeature);
        return;
      }
      onFeatureTapped(features[0]!);
    }
  }

  /// A callback that is executed when the map was longclicked.
  onMapLongClick(BuildContext context, double x, double y) async {
    if (mapController == null) return;
    // Convert x and y into a lat/lon.
    final ppi = MediaQuery.of(context).devicePixelRatio;
    // On android, we need to multiply by the ppi.
    if (Platform.isAndroid) {
      x *= ppi;
      y *= ppi;
    }
    final point = ScreenCoordinate(x: x, y: y);
    final coord = await mapController!.coordinateForPixel(point);
    final geocoding = getIt<Geocoding>();
    String fallback = "Wegpunkt ${(routing.selectedWaypoints?.length ?? 0) + 1}";
    final pointCoord = Point.fromJson(Map<String, dynamic>.from(coord));
    final longitude = pointCoord.coordinates.lng.toDouble();
    final latitude = pointCoord.coordinates.lat.toDouble();
    final coordLatLng = LatLng(latitude, longitude);
    String address = await geocoding.reverseGeocode(coordLatLng) ?? fallback;
    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) {
      await routing.addWaypoint(Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude));
    }
    await routing.addWaypoint(Waypoint(latitude, longitude, address: address));
    await routing.loadRoutes();
  }

  /// Updates the bearing and centering button.
  Future<void> updateBearingAndCenteringButtons() async {
    if (mapController == null) return;

    final CameraState camera = await mapController!.getCameraState();

    // Set bearing in mapFunctions.
    mapValues.setCameraBearing(camera.bearing);

    // When the camera position changed, set not centered.
    if (camera.center["coordinates"] == null) return;
    // Cast from Object to List [lon, lat].
    final List coordinates = camera.center["coordinates"] as List;
    if (coordinates.length != 2) return;
    if (positioning.lastPosition == null) return;
    // To make the values comparable.
    final double lat = double.parse(coordinates[1].toStringAsFixed(4));
    final double lon = double.parse(coordinates[0].toStringAsFixed(4));
    final double latUser = double.parse(positioning.lastPosition!.latitude.toStringAsFixed(4));
    final double lonUser = double.parse(positioning.lastPosition!.longitude.toStringAsFixed(4));

    if (lat == latUser && lon == lonUser) {
      mapValues.setCameraCentered();
    } else {
      mapValues.setCameraNotCentered();
    }
  }

  /// Updates the route labels.
  Future<void> updateRouteLabels() async {
    if (mapController == null) return;
    if (routing.allRoutes == null) return;
    if (routing.allRoutes!.length != 2) return;
    // Check if the route labels have to be positionally adjusted (if they got moved out of the display).
    bool allInBounds = true;
    for (Map data in routeLabelCoordinates) {
      // Check out of new bounds.
      ScreenCoordinate screenCoordinate = await mapController!.pixelForCoordinate({
        "coordinates": [data["coordinate"].lon, data["coordinate"].lat]
      });
      if (screenCoordinate.x == -1 || screenCoordinate.y == -1) {
        allInBounds = false;
      }
    }

    if (!allInBounds || routeLabelCoordinates.length != 2) {
      routeLabelCoordinates = await getCoordinatesForRouteLabels();
      await (RouteLabelLayer(routeLabelCoordinates)).update(mapController!);
    }
  }

  /// A callback that is executed when the camera movement changes.
  Future<void> onCameraChanged(CameraChangedEventData cameraChangedEventData) async {
    if (mapController == null) return;

    updateBearingAndCenteringButtons();

    lock.run(() {
      updateRouteLabels();
    });
  }

  /// Calculates the coordinates for the route labels.
  Future<List<Map>> getCoordinatesForRouteLabels() async {
    if (mapController == null) return [];

    // Check if routes are loaded.
    if (routing.allRoutes == null) return [];

    if (routing.allRoutes!.length != 2) return [];

    // Chosen coordinates and feature object.
    List<Map> chosenCoordinates = [];
    // Search appropriate Point in Route
    for (r.Route route in routing.allRoutes!) {
      GHCoordinate? chosenCoordinate;
      List<GHCoordinate> uniqueInBounceCoordinates = [];

      // Go through all coordinates.
      for (GHCoordinate coordinate in route.path.points.coordinates) {
        // Check if the coordinate is unique and not on the same line.
        bool unique = true;
        // Loop through all route coordinates.
        for (r.Route routeToBeChecked in routing.allRoutes!) {
          // Would always be not unique without this check.
          if (routeToBeChecked.id != route.id) {
            // Compare coordinate to all coordinates in other route.
            for (GHCoordinate coordinateToBeChecked in routeToBeChecked.path.points.coordinates) {
              if (!unique) {
                break;
              }
              if (coordinateToBeChecked.lon == coordinate.lon && coordinateToBeChecked.lat == coordinate.lat) {
                unique = false;
              }
            }
          }
        }

        if (unique) {
          // Check coordinates in screen bounds.
          ScreenCoordinate screenCoordinate = await mapController!.pixelForCoordinate({
            "coordinates": [coordinate.lon, coordinate.lat]
          });
          if (screenCoordinate.x != -1 || screenCoordinate.y != -1) {
            uniqueInBounceCoordinates.add(coordinate);
          }
        }
      }

      // Determine which coordinate to use.
      if (uniqueInBounceCoordinates.isNotEmpty) {
        // Use the middlemost coordinate.
        chosenCoordinate = uniqueInBounceCoordinates[uniqueInBounceCoordinates.length ~/ 2];
      }

      if (chosenCoordinate != null) {
        chosenCoordinates.add({
          "coordinate": chosenCoordinate,
          "time": ((route.path.time * 0.001) * 0.016).round(),
          "feature": {
            "id": "routeLabel-${route.id}", // Required for click listener.
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [chosenCoordinate.lon, chosenCoordinate.lat],
            },
            "properties": {
              "isPrimary": routing.selectedRoute!.id == route.id,
              "text": "${((route.path.time * 0.001) * 0.016).round()} min"
            },
          }
        });
      }
    }
    return chosenCoordinates;
  }

  @override
  Widget build(BuildContext context) {
    isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // Show the map.
        GestureDetector(
          onLongPressDown: (details) {
            tapPosition = details.localPosition;
            animationController.forward();
          },
          onLongPressCancel: () {
            animationController.reverse();
          },
          onLongPressEnd: (details) {
            animationController.reverse();
            onMapLongClick(context, details.localPosition.dx, details.localPosition.dy);
          },
          behavior: HitTestBehavior.translucent,
          child: AppMap(
            onMapCreated: onMapCreated,
            onStyleLoaded: onStyleLoaded,
            onCameraChanged: onCameraChanged,
            onMapTap: onMapTap,
            logoViewOrnamentPosition: OrnamentPosition.BOTTOM_LEFT,
            attributionButtonOrnamentPosition: OrnamentPosition.BOTTOM_RIGHT,
          ),
        ),

        // Show an animation when the user taps the map.
        if (tapPosition != null)
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  left: tapPosition!.dx - animation.value * 128 - 12,
                  top: tapPosition!.dy - animation.value * 128 - 12,
                  child: Opacity(
                    opacity: math.max(0, math.min(1, (animation.value) * 4)),
                    child: Container(
                      width: animation.value * 256 + 24,
                      height: animation.value * 256 + 24,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(1.0 - animation.value),
                          width: 8.0 - animation.value * 8,
                        ),
                        borderRadius: BorderRadius.circular(128),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: tapPosition!.dx - (1.0 - animation.value) * 64 - 12,
                  top: tapPosition!.dy - (1.0 - animation.value) * 64 - 12,
                  child: Opacity(
                    opacity: math.max(0, (animation.value - 0.5) * 2),
                    child: Container(
                      width: (1.0 - animation.value) * 128 + 24,
                      height: (1.0 - animation.value) * 128 + 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2 * animation.value),
                        borderRadius: BorderRadius.circular(128),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: tapPosition!.dx - 12,
                  top: math.min(12 + tapPosition!.dy - 256 + 256 * math.max(0, (animation.value - 0.25) * 4 / 3),
                          tapPosition!.dy) -
                      12,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Opacity(
                      opacity: math.max(0, (animation.value - 0.5) * 2),
                      child: Image.asset(
                        'assets/images/pin.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: tapPosition!.dx - 12,
                  top: (tapPosition!.dy - 256 + 256 * math.max(0, (animation.value - 0.25) * 4 / 3)) - 12,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Opacity(
                      opacity: math.max(0, (animation.value - 0.5) * 2),
                      child: Image.asset(
                        'assets/images/waypoint.drawio.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
