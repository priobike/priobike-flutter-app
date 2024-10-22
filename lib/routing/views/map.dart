import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/layers/boundary_layers.dart';
import 'package:priobike/common/map/layers/poi_layers.dart';
import 'package:priobike/common/map/layers/prio_layers.dart';
import 'package:priobike/common/map/layers/route_layers.dart';
import 'package:priobike/common/map/layers/sg_layers.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/home/services/poi.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/poi_popup.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/map_values.dart';
import 'package:priobike/routing/services/poi.dart';
import 'package:priobike/routing/services/route_labels.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/details/poi_popup.dart';
import 'package:priobike/routing/views/details/route_label.dart';
import 'package:priobike/routing/views/widgets/target_marker_icon.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tutorial/service.dart';

/// The fixed icon size of the cancel button.
const double cancelButtonIconSize = 50;

/// The value used to calculate the relative space after which the poi pop ups should be fade in or out.
const double poiScreenMargin = 0.1;

class RoutingMapView extends StatefulWidget {
  /// The associated mapValues service, which is injected by the provider.
  final MapValues mapValues;

  /// The associated mapFunctions service, which is injected by the provider.
  final MapFunctions mapFunctions;

  const RoutingMapView({super.key, required this.mapValues, required this.mapFunctions});

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> with TickerProviderStateMixin {
  static const viewId = "routing.views.map";

  static const userLocationLayerId = "user-location-puck";

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated poi service, which is injected by the provider.
  late Pois pois;

  /// The associated location service, which is injected by the provider.
  late Positioning positioning;

  /// The associated layers service, which is injected by the provider.
  late Layers layers;

  /// The associated map designs service, which is injected by the provider.
  late MapDesigns mapDesigns;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  /// The associated tutorial service, which is injected by the provider.
  late Tutorial tutorial;

  /// The associated route label management service, which is created in the init.
  RouteLabelManager? routeLabelManager;

  /// A map controller for the map.
  MapboxMap? mapController;

  /// The animation for the on-tap animation.
  late Animation<double> animation;

  /// The default map insets.
  final defaultMapInsets = const EdgeInsets.only(
    top: 108,
    bottom: 146,
  );

  /// The current mode (dark/light).
  bool isDark = false;

  /// The route label coordinates.
  List<Map> routeLabelCoordinates = [];

  /// The index of the basemap layers where the first label layer is located (the label layers are top most).
  var firstBaseMapLabelLayerIndex = 0;

  /// A bool indicating whether the Mapbox internal map layers have finished loading.
  var mapLayersFinishedLoading = false;

  /// The waypoint pixel coordinates
  Map<Waypoint, ScreenCoordinate> waypointPixelCoordinates = {};

  /// The state of the POI popup.
  POIPopup? poiPopup;

  /// The relative horizontal margin in pixel for the poi pop up to be displayed.
  late double poiPopUpMarginLeft;

  /// The relative horizontal margin in pixel for the poi pop up to be displayed.
  late double poiPopUpMarginRight;

  /// The relative vertical margin in pixel for the poi pop up to be displayed.
  late double poiPopUpMarginTop;

  /// The relative vertical margin in pixel for the poi pop up to be displayed.
  late double poiPopUpMarginBottom;

  /// The absolute center x of the screen.
  late double centerX;

  /// The absolute center y of the screen.
  late double centerY;

  /// The bool that holds the state of map moving.
  bool isMapMoving = false;

  /// The bool that holds the state whether the edit waypoint indicator is displayed.
  bool showWaypointIndicator = false;

  /// The bool that holds the state whether the edit waypoint indicator is displayed.
  bool showRoutePreview = false;

  /// The index in the list represents the layer order in z axis.
  final List layerOrder = [
    VeloRoutesLayer.layerId,
    TrafficLayer.layerId,
    IntersectionsLayer.layerId,
    AllRoutesLayer.layerId,
    AllRoutesLayer.layerIdClick,
    RoutePreviewLayer.layerId,
    SelectedRouteLayer.layerIdBackground,
    SelectedRouteLayer.layerId,
    SelectedRouteLayer.layerIdChevrons,
    PoisLayer.layerIdBackground,
    PoisLayer.layerId,
    PoisLayer.layerIdSymbol,
    PoisLayer.layerIdCount,
    RouteCrossingsCircleLayer.layerId,
    SelectedRouteCrossingsCircleLayer.layerId,
    WaypointsLayer.layerId,
    OfflineCrossingsLayer.layerId,
    TrafficLightsLayer.layerId,
    GreenWaveLayer.layerId,
    BikeShopLayer.layerId,
    BikeShopLayer.textLayerId,
    BikeShopLayer.clickLayerId,
    BikeAirStationLayer.layerId,
    BikeAirStationLayer.textLayerId,
    BikeAirStationLayer.clickLayerId,
    ParkingStationsLayer.layerId,
    ParkingStationsLayer.clickLayerId,
    RentalStationsLayer.layerId,
    RentalStationsLayer.textLayerId,
    RentalStationsLayer.clickLayerId,
    userLocationLayerId,
  ];

  /// Returns the index where the layer should be added in the Mapbox layer stack.
  Future<int> getIndex(String layerId) async {
    final currentLayers = await mapController!.style.getStyleLayers();

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
  updateMapFunctions() async {
    if (widget.mapFunctions.needsCentering) {
      fitCameraToUserPosition();
      widget.mapFunctions.needsCentering = false;
      return;
    }

    if (widget.mapFunctions.needsCenteringNorth) {
      centerCameraToNorth();
      widget.mapFunctions.needsCenteringNorth = false;
      return;
    }

    if (widget.mapFunctions.needsNewWaypointCoordinates) {
      setCoordinatesForMovedWaypoint();
      widget.mapFunctions.needsNewWaypointCoordinates = false;
      return;
    }

    if (widget.mapFunctions.needsWaypointCentering) {
      if (widget.mapFunctions.tappedWaypointIdx != null) {
        Waypoint tappedWaypoint = routing.selectedWaypoints![widget.mapFunctions.tappedWaypointIdx!];
        // Add highlighting.
        if (!mounted) return;
        await WaypointsLayer(isDark, tappedWaypointIdx: widget.mapFunctions.tappedWaypointIdx!).update(mapController!);

        // Move the camera to the center of the waypoint.
        fitCameraToCoordinate(tappedWaypoint.lat, tappedWaypoint.lon);
        // Wait for animation.
        await Future.delayed(const Duration(seconds: 1));

        // Display the waypoint indicator.
        setState(() {
          showWaypointIndicator = true;
        });
        return;
      }
    }

    if (widget.mapFunctions.needsRemoveHighlighting) {
      // Remove highlighting.
      if (!mounted) return;
      await WaypointsLayer(isDark).update(mapController!);

      widget.mapFunctions.needsRemoveHighlighting = false;

      setState(() {
        showWaypointIndicator = false;
      });

      // To update the screen.
      if (Platform.isAndroid) {
        final cameraState = await mapController!.getCameraState();
        mapController!.flyTo(
          CameraOptions(
            zoom: cameraState.zoom + 0.001,
          ),
          MapAnimationOptions(duration: 100),
        );
      }
      return;
    }

    if (widget.mapFunctions.selectPointOnMap) {
      // Display the waypoint indicator.
      setState(() {
        showWaypointIndicator = true;
      });

      updateRoutePreview();

      if (Platform.isAndroid) {
        final cameraState = await mapController!.getCameraState();
        mapController!.flyTo(
          CameraOptions(
            zoom: cameraState.zoom + 0.001,
          ),
          MapAnimationOptions(duration: 100),
        );
      }
      return;
    } else {
      setState(() {
        showWaypointIndicator = false;
      });

      updateRoutePreview();

      if (Platform.isAndroid) {
        final cameraState = await mapController!.getCameraState();
        mapController!.flyTo(
          CameraOptions(
            zoom: cameraState.zoom + 0.001,
          ),
          MapAnimationOptions(duration: 100),
        );
      }
      return;
    }
  }

  /// Called when the listener callback of the Routing service ChangeNotifier is fired.
  updateRoute() {
    updateRouteMapLayers();

    fitCameraToRouteBounds();

    routeLabelManager?.resetService();
    routeLabelManager?.updateRouteLabels();
  }

  @override
  void initState() {
    super.initState();

    layers = getIt<Layers>();
    mapDesigns = getIt<MapDesigns>();
    positioning = getIt<Positioning>();
    routing = getIt<Routing>();
    pois = getIt<Pois>();
    status = getIt<PredictionSGStatus>();
    tutorial = getIt<Tutorial>();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // Calculate the relative padding for the pio pop up.
      final size = MediaQuery.of(context).size;
      poiPopUpMarginLeft = size.width * poiScreenMargin;
      poiPopUpMarginRight = size.width - size.width * poiScreenMargin;
      poiPopUpMarginTop = size.height * poiScreenMargin;
      poiPopUpMarginBottom = size.height - size.height * poiScreenMargin;
      centerX = size.width / 2;
      centerY = size.height / 2;
    });
  }

