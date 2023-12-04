import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
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
import 'package:priobike/routing/models/drag_waypoint.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routing/models/screen_edge.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/map_values.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tutorial/service.dart';

class RoutingMapView extends StatefulWidget {
  /// The stream that receives notifications when the bottom sheet is dragged.
  final Stream<DraggableScrollableNotification>? sheetMovement;

  const RoutingMapView({required this.sheetMovement, super.key});

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> with TickerProviderStateMixin {
  static const viewId = "routing.views.map";

  static const userLocationLayerId = "user-location-puck";

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

  /// The associated tutorial service, which is injected by the provider.
  late Tutorial tutorial;

  /// A map controller for the map.
  MapboxMap? mapController;

  /// The stream that receives notifications when the bottom sheet is dragged.
  StreamSubscription<DraggableScrollableNotification>? sheetMovementSubscription;

  /// Where the user is currently tapping.
  Offset? tapPosition;

  /// Where the user is currently long tapping, used for dragging waypoints.
  Offset? dragPosition;

  bool showAuxiliaryMarking = false;

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
  final routeLabelLock = Lock(milliseconds: 500);

  /// The index of the basemap layers where the first label layer is located (the label layers are top most).
  var firstBaseMapLabelLayerIndex = 0;

  /// A bool indicating whether the Mapbox internal map layers have finished loading.
  var mapLayersFinishedLoading = false;

  /// When the user long presses on a waypoint, this is the waypoint that is being dragged.
  Waypoint? draggedWaypoint;

  /// The index of the dragged waypoint to determine if the waypoint is a destination or a waypoint in the middle.
  int? draggedWaypointIndex;

  /// The type of the dragged waypoint to determine the icon.
  WaypointType? draggedWaypointType;

  /// The current screen edge the user is dragging the waypoint to, if any.
  ScreenEdge currentScreenEdge = ScreenEdge.none;

  /// Hide the icon of a dragged waypoint while loading when adding a new waypoint.
  bool hideDragWaypoint = false;

  /// The index in the list represents the layer order in z axis.
  final List layerOrder = [
    VeloRoutesLayer.layerId,
    TrafficLayer.layerId,
    AllRoutesLayer.layerId,
    AllRoutesLayer.layerIdClick,
    SelectedRouteLayer.layerIdBackground,
    SelectedRouteLayer.layerId,
    DiscomfortsLayer.layerId,
    DiscomfortsLayer.layerIdMarker,
    WaypointsLayer.layerId,
    OfflineCrossingsLayer.layerId,
    TrafficLightsLayer.layerId,
    AccidentHotspotsLayer.layerId,
    ConstructionSitesLayer.layerId,
    GreenWaveLayer.layerId,
    BikeShopLayer.layerId,
    BikeAirStationLayer.layerId,
    ParkingStationsLayer.layerId,
    RentalStationsLayer.layerId,
    userLocationLayerId,
    RouteLabelLayer.layerId,
  ];

  /// Returns the index where the layer should be added in the Mapbox layer stack.
  Future<int> getIndex(String layerId) async {
    final currentLayers = await mapController!.style.getStyleLayers();
    // Place the route label layer on top of all other layers.
    if (layerId == RouteLabelLayer.layerId) {
      return currentLayers.length - 1;
    }
    // Find out how many of our layers are before the layer that should be added.
    var layersBeforeAdded = 0;
    for (final layer in layerOrder) {
      if (currentLayers.firstWhereOrNull((element) => element?.id == layer) != null) {
        layersBeforeAdded++;
      }
      if (layer == layerId) {
        break;
      }
    }
    // Add the layer on top of our layers that are before it and below the label layers.
    return firstBaseMapLabelLayerIndex + layersBeforeAdded;
  }

  /// Updates the centering.
  updateMapFunctions() {
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

  /// Called when the listener callback of the Routing service ChangeNotifier is fired.
  updateRoute() async {
    updateRouteMapLayers();
    fitCameraToRouteBounds();
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
    mapDesigns = getIt<MapDesigns>();
    positioning = getIt<Positioning>();
    routing = getIt<Routing>();
    discomforts = getIt<Discomforts>();
    status = getIt<PredictionSGStatus>();
    mapFunctions = getIt<MapFunctions>();
    mapValues = getIt<MapValues>();
    tutorial = getIt<Tutorial>();
  }

  @override
  void dispose() {
    // Unbind the sheet movement listener.
    sheetMovementSubscription?.cancel();
    animationController.dispose();
    layers.removeListener(loadGeoLayers);
    mapDesigns.removeListener(loadMapDesign);
    positioning.removeListener(displayCurrentUserLocation);
    routing.removeListener(updateRoute);
    discomforts.removeListener(updateDiscomforts);
    status.removeListener(updateSelectedRouteLayer);
    mapFunctions.removeListener(updateMapFunctions);
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
    final frame = MediaQuery.of(context);
    // The delay is necessary, otherwise sometimes the camera won't move.
    await Future.delayed(const Duration(milliseconds: 500));
    final currentCameraOptions = await mapController?.getCameraState();
    if (currentCameraOptions == null) return;

    MbxEdgeInsets padding = MbxEdgeInsets(
      // (AppBackButton height + top padding)
      top: (80 + frame.padding.top),
      // AppBackButton width
      left: 64,
      // (BottomSheet + bottom padding)
      bottom: (140 + frame.padding.bottom),
      right: 0,
    );

    final cameraOptionsForBounds = await mapController?.cameraForCoordinateBounds(
      routing.selectedRoute!.paddedBounds,
      padding,
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

    await mapController?.style.styleLayerExists(userLocationLayerId).then((value) async {
      if (!value) {
        final index = await getIndex(userLocationLayerId);
        if (!mounted) return;
        await mapController!.style.addLayerAt(
            LocationIndicatorLayer(
              id: userLocationLayerId,
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
            LayerPosition(at: index));
        await mapController!.style
            .setStyleTransition(TransitionOptions(duration: 1000, enablePlacementTransitions: false));
      } else {
        await mapController!.style.updateLayer(
          LocationIndicatorLayer(
            id: userLocationLayerId,
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
    if (layers.showAirStations) {
      final index = await getIndex(BikeAirStationLayer.layerId);
      if (!mounted) return;
      await BikeAirStationLayer(isDark).install(mapController!, at: index);
    } else {
      if (!mounted) return;
      await BikeAirStationLayer.remove(mapController!);
    }
    if (layers.showConstructionSites) {
      final index = await getIndex(ConstructionSitesLayer.layerId);
      if (!mounted) return;
      await ConstructionSitesLayer(isDark).install(mapController!, at: index);
    } else {
      if (!mounted) return;
      await ConstructionSitesLayer.remove(mapController!);
    }
    if (layers.showParkingStations) {
      final index = await getIndex(ParkingStationsLayer.layerId);
      if (!mounted) return;
      await ParkingStationsLayer(isDark).install(mapController!, at: index);
    } else {
      if (!mounted) return;
      await ParkingStationsLayer.remove(mapController!);
    }
    if (layers.showRentalStations) {
      final index = await getIndex(RentalStationsLayer.layerId);
      if (!mounted) return;
      await RentalStationsLayer(isDark).install(mapController!, at: index);
    } else {
      if (!mounted) return;
      await RentalStationsLayer.remove(mapController!);
    }
    if (layers.showRepairStations) {
      final index = await getIndex(BikeShopLayer.layerId);
      if (!mounted) return;
      await BikeShopLayer(isDark).install(mapController!, at: index);
    } else {
      if (!mounted) return;
      await BikeShopLayer.remove(mapController!);
    }
    if (layers.showAccidentHotspots) {
      final index = await getIndex(AccidentHotspotsLayer.layerId);
      if (!mounted) return;
      await AccidentHotspotsLayer(isDark).install(mapController!, at: index);
    } else {
      if (!mounted) return;
      await AccidentHotspotsLayer.remove(mapController!);
    }
    if (layers.showGreenWaveLayer) {
      final index = await getIndex(GreenWaveLayer.layerId);
      if (!mounted) return;
      await GreenWaveLayer(isDark).install(mapController!, at: index);
    } else {
      if (!mounted) return;
      await GreenWaveLayer.remove(mapController!);
    }
    if (layers.showTrafficLayer) {
      final index = await getIndex(TrafficLayer.layerId);
      if (!mounted) return;
      await TrafficLayer(isDark).install(mapController!, at: index);
    } else {
      if (!mounted) return;
      await TrafficLayer.remove(mapController!);
    }
    if (layers.showVeloRoutesLayer) {
      final index = await getIndex(VeloRoutesLayer.layerId);
      if (!mounted) return;
      await VeloRoutesLayer(isDark).install(mapController!, at: index);
    } else {
      if (!mounted) return;
      await VeloRoutesLayer.remove(mapController!);
    }

    /*
    * Only applies to Android. Due to a data leak on Android-Flutter (https://github.com/flutter/flutter/issues/118384),
    * we use a TextureView instead of the SurfaceView (for the Mapbox map), which causes the problem that
    * the layer changes sometimes only become active after interacting with the map
    * again. To solve this, the following workaround was introduced.
    * More Details: https://trello.com/c/xIeOXzZU
    * */
    if (Platform.isAndroid) {
      final cameraState = await mapController!.getCameraState();
      mapController!.flyTo(
        CameraOptions(
          zoom: cameraState.zoom + 0.001,
        ),
        MapAnimationOptions(duration: 100),
      );
    }
  }

  /// Update discomforts layer.
  updateDiscomforts() async {
    if (mapController == null) return;
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await DiscomfortsLayer(isDark).update(mapController!);
  }

  /// Update selected route layer.
  updateSelectedRouteLayer() async {
    if (mapController == null) return;
    if (!mounted) return;
    await SelectedRouteLayer().update(mapController!);
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
    await updateDiscomforts();
    await updateSelectedRouteLayer();
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
    var index = await getIndex(OfflineCrossingsLayer.layerId);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark).install(
      mapController!,
      iconSize: ppi / 10,
      at: index,
    );
    index = await getIndex(TrafficLightsLayer.layerId);
    if (!mounted) return;
    await TrafficLightsLayer(isDark).install(
      mapController!,
      iconSize: ppi / 10,
      at: index,
    );
    index = await getIndex(WaypointsLayer.layerId);
    if (!mounted) return;
    await WaypointsLayer().install(
      mapController!,
      iconSize: 0.2,
      at: index,
    );
    index = await getIndex(DiscomfortsLayer.layerId);
    if (!mounted) return;
    await DiscomfortsLayer(isDark).install(
      mapController!,
      iconSize: ppi / 14,
      at: index,
    );
    index = await getIndex(SelectedRouteLayer.layerId);
    if (!mounted) return;
    await SelectedRouteLayer().install(
      mapController!,
      at: index,
    );
    index = await getIndex(AllRoutesLayer.layerId);
    if (!mounted) return;
    await AllRoutesLayer().install(
      mapController!,
      at: index,
    );
    index = await getIndex(RouteLabelLayer.layerId);
    if (!mounted) return;
    routeLabelCoordinates = await getCoordinatesForRouteLabels();
    await RouteLabelLayer(routeLabelCoordinates).install(
      mapController!,
      at: index,
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
            // Needs to be set since this offset is set in fitCameraToRouteBounds().
            left: 64,
            top: defaultMapInsets.top,
            right: defaultMapInsets.left),
      ),
    );
    final attributionMargins =
        math.Point(10, 116 / frame.size.height + (frame.padding.bottom / frame.size.height) + 170);
    mapController!.attribution.updateSettings(AttributionSettings(
        marginBottom: attributionMargins.y.toDouble(),
        marginRight: attributionMargins.x.toDouble(),
        position: OrnamentPosition.BOTTOM_RIGHT));
    mapController!.logo.updateSettings(LogoSettings(
        marginBottom: attributionMargins.y.toDouble(),
        marginLeft: attributionMargins.x.toDouble(),
        position: OrnamentPosition.BOTTOM_LEFT));
  }

  /// Used to get the index of the first label layer in the layer stack. This is used to place our layers below the
  /// label layers such that they are still readable.
  getFirstLabelLayer() async {
    if (mapController == null) return;

    final layers = await mapController!.style.getStyleLayers();
    final firstLabel = layers.firstWhereOrNull((layer) {
      final layerId = layer?.id ?? "";
      return layerId.contains("-label");
    });
    // If there are no label layers in the style we want to start adding on top of the last layer.
    if (firstLabel == null) {
      firstBaseMapLabelLayerIndex = (layers.isNotEmpty) ? layers.length - 1 : 0;
      return;
    }
    final firstLabelIndex = layers.indexOf(firstLabel);
    // If there are no label layers in the style we want to start adding on top of the last layer.
    if (firstLabelIndex == -1) {
      firstBaseMapLabelLayerIndex = (layers.isNotEmpty) ? layers.length - 1 : 0;
      return;
    }

    firstBaseMapLabelLayerIndex = firstLabelIndex;
  }

  /// A callback which is executed when the map was created.
  onMapCreated(MapboxMap controller) async {
    mapController = controller;
  }

  /// A callback which is executed when the map style was (re-)loaded.
  onStyleLoaded(StyleLoadedEventData styleLoadedEventData) async {
    if (mapController == null || !mounted) return;

    setState(() {
      mapLayersFinishedLoading = false;
    });

    // Wait until the Mapbox internal layers are loaded.
    // (The layers of the map need some time to load, even after the onStyleLoaded callback.)
    // (If we proceed without waiting, the app might crash,
    // because we are trying to add layers on top of layers that are not there yet.)
    // 40 is an kind of arbitrary number that is high enough to indicate that a lot of the layers are loaded but not too high
    // such that in the future if we reduce the layers on our Mapbox style (in Mapbox studio) we never reach this number.
    while (true) {
      final layers = await mapController!.style.getStyleLayers();
      if (layers.length > 40) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    setState(() {
      mapLayersFinishedLoading = true;
    });

    layers.addListener(loadGeoLayers);
    mapDesigns.addListener(loadMapDesign);
    positioning.addListener(displayCurrentUserLocation);
    routing.addListener(updateRoute);
    discomforts.addListener(updateDiscomforts);
    status.addListener(updateSelectedRouteLayer);
    mapFunctions.addListener(updateMapFunctions);

    await getFirstLabelLayer();

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // Fit the content below the top and the bottom stuff.
    fitAttributionPosition();

    await displayCurrentUserLocation();
    await loadGeoLayers();

    // Load the boundary layer.
    await BoundaryLayer(isDark).install(mapController!);

    await fitCameraToRouteBounds();
    await loadRouteMapLayers();
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
        layerIds: [AllRoutesLayer.layerIdClick, RouteLabelLayer.layerId],
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
    final point = ScreenCoordinate(x: x, y: y);
    await addWaypoint(point);
  }

  /// Check if user tapped on an existing waypoint and return the waypoint if found.
  Future<Waypoint?> _checkIfWaypointIsAtTappedPosition({required double x, required double y}) async {
    if (mapController == null) return null;
    if (routing.selectedWaypoints == null) return null;

    final tapPosition = ScreenCoordinate(x: x, y: y);

    Waypoint? foundWaypoint;
    double? foundWaypointDistance;

    for (Waypoint waypoint in routing.selectedWaypoints!) {
      final ScreenCoordinate coordsOnScreenWaypoint = await mapController!.pixelForCoordinate({
        "coordinates": [waypoint.lon, waypoint.lat]
      });
      final distance = math.sqrt(math.pow(coordsOnScreenWaypoint.x - tapPosition.x, 2) +
          math.pow(coordsOnScreenWaypoint.y - tapPosition.y, 2));

      if (distance < 50) {
        // get closest waypoint if there are multiple waypoints at the same position
        if (foundWaypointDistance == null || distance < foundWaypointDistance) {
          foundWaypoint = waypoint;
          foundWaypointDistance = distance;
        }
      }
    }
    return foundWaypoint;
  }

  /// Add a waypoint at the tapped position.
  Future<void> addWaypoint(ScreenCoordinate point) async {
    final coord = await mapController!.coordinateForPixel(point);
    final geocoding = getIt<Geocoding>();
    final fallback = "Wegpunkt ${(routing.selectedWaypoints?.length ?? 0) + 1}";
    final pointCoord = Point.fromJson(Map<String, dynamic>.from(coord));
    final longitude = pointCoord.coordinates.lng.toDouble();
    final latitude = pointCoord.coordinates.lat.toDouble();
    final coordLatLng = LatLng(latitude, longitude);

    final pointIsInBoundary = getIt<Boundary>().checkIfPointIsInBoundary(longitude, latitude);
    if (!pointIsInBoundary) {
      if (!mounted) return;
      final backend = getIt<Settings>().backend;
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black.withOpacity(0.4),
        pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
          return DialogLayout(
            title: 'Wegpunkt außerhalb des Stadtgebiets',
            text:
                'Das Routing wird aktuell nur innerhalb von ${backend.region} unterstützt. \nBitte passe Deinen Wegpunkt an.',
            icon: Icons.info_rounded,
            iconColor: Theme.of(context).colorScheme.primary,
            actions: [
              BigButton(
                iconColor: Colors.white,
                icon: Icons.check_rounded,
                label: "Ok",
                onPressed: () => Navigator.of(context).pop(),
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
              )
            ],
          );
        },
      );
      // If the user is dragging a waypoint outside of the city boundary, restore the original waypoint and return
      // otherwise the user is trying to add a new waypoint and we can just return
      if (draggedWaypoint != null) {
        await routing.addWaypoint(draggedWaypoint!, draggedWaypointIndex);
        await getIt<Geosearch>().addToSearchHistory(draggedWaypoint!);
        await routing.loadRoutes();
      }
      return;
    }

    String address = await geocoding.reverseGeocode(coordLatLng) ?? fallback;

    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) {
      await routing.addWaypoint(Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude));
    }
    tutorial.complete("priobike.tutorial.draw-waypoints");
    final waypoint = Waypoint(latitude, longitude, address: address);
    // if the draggedWaypoint isn't null, the user is dragging a waypoint
    // and the waypoint must be reinserted at the same index as before the dragging
    // otherwise the user is adding a waypoint by tapping on the map
    // and the waypoint must be appended to end of list
    int index;
    if (draggedWaypoint != null && draggedWaypointIndex != null) {
      index = draggedWaypointIndex!;
    } else {
      index = routing.selectedWaypoints!.length;
    }
    await routing.addWaypoint(waypoint, index);
    await getIt<Geosearch>().addToSearchHistory(waypoint);
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

    routeLabelLock.run(() {
      updateRouteLabels();
    });
  }

  /// When the user drags a waypoint.
  void dragWaypoint({required double x, required double y}) {
    if (draggedWaypoint == null || mapController == null) return;

    // check if the user dragged the waypoint to the edge of the screen
    final ScreenEdge screenEdge = getDragScreenEdge(x: x, y: y, context: context);

    if (screenEdge != ScreenEdge.none) {
      if (screenEdge != currentScreenEdge) {
        currentScreenEdge = screenEdge;
        animateCameraScreenEdge(screenEdge);
      }
    } else {
      currentScreenEdge = ScreenEdge.none;
    }
  }

  /// Animates the map camera when the user drags a waypoint to the edge of the screen.
  Future<void> animateCameraScreenEdge(ScreenEdge screenEdge) async {
    if (draggedWaypoint == null || mapController == null) return;

    // determine how to move the map
    final cameraMovement = moveCameraWhenDraggingToScreenEdge(screenEdge: screenEdge);

    // get the current coordinates of the center of the map
    final CameraState cameraState = await mapController!.getCameraState();
    final coords = cameraState.center["coordinates"]! as List;
    final double x = coords[0];
    final double y = coords[1];

    // The zoom is usually between 12 and 16, while 16 is more zoomed in.
    // We need to speed up the movement while zoomed out otherwise the movement is too slow.
    final zoom = cameraState.zoom;
    double zoomSpeedup = 16 - zoom;

    // No negative zoom speedup otherwise the map would move in the opposite direction.
    // And don't set to 0 otherwise the map would not move at all.
    if (zoomSpeedup <= 0.3) zoomSpeedup = 0.3;

    await mapController?.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            x + (cameraMovement['x'] ?? 0) * zoomSpeedup,
            y + (cameraMovement['y'] ?? 0) * zoomSpeedup,
          ),
        ).toJson(),
      ),
      MapAnimationOptions(duration: 0),
    );