  @override
  void dispose() {
    layers.removeListener(loadGeoLayers);
    mapDesigns.removeListener(loadMapDesign);
    positioning.removeListener(displayCurrentUserLocation);
    routing.removeListener(updateRoute);
    pois.removeListener(updatePois);
    status.removeListener(updateSelectedRouteLayer);
    widget.mapFunctions.removeListener(updateMapFunctions);
    routeLabelManager?.removeListener(onRouteLabelUpdate);
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
          ),
        ),
      ),
      MapAnimationOptions(duration: duration),
    );
  }

  /// Fit the camera to the given position.
  fitCameraToCoordinate(double lat, double lon) async {
    if (mapController == null || !mounted) return;
    // Animation duration.
    const duration = 1000;

    // There is a bug in mapbox which causes padding to be saved for other flyTo/easeTo calls.
    // Therefore we can not apply padding here.
    await mapController?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            lon,
            lat,
          ),
        ),
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
      left: 86,
      // BottomSheet (122) + shortcuts (54) + attribution (16) + bottom padding
      bottom: (194 + frame.padding.bottom),
      // Width of legend
      right: 86,
    );

    final cameraOptionsForBounds = await mapController?.cameraForCoordinateBounds(
      routing.selectedRoute!.bounds,
      padding,
      currentCameraOptions.bearing,
      currentCameraOptions.pitch,
      null,
      null,
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
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await PoisLayer(isDark || mapDesigns.mapDesign.name == 'Satellit').update(mapController!);
  }

  /// Load the map layers.
  loadGeoLayers() async {
    if (mapController == null || !mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (layers.showAirStations) {
      final index = await getIndex(BikeAirStationLayer.layerId);
      if (!mounted) return;
      try {
        await BikeAirStationLayer(isDark).install(mapController!, at: index);
      } catch (e) {
        log.e("Error while installing layer BikeAirStationLayer: $e");
      }
    } else {
      if (!mounted) return;
      await BikeAirStationLayer.remove(mapController!);
    }
    if (layers.showParkingStations) {
      final index = await getIndex(ParkingStationsLayer.layerId);
      if (!mounted) return;
      try {
        await ParkingStationsLayer(isDark).install(mapController!, at: index);
      } catch (e) {
        log.e("Error while installing layer ParkingStationsLayer: $e");
      }
    } else {
      if (!mounted) return;
      await ParkingStationsLayer.remove(mapController!);
    }
    if (layers.showRentalStations) {
      final index = await getIndex(RentalStationsLayer.layerId);
      if (!mounted) return;
      try {
        await RentalStationsLayer(isDark).install(mapController!, at: index);
      } catch (e) {
        log.e("Error while installing layer RentalStationsLayer: $e");
      }
    } else {
      if (!mounted) return;
      await RentalStationsLayer.remove(mapController!);
    }
    if (layers.showRepairStations) {
      final index = await getIndex(BikeShopLayer.layerId);
      if (!mounted) return;
      try {
        await BikeShopLayer(isDark).install(mapController!, at: index);
      } catch (e) {
        log.e("Error while installing layer BikeShopLayer: $e");
      }
    } else {
      if (!mounted) return;
      await BikeShopLayer.remove(mapController!);
    }
    if (layers.showGreenWaveLayer) {
      final index = await getIndex(GreenWaveLayer.layerId);
      if (!mounted) return;
      try {
        await GreenWaveLayer(isDark).install(mapController!, at: index);
      } catch (e) {
        log.e("Error while installing layer GreenWaveLayer: $e");
      }
    } else {
      if (!mounted) return;
      await GreenWaveLayer.remove(mapController!);
    }
    if (layers.showTrafficLayer) {
      final index = await getIndex(TrafficLayer.layerId);
      if (!mounted) return;
      try {
        await TrafficLayer(isDark).install(mapController!, at: index);
      } catch (e) {
        log.e("Error while installing layer TrafficLayer: $e");
      }
    } else {
      if (!mounted) return;
      await TrafficLayer.remove(mapController!);
    }
    if (layers.showVeloRoutesLayer) {
      final index = await getIndex(VeloRoutesLayer.layerId);
      if (!mounted) return;
      try {
        await VeloRoutesLayer(isDark).install(mapController!, at: index);
      } catch (e) {
        log.e("Error while installing layer VeloRoutesLayer: $e");
      }
    } else {
      if (!mounted) return;
      await VeloRoutesLayer.remove(mapController!);
    }

    final index = await getIndex(IntersectionsLayer.layerId);
    if (!mounted) return;
    try {
      await IntersectionsLayer(isDark).install(mapController!, at: index);
    } catch (e) {
      log.e("Error while installing layer IntersectionsLayer: $e");
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

  /// Update pois layer.
  updatePois() async {
    if (mapController == null) return;
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await PoisLayer(isDark || mapDesigns.mapDesign.name == 'Satellit').update(mapController!);
  }

  /// Update selected route layer.
  updateSelectedRouteLayer() async {
    if (mapController == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!mounted) return;
    await SelectedRouteLayer(isDark, showStatus: true).update(mapController!);
    if (!mounted) return;
    // Pois on selected route are highlighted.
    await PoisLayer(isDark).update(mapController!);
    if (!mounted) return;
    await RouteCrossingsCircleLayer().update(mapController!);
    if (!mounted) return;
    await SelectedRouteCrossingsCircleLayer().update(mapController!);
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
    await WaypointsLayer(isDark).update(mapController!);
    await updatePois();
    await updateSelectedRouteLayer();
    if (!mounted) return;
    await AllRoutesLayer(isDark).update(mapController!);
    await RoutePreviewLayer(isDark).update(mapController!);
    if (!mounted) return;
  }

  /// Load all route map layers.
  loadRouteMapLayers() async {
    if (mapController == null) return;
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var index = await getIndex(OfflineCrossingsLayer.layerId);
    if (!mounted) return;
    try {
      await OfflineCrossingsLayer(isDark).install(
        mapController!,
        iconSize: 0.33,
        at: index,
      );
    } catch (e) {
      log.e("Error while installing layer OfflineCrossingsLayer: $e");
    }
    index = await getIndex(TrafficLightsLayer.layerId);
    if (!mounted) return;
    try {
      await TrafficLightsLayer(isDark).install(
        mapController!,
        iconSize: 0.33,
        at: index,
      );
    } catch (e) {
      log.e("Error while installing layer TrafficLightsLayer: $e");
    }
    index = await getIndex(WaypointsLayer.layerId);
    if (!mounted) return;
    try {
      await WaypointsLayer(isDark).install(
        mapController!,
        iconSize: 0.1,
        at: index,
      );
    } catch (e) {
      log.e("Error while installing layer WaypointsLayer: $e");
    }
    index = await getIndex(PoisLayer.layerId);
    if (!mounted) return;
    try {
      await PoisLayer(isDark || mapDesigns.mapDesign.name == 'Satellit').install(
        mapController!,
        at: index,
      );
    } catch (e) {
      log.e("Error while installing layer PoisLayer: $e");
    }
    index = await getIndex(SelectedRouteLayer.layerId);
    if (!mounted) return;
    try {
      await SelectedRouteLayer(isDark, showStatus: true).install(
        mapController!,
        at: index,
      );
    } catch (e) {
      log.e("Error while installing layer SelectedRouteLayer: $e");
    }
    index = await getIndex(RoutePreviewLayer.layerId);
    if (!mounted) return;
    try {
      await RoutePreviewLayer(isDark).install(
        mapController!,
        at: index,
      );
    } catch (e) {
      log.e("Error while installing layer RoutePreviewLayer: $e");
    }
    index = await getIndex(AllRoutesLayer.layerId);
    if (!mounted) return;
    try {
      await AllRoutesLayer(isDark).install(
        mapController!,
        at: index,
      );
    } catch (e) {
      log.e("Error while installing layer AllRoutesLayer: $e");
    }
    index = await getIndex(RouteCrossingsCircleLayer.layerId);
    if (!mounted) return;
    try {
      await RouteCrossingsCircleLayer().install(
        mapController!,
        at: index,
      );
    } catch (e) {
      log.e("Error while installing layer RouteCrossingsCircleLayer: $e");
    }
    index = await getIndex(SelectedRouteCrossingsCircleLayer.layerId);
    if (!mounted) return;
    try {
      await SelectedRouteCrossingsCircleLayer().install(
        mapController!,
        at: index,
      );
    } catch (e) {
      log.e("Error while installing layer SelectedRouteCrossingsCircleLayer: $e");
    }
  }

  /// A callback that is called when the user taps a feature.
  onFeatureTapped(QueriedRenderedFeature queriedRenderedFeature) async {
    // Map the id of the layer to the corresponding feature.
    final id = queriedRenderedFeature.queriedFeature.feature['id'];

    if (id != null) {
      // Case waypoint
      if ((id as String).startsWith("waypoint-")) {
        final waypointIdx = int.tryParse(id.split("-")[1]);
        if (waypointIdx == null) return;
        if (routing.selectedWaypoints == null) return;
        widget.mapFunctions.setTappedWaypointIdx(waypointIdx);
        widget.mapFunctions.setCameraCenterOnWaypointLocation();
        return;
      }

      // Only check for more features if edit waypoint mode is not active.
      if (widget.mapFunctions.tappedWaypointIdx != null) return;

      // Case Route or Route label.
      if ((id).startsWith("route-")) {
        final routeIdx = int.tryParse(id.split("-")[1]);
        if (routeIdx == null || (routing.selectedRoute != null && routeIdx == routing.selectedRoute!.idx)) return;
        routing.switchToRoute(routeIdx);
        return;
      }
    }

    Map? properties = queriedRenderedFeature.queriedFeature.feature["properties"] as Map?;
    if (properties != null) {
      if (properties.containsKey("id")) {
        final propertiesId = properties["id"];
        // Case POIs.
        if (propertiesId.contains("bike_air_station") ||
            propertiesId.contains("bicycle_shop") ||
            propertiesId.contains("bicycle_rental") ||
            propertiesId.contains("bicycle_parking")) {
          if (mapController == null) return;
          Map? geometry = queriedRenderedFeature.queriedFeature.feature["geometry"] as Map?;
          if (geometry == null) return;
          double lon = geometry["coordinates"][0];
          double lat = geometry["coordinates"][1];

          var name = "";
          final type = propertiesId.split("-")[0];
          switch (type) {
            case "bike_air_station":
              name = "Luftstation${properties.containsKey("anmerkungen") ? " ${properties["anmerkungen"]}" : ""}";
              BikeAirStationLayer(isDark).toggleSelect(mapController!, selectedPOIId: propertiesId);
              break;
            case "bicycle_shop":
              name = properties.containsKey("name") ? properties["name"] : "Fahrradladen";
              BikeShopLayer(isDark).toggleSelect(mapController!, selectedPOIId: propertiesId);
              break;
            case "bicycle_rental":
              name = "Ausleihstation${properties.containsKey("name") ? " ${properties["name"]}" : ""}";
              RentalStationsLayer(isDark).toggleSelect(mapController!, selectedPOIId: propertiesId);
              break;
            case "bicycle_parking":
              name = "Fahrradständer";
              ParkingStationsLayer(isDark).toggleSelect(mapController!, selectedPOIId: propertiesId);
              break;
            default:
              return;
          }

          // Move the camera to the center of the POI.
          fitCameraToCoordinate(lat, lon);

          final position = await mapController!.pixelForCoordinate(
            Point(
              coordinates: Position(
                lon,
                lat,
              ),
            ),
          );

          setState(() {
            poiPopup = POIPopup(
                poiElement: POIElement(
                  name: name,
                  typeDescription: type,
                  lon: lon,
                  lat: lat,
                ),
                screenCoordinateX: position.x,
                screenCoordinateY: position.y,
                poiOpacity: 1);
          });
        }
      }
    }
  }

  /// Fit the attribution position to the position of the bottom sheet.
  fitAttributionPosition({double? sheetHeightRelative}) {
    if (mapController == null) return;

    // Bottom padding + sheet init size + padding + shortcut height + padding.
    const attributionMargins = math.Point(10, 122 + 8 + 40 + 8);
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

    final frame = MediaQuery.of(context);
    // Fit left and right to the button margin fo 86px.
    const routeLabelMarginLeft = 0.0;
    final routeLabelMarginRight = frame.size.width;
    final routeLabelMarginTop = frame.padding.top;
    // Fit initial bottom sheet size of 140px - padding - shortcut row - mapbox attributes.
    final routeLabelMarginBottom = frame.size.height - frame.padding.bottom - 140 - 8 - 32 - 16;
    final widthMid = frame.size.width / 2;
    final heightMid = frame.size.height / 2;
    routeLabelManager = RouteLabelManager(
      routeLabelMarginLeft: routeLabelMarginLeft,
      routeLabelMarginRight: routeLabelMarginRight,
      routeLabelMarginTop: routeLabelMarginTop,
      routeLabelMarginBottom: routeLabelMarginBottom,
      widthMid: widthMid,
      heightMid: heightMid,
      mapController: mapController!,
    );
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
    pois.addListener(updatePois);
    status.addListener(updateSelectedRouteLayer);
    widget.mapFunctions.addListener(updateMapFunctions);
    routeLabelManager?.addListener(onRouteLabelUpdate);

    await getFirstLabelLayer();

    // Load all symbols that will be displayed on the map.
    try {
      await SymbolLoader(mapController!).loadSymbols();
    } catch (e) {
      log.e("Error while installing layer SymbolLoader: $e");
    }

    // Fit the content below the top and the bottom stuff.
    fitAttributionPosition();

    await displayCurrentUserLocation();
    await loadGeoLayers();

    // Load the boundary layer.
    try {
      await BoundaryLayer(isDark).install(mapController!);
    } catch (e) {
      log.e("Error while installing layer BoundaryLayer: $e");
    }

    await fitCameraToRouteBounds();
    await loadRouteMapLayers();
  }

  /// A callback which is executed when a tap on the map is registered.
  /// This also resolves if a certain feature is being tapped on.
  Future<void> onMapTap(MapContentGestureContext mapContentGestureContext) async {
    if (mapController == null || !mounted) return;
    // Do not handle onTap when add waypoint mode is active.
    if (widget.mapFunctions.selectPointOnMap) return;

    if (poiPopup != null) {
      await resetPOISelection();
    }

    final List<QueriedRenderedFeature?> features = await mapController!.queryRenderedFeatures(
      RenderedQueryGeometry(
        value: json.encode(mapContentGestureContext.touchPosition.encode()),
        type: Type.SCREEN_COORDINATE,
      ),
      RenderedQueryOptions(
        layerIds: [
          AllRoutesLayer.layerIdClick,
          BikeShopLayer.clickLayerId,
          BikeShopLayer.textLayerId,
          BikeAirStationLayer.clickLayerId,
          BikeAirStationLayer.textLayerId,
          RentalStationsLayer.clickLayerId,
          RentalStationsLayer.textLayerId,
          ParkingStationsLayer.clickLayerId,
          WaypointsLayer.layerId,
        ],
      ),
    );

    if (features.isNotEmpty) {
      onFeatureTapped(features[0]!);
      return;
    }
  }

  /// A callback which is executed when a long tap on the map is registered.
  Future<void> onMapLongTap(MapContentGestureContext mapContentGestureContext) async {
    if (mapController == null || !mounted) return;

    // Do not handle onLongTap when add waypoint mode is active.
    if (widget.mapFunctions.selectPointOnMap) return;

    if (poiPopup != null) {
      await resetPOISelection();
    }

    final List<QueriedRenderedFeature?> features = await mapController!.queryRenderedFeatures(
      RenderedQueryGeometry(
        value: json.encode(mapContentGestureContext.touchPosition.encode()),
        type: Type.SCREEN_COORDINATE,
      ),
      RenderedQueryOptions(
        layerIds: [
          WaypointsLayer.layerId,
        ],
      ),
    );

    if (features.isNotEmpty) {
      // Handle edit waypoint.
      onFeatureTapped(features[0]!);
      return;
    }
  }

  /// Resets the current POI selection.
  Future<void> resetPOISelection() async {
    if (mapController == null || !mounted) return;
    if (poiPopup == null) return;
    switch (poiPopup!.poiElement.typeDescription) {
      case "bike_air_station":
        BikeAirStationLayer(isDark).toggleSelect(mapController!);
        break;
      case "bicycle_shop":
        BikeShopLayer(isDark).toggleSelect(mapController!);
        break;
      case "bicycle_rental":
        RentalStationsLayer(isDark).toggleSelect(mapController!);
        break;
      case "bicycle_parking":
        ParkingStationsLayer(isDark).toggleSelect(mapController!);
        break;
      default:
        return;
    }

    setState(() {
      poiPopup = null;
    });
  }

  /// Updates the route preview visualization if needed.
  Future<void> updateRoutePreview() async {
    if (mapController == null || !mounted) return;
    // Only update if adding waypoint at is active.
    if (showWaypointIndicator == false || !widget.mapFunctions.selectPointOnMap) {
      if (showRoutePreview == false) return;
      if (!mounted) return;
      await RoutePreviewLayer(isDark).update(mapController!);
      showRoutePreview = false;
      return;
    }

    if (routing.selectedWaypoints == null) return;

    final Point centerCoordinate = await mapController!.coordinateForPixel(ScreenCoordinate(x: centerX, y: centerY));

    // Snap the screenCoordinates to the route.
    final addedPosition =
        LatLng(centerCoordinate.coordinates.lat.toDouble(), centerCoordinate.coordinates.lng.toDouble());

    final bestWaypointIndex = routing.getBestWaypointInsertIndex(addedPosition);

    // Update the route preview layer depending on the best waypoint index.
    if (bestWaypointIndex == 0) {
      if (!mounted) return;
      await RoutePreviewLayer(
        isDark,
        addedPosition: addedPosition,
        snappedWaypoint: LatLng(
            routing.selectedWaypoints![bestWaypointIndex].lat, routing.selectedWaypoints![bestWaypointIndex].lon),
      ).update(mapController!);
      showRoutePreview = true;
    } else if (bestWaypointIndex == routing.selectedWaypoints!.length) {
      if (!mounted) return;
      await RoutePreviewLayer(
        isDark,
        addedPosition: addedPosition,
        snappedWaypoint: LatLng(routing.selectedWaypoints![bestWaypointIndex - 1].lat,
            routing.selectedWaypoints![bestWaypointIndex - 1].lon),
      ).update(mapController!);
      showRoutePreview = true;
      return;
    } else if (bestWaypointIndex > 0) {
      await RoutePreviewLayer(
        isDark,
        addedPosition: addedPosition,
        snappedWaypoint: LatLng(routing.selectedWaypoints![bestWaypointIndex - 1].lat,
            routing.selectedWaypoints![bestWaypointIndex - 1].lon),
        snappedSecondWaypoint: LatLng(
            routing.selectedWaypoints![bestWaypointIndex].lat, routing.selectedWaypoints![bestWaypointIndex].lon),
      ).update(mapController!);
      showRoutePreview = true;
    }
  }

  /// Add a waypoint at the tapped position.
  /// When the parameter atBestLocationOnRoute is set to true,
  /// we select the best position inbetween existing waypoints with
  /// regard to the route.
  Future<void> addWaypoint(ScreenCoordinate point, {atBestLocationOnRoute = false}) async {
    final Point coord = await mapController!.coordinateForPixel(point);
    final geocoding = getIt<Geocoding>();
    final fallback = "Wegpunkt ${(routing.selectedWaypoints?.length ?? 0) + 1}";
    final longitude = coord.coordinates.lng.toDouble();
    final latitude = coord.coordinates.lat.toDouble();
    final coordLatLng = LatLng(latitude, longitude);

    final pointIsInBoundary = getIt<Boundary>().checkIfPointIsInBoundary(longitude, latitude);
    if (!pointIsInBoundary) {
      if (!mounted) return;
      final city = getIt<Settings>().city;
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black.withOpacity(0.4),
        transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
        pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
          return DialogLayout(
            title: 'Wegpunkt außerhalb des Stadtgebiets',
            text:
                'Das Routing wird aktuell nur innerhalb von ${city.nameDE} unterstützt. \nBitte passe Deinen Wegpunkt an.',
            actions: [
              BigButtonPrimary(
                label: "Ok",
                onPressed: () => Navigator.of(context).pop(),
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
              )
            ],
          );
        },
      );
      return;
    }

    String address = await geocoding.reverseGeocode(coordLatLng) ?? fallback;

    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) {
      await routing.addWaypoint(Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude));
    }
    tutorial.complete("priobike.tutorial.draw-waypoints");
    final waypoint = Waypoint(latitude, longitude, address: address);
    // if the user is adding a waypoint by tapping on the map
    // the waypoint must be appended at the best position or to end of list
    // the waypoint must be appended at the best position or to end of list
    int index;
    if (atBestLocationOnRoute) {
      // Find the best index where the waypoint should be inserted.
      index = routing.getBestWaypointInsertIndex(coordLatLng);
    } else {
      // Simply add the waypoint at the end.
      index = routing.selectedWaypoints!.length;
    }
    await routing.addWaypoint(waypoint, index);
    await getIt<Geosearch>().addToSearchHistory(waypoint);
    await routing.loadRoutes();
  }

  /// Replaces a waypoint at the tapped position.
  Future<void> replaceWaypoint(ScreenCoordinate point, int idx) async {
    final Point coord = await mapController!.coordinateForPixel(point);
    final geocoding = getIt<Geocoding>();
    final fallback = "Wegpunkt ${(routing.selectedWaypoints?.length ?? 0) + 1}";
    final longitude = coord.coordinates.lng.toDouble();
    final latitude = coord.coordinates.lat.toDouble();
    final coordLatLng = LatLng(latitude, longitude);

    final pointIsInBoundary = getIt<Boundary>().checkIfPointIsInBoundary(longitude, latitude);
    if (!pointIsInBoundary) {
      if (!mounted) return;
      final city = getIt<Settings>().city;
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black.withOpacity(0.4),
        transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
        pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
          return DialogLayout(
            title: 'Wegpunkt außerhalb des Stadtgebiets',
            text:
                'Das Routing wird aktuell nur innerhalb von ${city.nameDE} unterstützt. \nBitte passe Deinen Wegpunkt an.',
            actions: [
              BigButtonPrimary(
                label: "Ok",
                onPressed: () => Navigator.of(context).pop(),
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
              )
            ],
          );
        },
      );
      return;
    }

    String address = await geocoding.reverseGeocode(coordLatLng) ?? fallback;

    tutorial.complete("priobike.tutorial.draw-waypoints");
    final waypoint = Waypoint(latitude, longitude, address: address);

    // Remove old waypoint.
    routing.selectedWaypoints!.removeAt(idx);

    await getIt<Geosearch>().addToSearchHistory(waypoint);

    // Only change the location of the current waypoint and not load a route if selected waypoint length was 1.
    if (routing.selectedWaypoints!.isEmpty) {
      routing.selectWaypoints([waypoint]);
    } else {
      // Add waypoint at index and load route.
      await routing.addWaypoint(waypoint, idx);
      await routing.loadRoutes();
    }
  }

  /// Updates the bearing and centering button.
  Future<void> updateBearingAndCenteringButtons() async {
    if (mapController == null) return;

    final CameraState camera = await mapController!.getCameraState();

    // Set bearing in mapFunctions.
    widget.mapValues.setCameraBearing(camera.bearing);

    // Cast from Object to List [lon, lat].
    final coordinates = camera.center.coordinates;
    if (coordinates.length != 2) return;
    if (positioning.lastPosition == null) return;
    // To make the values comparable.
    final double lat = double.parse(coordinates[1]!.toStringAsFixed(4));
    final double lon = double.parse(coordinates[0]!.toStringAsFixed(4));
    final double latUser = double.parse(positioning.lastPosition!.latitude.toStringAsFixed(4));
    final double lonUser = double.parse(positioning.lastPosition!.longitude.toStringAsFixed(4));

    if (lat == latUser && lon == lonUser) {
      widget.mapValues.setCameraCentered();
    } else {
      widget.mapValues.setCameraNotCentered();
    }
  }

  /// Function that Updates the route labels.
  Future<void> onRouteLabelUpdate() async {
    setState(() {});
  }

  /// Updates the bearing and centering button.
  Future<void> updatePOIPopupScreenPosition() async {
    if (mapController == null) return;
    if (poiPopup == null) return;

    final position = await mapController!.pixelForCoordinate(
      Point(
        coordinates: Position(
          poiPopup!.poiElement.lon,
          poiPopup!.poiElement.lat,
        ),
      ),
    );

    double x = poiPopup!.screenCoordinateX;
    double y = poiPopup!.screenCoordinateY;
    double opacity = poiPopup!.poiOpacity;

    // Only update the position for non negative values to make sure that the pop up doesn't move to the top corner.
    if (position.x > 0 && position.y > 0) {
      x = position.x;
      y = position.y;
    }

    // Update the poi pop up opacity depending on the position.
    if (position.x > poiPopUpMarginLeft &&
        position.x < poiPopUpMarginRight &&
        position.y > poiPopUpMarginTop &&
        position.y < poiPopUpMarginBottom) {
      if (poiPopup!.poiOpacity == 0) opacity = 1;
    } else {
      if (poiPopup!.poiOpacity == 1) opacity = 0;
    }

    setState(() => poiPopup!.updatePopUp(x, y, opacity));
  }

  /// A callback that is executed when the camera movement changes.
  Future<void> onCameraChanged(CameraChangedEventData cameraChangedEventData) async {
    // Set map moving.
    if (!isMapMoving) {
      setState(() {
        isMapMoving = true;
      });
    }

    if (mapController == null) return;

    updateBearingAndCenteringButtons();

    updatePOIPopupScreenPosition();

    updateRoutePreview();
  }

  /// A callback that is executed when the camera movement changes.
  Future<void> onMapIdle(MapIdleEventData mapIdleEventData) async {
    setState(() {
      isMapMoving = false;
    });
    routeLabelManager?.updateRouteLabels();
  }

  /// The callback that is executed when the POI gets selected in the popup.
  Future<void> onPressedPOIPopup() async {
    if (poiPopup == null) return;
    // Add POI to routing and fetch route.
    final waypoint = Waypoint(poiPopup!.poiElement.lat, poiPopup!.poiElement.lon, address: poiPopup!.poiElement.name);
    final waypoints = routing.selectedWaypoints ?? [];

    // Add the own location as a start point to the route, if the waypoint selected in the search is the
    // first waypoint of the route. Thus making it the destination of the route.
    if (waypoints.isEmpty) {
      if (positioning.lastPosition != null) {
        waypoints.add(Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude));
      }
    }
    final newWaypoints = [...waypoints, waypoint];

    routing.selectWaypoints(newWaypoints);
    routing.loadRoutes();

    resetPOISelection();
  }

  /// The callback that is executed when the route label got pressed.
  void onPressedRouteLabel(int id) async {
    routing.switchToRoute(id);
  }

  /// Get the coordinates for the moved waypoint.
  void setCoordinatesForMovedWaypoint() async {
    if (mapController == null) return;

    final frame = MediaQuery.of(context);
    final x = frame.size.width / 2;
    final y = frame.size.height / 2;

    final point = ScreenCoordinate(x: x, y: y);

    if (widget.mapFunctions.tappedWaypointIdx != null) {
      if (routing.selectedWaypoints == null) return;

      int idx = widget.mapFunctions.tappedWaypointIdx!;

      // replace waypoint at the new position
      widget.mapFunctions.reset();
      await replaceWaypoint(point, idx);
    } else if (widget.mapFunctions.selectPointOnMap) {
      // Add waypoint at best location.
      widget.mapFunctions.reset();
      await addWaypoint(point, atBestLocationOnRoute: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    isDark = Theme.of(context).brightness == Brightness.dark;
    final frame = MediaQuery.of(context);

    return Stack(
      children: [
        // Show the map.
        AppMap(
          onMapCreated: onMapCreated,
          onStyleLoaded: onStyleLoaded,
          onCameraChanged: onCameraChanged,
          onMapIdle: onMapIdle,
          onMapTap: onMapTap,
          onMapLongClick: onMapLongTap,
          logoViewOrnamentPosition: OrnamentPosition.BOTTOM_LEFT,
          attributionButtonOrnamentPosition: OrnamentPosition.BOTTOM_RIGHT,
        ),

        if (routeLabelManager != null &&
            widget.mapFunctions.tappedWaypointIdx == null &&
            !widget.mapFunctions.selectPointOnMap &&
            routeLabelManager!.managedRouteLabels.isNotEmpty)
          ...routeLabelManager!.managedRouteLabels.map((ManagedRouteLabel managedRouteLabel) {
            if (managedRouteLabel.ready()) {
              return Positioned(
                left: managedRouteLabel.screenCoordinateX,
                top: managedRouteLabel.screenCoordinateY,
                child: FractionalTranslation(
                  translation: Offset(
                    managedRouteLabel.alignment == RouteLabelAlignment.topLeft ||
                            managedRouteLabel.alignment == RouteLabelAlignment.bottomLeft
                        ? 0
                        : -1,
                    managedRouteLabel.alignment == RouteLabelAlignment.topLeft ||
                            managedRouteLabel.alignment == RouteLabelAlignment.topRight
                        ? 0
                        : -1,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      onPressedRouteLabel(managedRouteLabel.routeIdx);
                    },
                    child: RouteLabel(
                      routeIdx: managedRouteLabel.routeIdx,
                      alignment: managedRouteLabel.alignment!,
                      isMapMoving: isMapMoving,
                    ),
                  ),
                ),
              );
            } else {
              return Container();
            }
          }),

        if (poiPopup != null)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            // Subtract half the width of the widget to center it.
            left: poiPopup!.screenCoordinateX - (frame.size.width * 0.3),
            top: poiPopup!.screenCoordinateY,
            child: AnimatedOpacity(
              opacity: poiPopup!.poiOpacity,
              duration: const Duration(milliseconds: 150),
              child: POIInfoPopup(selectedPOI: poiPopup!.poiElement, onPressed: onPressedPOIPopup),
            ),
          ),

        if (!mapLayersFinishedLoading)
          Center(
            child: Tile(
              fill: Theme.of(context).colorScheme.surface,
              shadowIntensity: 0.2,
              shadow: Colors.black,
              content: const CircularProgressIndicator(),
            ),
          ),

        // Show waypoint indicator for edit waypoint.
        if (showWaypointIndicator && widget.mapFunctions.tappedWaypointIdx != null && routing.selectedWaypoints != null)
          TargetMarkerIcon(
            idx: widget.mapFunctions.tappedWaypointIdx!,
            waypointSize: routing.selectedWaypoints!.length,
          ),

        // Show waypoint indicator for add waypoint.
        if (showWaypointIndicator && widget.mapFunctions.selectPointOnMap)
          const TargetMarkerIcon(
            idx: 0,
            waypointSize: 1,
          ),
      ],
    );
  }
}