    // Add a small delay to throttle the camera movement.
    await Future.delayed(const Duration(milliseconds: 10));

    // if the user drags a waypoint to the edge of the screen recursively call this function to move the map
    // it is implemented this way, because "onLongPressMoveUpdate" in the Gesture Detector below
    // gets only called when the user moves the finger but we want to keep moving the map
    // when the user keeps a waypoint at the edge of the screen without moving the finger
    if (currentScreenEdge != ScreenEdge.none && currentScreenEdge == screenEdge) animateCameraScreenEdge(screenEdge);
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

      // Get the seconds to cover the route.
      final seconds = route.path.time / 1000;
      // Get the full hours needed to cover the route.
      final hours = seconds ~/ 3600;
      // Get the remaining minutes.
      final minutes = (seconds - hours * 3600) ~/ 60;

      // Because it is very difficult to display the time in hours and minutes in the label when selecting a route,
      // the time is calculated in minutes here.
      final totalTimeInMinutes = hours * 60 + minutes;

      if (chosenCoordinate != null) {
        chosenCoordinates.add({
          "coordinate": chosenCoordinate,
          "time": totalTimeInMinutes,
          "feature": {
            "id": "routeLabel-${route.id}", // Required for click listener.
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [chosenCoordinate.lon, chosenCoordinate.lat],
            },
            "properties": {
              "isPrimary": routing.selectedRoute!.id == route.id,
              "text": "$totalTimeInMinutes min",
            },
          }
        });
      }
    }
    return chosenCoordinates;
  }

  /// Move the waypoint after finish dragging
  Future<void> moveDraggedWaypoint(BuildContext context, double dx, double dy) async {
    if (routing.selectedWaypoints == null || draggedWaypoint == null) return;

    draggedWaypointIndex = routing.getIndexOfWaypoint(draggedWaypoint!);

    // remove old waypoint from before dragging from routing and search history
    routing.selectedWaypoints!.remove(draggedWaypoint!);
    getIt<Geosearch>().removeItemFromSearchHistory(draggedWaypoint!);

    final point = ScreenCoordinate(x: dx, y: dy);

    // hide the dragged waypoint icon while loading when adding the new waypoint
    hideDragWaypoint = true;

    // add new waypoint at the new position
    await addWaypoint(point);
  }

  /// Reset variables for dragging
  void _resetDragging() {
    dragPosition = null;
    draggedWaypoint = null;
    draggedWaypointIndex = null;
    draggedWaypointType = null;
    hideDragWaypoint = false;
    currentScreenEdge = ScreenEdge.none;
  }

  @override
  Widget build(BuildContext context) {
    isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Show the map.
        GestureDetector(
          onLongPressDown: (details) async {
            // check if user long pressed on map or waypoint
            // if on map, create new waypoint
            // if on waypoint, start dragging waypoint
            draggedWaypoint =
                await _checkIfWaypointIsAtTappedPosition(x: details.localPosition.dx, y: details.localPosition.dy);
            if (draggedWaypoint == null) {
              _resetDragging();
              tapPosition = details.localPosition;
              animationController.forward();
            } else {
              if (routing.selectedWaypoints == null || !routing.selectedWaypoints!.contains(draggedWaypoint)) return;
              dragPosition = details.localPosition;
              draggedWaypointType = getWaypointType(routing.selectedWaypoints!, draggedWaypoint!);
              showAuxiliaryMarking = true;
            }
          },
          onLongPressCancel: () {
            animationController.reverse();
            _resetDragging();
          },
          onLongPressMoveUpdate: (details) async {
            // if user pressed on map, reverse pin animation
            // if user pressed on waypoint, drag waypoint
            if (draggedWaypoint == null) {
              animationController.reverse();
              return;
            }

            // set new icon position under the finger while dragging
            setState(() {
              dragPosition = details.localPosition;
            });

            dragWaypoint(
              x: details.localPosition.dx,
              y: details.localPosition.dy,
            );
          },
          onLongPressEnd: (details) async {
            if (draggedWaypoint != null) {
              showAuxiliaryMarking = false;
              currentScreenEdge = ScreenEdge.none;
              double cancelButtonX = MediaQuery.of(context).size.width / 2 - 24;
              double cancelButtonY = MediaQuery.of(context).size.height / 1.5;

              // the icon x and y position of the icon starts in the top left corner
              // therefore we need to add half the icon size to the x and y position to get the center of the icon
              const iconSize = 50 / 2;
              cancelButtonX += iconSize;
              cancelButtonY += iconSize;

              final x = details.localPosition.dx;
              final y = details.localPosition.dy;

              // check if the user dragged to the cancel button
              // if yes, just refresh to remove the cancel button
              // if no, move the waypoint to the new position
              if (x > cancelButtonX - iconSize &&
                  x < cancelButtonX + iconSize &&
                  y > cancelButtonY - iconSize &&
                  y < cancelButtonY + iconSize) {
                setState(() {});
              } else {
                await moveDraggedWaypoint(context, details.localPosition.dx, details.localPosition.dy);
              }
            } else {
              animationController.reverse();

              // if the user pressed on the map, add a waypoint
              await onMapLongClick(context, details.localPosition.dx, details.localPosition.dy);
            }
            _resetDragging();
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
        // for dragging waypoints
        if (dragPosition != null && draggedWaypointType != null && !hideDragWaypoint)
          Stack(
            children: [
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 24,
                top: MediaQuery.of(context).size.height / 1.5,
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      color: Theme.of(context).colorScheme.primary,
                      iconSize: 50,
                      // do nothing here and handle the cancel button in onLongPressEnd
                      onPressed: () {},
                    ),
                    BoldSmall(
                      context: context,
                      text: "Abbrechen",
                    )
                  ],
                ),
              ),
              AnimatedPositioned(
                // only add a very short duration, otherwise dragging feels sluggish.
                duration: const Duration(milliseconds: 20),
                // Subtract half the icon size to center the icon.
                left: dragPosition!.dx - (24 * 1.5) / 2,
                top: dragPosition!.dy - (24 * 1.5) / 2,
                child: SizedBox(
                  // Image width times scale (1.5).
                  width: 24 * 1.5,
                  height: 24 * 1.5,
                  child: Image.asset(
                    draggedWaypointType!.iconPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              AnimatedPositioned(
                // only add a very short duration, otherwise dragging feels sluggish.
                duration: const Duration(milliseconds: 20),
                // Subtract half the icon size to center the icon.
                left: dragPosition!.dx - (showAuxiliaryMarking ? 75 : 0) / 2,
                top: dragPosition!.dy - (showAuxiliaryMarking ? 75 : 0) / 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                  width: showAuxiliaryMarking ? 75 : 0,
                  height: showAuxiliaryMarking ? 75 : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      width: 3,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                // only add a very short duration, otherwise dragging feels sluggish.
                duration: const Duration(milliseconds: 20),
                // Subtract half the icon size to center the icon.
                left: dragPosition!.dx - (showAuxiliaryMarking ? 100 : 0) / 2,
                top: dragPosition!.dy - (showAuxiliaryMarking ? 100 : 0) / 2,
                child: Container(
                  width: showAuxiliaryMarking ? 100 : 0,
                  height: showAuxiliaryMarking ? 100 : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      width: 2,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                // only add a very short duration, otherwise dragging feels sluggish.
                duration: const Duration(milliseconds: 20),
                // Subtract half the icon size to center the icon.
                left: dragPosition!.dx - (showAuxiliaryMarking ? 125 : 0) / 2,
                top: dragPosition!.dy - (showAuxiliaryMarking ? 125 : 0) / 2,
                child: Container(
                  width: showAuxiliaryMarking ? 125 : 0,
                  height: showAuxiliaryMarking ? 125 : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      width: 1,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),

        if (!mapLayersFinishedLoading)
          Center(
            child: Tile(
              fill: Theme.of(context).colorScheme.background,
              shadowIntensity: 0.2,
              shadow: Colors.black,
              content: const CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
