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
import 'package:priobike/home/services/poi.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/drag_waypoint.dart';
import 'package:priobike/routing/models/poi_popup.dart';
import 'package:priobike/routing/models/route.dart' as r;
import 'package:priobike/routing/models/route_label.dart';
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
import 'package:priobike/routing/views/details/poi_popup.dart';
import 'package:priobike/routing/views/details/route_label.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tutorial/service.dart';

/// The fixed icon size of the cancel button.
const double cancelButtonIconSize = 50;

/// The value used to calculate the relative space after which the poi pop ups should be fade in or out.
const double poiScreenMargin = 0.1;

const double routeLabelScreenMarginHorizontal = 0.05;

/// Assumptions for the width and height of the route label box dimensions for the candidate evaluation. (Overestimated)
const double routeLabelBoxWidth = 100;
const double routeLabelBoxHeight = 50;

class RoutingMapView extends StatefulWidget {
  const RoutingMapView({super.key});

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

  /// Where the user is currently tapping.
  Offset? tapPosition;

  /// Where the user is currently long tapping, used for dragging waypoints.
  Offset? dragPosition;

  /// Whether the auxiliary marking around a waypoint is displayed or not.
  bool showAuxiliaryMarking = false;

  /// The animation controller for the on-tap animation.
  late AnimationController animationController;

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

  /// A lock that avoids rapid relocating of route labels.
  final routeLabelLock = Lock(milliseconds: 250);

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

  /// Whether user is dragging a waypoint over the cancel button.
  bool highlightCancelButton = false;

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

  /// The state of the route labels.
  List<RouteLabel> routeLabels = [];

  /// The bool that holds the state of map moving.
  bool isMapMoving = false;

  /// The relative horizontal margin in pixel for the route label to be displayed.
  late double routeLabelMarginLeft;

  /// The relative horizontal margin in pixel for the route label to be displayed.
  late double routeLabelMarginRight;

  /// The relative vertical margin in pixel for the route label to be displayed.
  late double routeLabelMarginTop;

  /// The relative vertical margin in pixel for the route label to be displayed.
  late double routeLabelMarginBottom;

  /// The relative vertical margin in pixel for the route label to be displayed.
  late double widthMid;

  /// The relative vertical margin in pixel for the route label to be displayed.
  late double heightMid;

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

    updateRouteLabels();
  }

  @override
  void initState() {
    super.initState();

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

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // Calculate the relative margin for the pio pop up.
      final frame = MediaQuery.of(context);
      poiPopUpMarginLeft = frame.size.width * poiScreenMargin;
      poiPopUpMarginRight = frame.size.width - frame.size.width * poiScreenMargin;
      poiPopUpMarginTop = frame.size.height * poiScreenMargin;
      poiPopUpMarginBottom = frame.size.height - frame.size.height * poiScreenMargin;

      // Calculate the relative margin for the route label.
      routeLabelMarginLeft = frame.size.width * routeLabelScreenMarginHorizontal;
      routeLabelMarginRight = frame.size.width - frame.size.width * routeLabelScreenMarginHorizontal;
      routeLabelMarginTop = frame.padding.top;
      // Fit initial bottom sheet size of 128px.
      routeLabelMarginBottom = frame.size.height - 128;
      widthMid = frame.size.width / 2;
      heightMid = frame.size.height / 2;
    });
  }

  @override
  void dispose() {
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
    final frame = MediaQuery.of(context);
    MbxEdgeInsets padding = MbxEdgeInsets(
      // (AppBackButton height + top padding)
      top: (80 + frame.padding.top),
      // AppBackButton width
      left: 0,
      // (BottomSheet + bottom padding)
      bottom: (146 + frame.padding.bottom),
      right: 0,
    );

    await mapController?.flyTo(
      CameraOptions(
          center: Point(
            coordinates: Position(
              positioning.lastPosition!.longitude,
              positioning.lastPosition!.latitude,
            ),
          ).toJson(),
          padding: padding),
      MapAnimationOptions(duration: duration),
    );
  }

  /// Fit the camera to the given position.
  fitCameraToCoordinate(double lat, double lon) async {
    if (mapController == null || !mounted) return;
    // Animation duration.
    const duration = 1000;
    final frame = MediaQuery.of(context);
    MbxEdgeInsets padding = MbxEdgeInsets(
      // (AppBackButton height + top padding)
      top: (80 + frame.padding.top),
      // AppBackButton width
      left: 0,
      // (BottomSheet + bottom padding)
      bottom: (146 + frame.padding.bottom),
      right: 0,
    );

    await mapController?.flyTo(
      CameraOptions(
          center: Point(
            coordinates: Position(
              lon,
              lat,
            ),
          ).toJson(),
          padding: padding),
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
      bottom: (146 + frame.padding.bottom),
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
  }

  /// Load all route map layers.
  loadRouteMapLayers() async {
    if (mapController == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var index = await getIndex(OfflineCrossingsLayer.layerId);
    if (!mounted) return;
    await OfflineCrossingsLayer(isDark).install(
      mapController!,
      iconSize: 0.33,
      at: index,
    );
    index = await getIndex(TrafficLightsLayer.layerId);
    if (!mounted) return;
    await TrafficLightsLayer(isDark).install(
      mapController!,
      iconSize: 0.33,
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
      iconSize: 0.2,
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
  }

  /// A callback that is called when the user taps a feature.
  onFeatureTapped(QueriedFeature queriedFeature) async {
    // Map the id of the layer to the corresponding feature.
    final id = queriedFeature.feature['id'];

    if (id != null) {
      // Case Route or Route label.
      if ((id as String).startsWith("route-") || id.startsWith("routeLabel-")) {
        final routeIdx = int.tryParse(id.split("-")[1]);
        if (routeIdx == null || (routing.selectedRoute != null && routeIdx == routing.selectedRoute!.id)) return;
        routing.switchToRoute(routeIdx);
        return;
      }
    }

    Map? properties = queriedFeature.feature["properties"] as Map?;
    if (properties != null) {
      if (properties.containsKey("id")) {
        final propertiesId = properties["id"];
        // Case POIs.
        if (propertiesId.contains("bike_air_station") ||
            propertiesId.contains("bicycle_shop") ||
            propertiesId.contains("bicycle_rental") ||
            propertiesId.contains("bicycle_parking")) {
          if (mapController == null) return;
          Map? geometry = queriedFeature.feature["geometry"] as Map?;
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
            ).toJson(),
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
    final frame = MediaQuery.of(context);
    final sheetHeightAbs = sheetHeightRelative == null
        // Bottom padding + sheet init size + padding + shortcut height + padding.
        ? 124.0 + 8 + 40 + 8 // Default value.
        // Bottom padding + sheet relative size + padding + shortcut height + padding.
        : sheetHeightRelative * frame.size.height + 40 + 8;
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
    // Bottom padding + sheet init size + padding + shortcut height + padding.
    const attributionMargins = math.Point(10, 124 + 8 + 40 + 8);
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

    if (poiPopup != null) {
      await resetPOISelection();
    }

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
        layerIds: [
          AllRoutesLayer.layerIdClick,
          RouteLabelLayer.layerId,
          BikeShopLayer.clickLayerId,
          BikeShopLayer.textLayerId,
          BikeAirStationLayer.clickLayerId,
          BikeAirStationLayer.textLayerId,
          RentalStationsLayer.clickLayerId,
          RentalStationsLayer.textLayerId,
          ParkingStationsLayer.clickLayerId,
        ],
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

  /// A callback that is executed when the map was longclicked.
  onMapLongClick(BuildContext context, double x, double y) async {
    if (mapController == null) return;
    // Convert x and y into a lat/lon.
    final point = ScreenCoordinate(x: x, y: y);
    await addWaypoint(point);
  }

  /// Check if user tapped on an existing waypoint and return the waypoint if found.
  Waypoint? _checkIfWaypointIsAtTappedPosition({required double x, required double y}) {
    if (mapController == null) return null;
    if (routing.selectedWaypoints == null) return null;

    final tapPosition = ScreenCoordinate(x: x, y: y);

    Waypoint? foundWaypoint;
    double? foundWaypointDistance;

    for (var entry in waypointPixelCoordinates.entries) {
      final distance =
          math.sqrt(math.pow(entry.value.x - tapPosition.x, 2) + math.pow(entry.value.y - tapPosition.y, 2));

      if (distance < 50) {
        // get closest waypoint if there are multiple waypoints at the same position
        if (foundWaypointDistance == null || distance < foundWaypointDistance) {
          foundWaypoint = entry.key;
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
                'Das Routing wird aktuell nur innerhalb von ${backend.region} unterstützt. \nBitte passe Deinen Wegpunkt an.',
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

  /// Updates the waypoint pixel coordinates for dragging waypoints.
  Future<void> updateWaypointPixelCoordinates() async {
    if (mapController == null) return;
    if (routing.selectedWaypoints == null) return;

    Map<Waypoint, ScreenCoordinate> newWaypointPixelCoordinates = {};

    for (Waypoint waypoint in routing.selectedWaypoints!) {
      final ScreenCoordinate coordsOnScreenWaypoint = await mapController!.pixelForCoordinate({
        "coordinates": [waypoint.lon, waypoint.lat]
      });
      newWaypointPixelCoordinates[waypoint] = coordsOnScreenWaypoint;
    }

    waypointPixelCoordinates = newWaypointPixelCoordinates;
  }

  /// Function that Updates the route labels.
  Future<void> updateRouteLabels() async {
    // Reset route label everytime a new route is fetching.
    if (routing.isFetchingRoute) {
      setState(() {
        routeLabels = [];
      });
      return;
    }

    // Check conditions for displaying route labels.
    if (mapController == null) return;
    if (routing.allRoutes == null) return;
    if (routing.allRoutes!.length < 2) return;

    // Initialize route label.
    // Init id, time text, secondary text and unique coordinates per route once.
    if (routeLabels.isEmpty) {
      // Init unique waypoints per route.
      List<List<GHCoordinate>> uniqueCoordinatesPerRoute = getUniqueCoordinatesPerRoute();

      for (r.Route route in routing.allRoutes!) {
        // TODO Find text to be displayed for routes.
        String? secondaryText = routing.findMostUniqueAttributeForRoute(route.id);

        routeLabels.add(
          RouteLabel(
            id: route.id,
            selected: routing.selectedRoute!.id == route.id,
            timeText: route.timeText,
            secondaryText: null,
            uniqueCoordinates: uniqueCoordinatesPerRoute[route.id],
          ),
        );
      }
    }

    // The new route label list is set at the end of this function.
    List<RouteLabel> updatedRouteLabels = [];
    // The list of lists with all screen coordinates.
    // Separated in different lists to avoid connecting screen coordinates of different routes to segments.
    List<List<ScreenCoordinate>> allCoordinates = [];

    // Preprocess data and calculate new candidates for the route labels.
    for (RouteLabel routeLabel in routeLabels) {
      // Update selected route label.
      routeLabel.selected = routing.selectedRoute!.id == routeLabel.id;

      // Get all screen coordinates of the route labels route and all candidates for this route label.
      var (allCoordinatesRouteLabel, candidates) = await getScreenCoordinates(routeLabel);
      if (allCoordinatesRouteLabel != null) {
        // Add to all coordinates.
        allCoordinates.add(allCoordinatesRouteLabel);
      }
      routeLabel.candidates = candidates;
    }

    // Calculate intersections with route coordinates and screen bounds and filter those candidates.
    for (RouteLabel routeLabel in routeLabels) {
      // Filtered candidates in decreasing order.
      List<RouteLabelCandidate> filteredCandidates = [];

      // Leave filteredCandidates empty if not candidates are in view.
      if (routeLabel.candidates == null || routeLabel.candidates!.isEmpty) {
        routeLabel.filteredCandidates = filteredCandidates;
        continue;
      }

      // Loop through candidates and filter.
      for (ScreenCoordinate candidate in routeLabel.candidates!) {
        // Check intersection with route segments for different orientations and return possible route label boxes.
        List<RouteLabelBox> possibleBoxes = _getPossibleRouteLabelBoxes(candidate, allCoordinates);

        // Skip candidate if no possible box found.
        if (possibleBoxes.isEmpty) continue;
        filteredCandidates.add(RouteLabelCandidate(candidate, possibleBoxes));
      }

      // Sort the filtered candidates so that the middlemost are the first ones to check compatibility.
      filteredCandidates.sort((a, b) =>
          ((a.screenCoordinate.x - widthMid).abs() + (a.screenCoordinate.y - heightMid).abs()) >
                  ((b.screenCoordinate.x - widthMid).abs() + (b.screenCoordinate.y - heightMid).abs())
              ? 1
              : 0);

      // Finally set filtered candidates for route label.
      routeLabel.filteredCandidates = filteredCandidates;
    }

    // Choose route label boxes that do not intersect with each other.
    // Therefore go through route labels and find the first combination, that do not intersect for all route labels given.

    // Test candidate combinations until one fits.
    // Hypothetically order of checks is as follows:
    /*
    x0 y0 z0
    x1 y0 z0
    x0 y1 z0
    x0 y0 z1
    x1 y1 z1
     */
    // The assumption is that a combination can be quickly.

    // Calculate max depth for the algorithm.
    int maxLength = routeLabels.fold(
        0,
        (int max, RouteLabel routeLabel) => max =
            (routeLabel.filteredCandidates != null && routeLabel.filteredCandidates!.length > max
                ? routeLabel.filteredCandidates!.length
                : max));

    bool combinationFound = false;
    if (maxLength > 0) {
      for (int i = 0; i < maxLength; i++) {
        if (combinationFound) break;

        // Iterate every combination plus one for index j.
        for (int j = -1; j < routeLabels.length; j++) {
          if (combinationFound) break;

          List<RouteLabelCandidate?> candidateCombination = [];
          // Fill candidates for iteration.
          for (int k = 0; k < routeLabels.length; k++) {
            if (routeLabels[k].filteredCandidates!.length > i + 1) {
              candidateCombination.add(routeLabels[k].filteredCandidates![i + (k == j ? 1 : 0)]);
            } else {
              // Add last candidate.
              if (routeLabels[k].filteredCandidates!.isNotEmpty) {
                candidateCombination
                    .add(routeLabels[k].filteredCandidates![routeLabels[k].filteredCandidates!.length - 1]);
              } else {
                // No candidate found.
                candidateCombination.add(null);
              }
            }
          }
          // Candidate list complete for this iteration.

          // If candidate list contains only one element, just pick one.
          // This can happen, when the second route is not visible.

          if (candidateCombination.length < 2) {
            // Has to be not null if only one element is set as candidate combination.
            routeLabels[0].screenCoordinateX = candidateCombination[0]!.screenCoordinate.x;
            routeLabels[0].screenCoordinateY = candidateCombination[0]!.screenCoordinate.y;
            routeLabels[0].routeLabelOrientationVertical =
                candidateCombination[0]!.possibleBoxes[0].routeLabelOrientationVertical;
            routeLabels[0].routeLabelOrientationHorizontal =
                candidateCombination[0]!.possibleBoxes[0].routeLabelOrientationHorizontal;
            updatedRouteLabels.add(routeLabels[0]);
            combinationFound = true;
          }

          // Test combination with all label options and break when first combination fits.
          // Reset new route label.
          // Checks combinations and return true, if combination is found.

          // Get orientation combinations
          List<RouteLabelBox?> foundCombination =
              _findCombinationOrientations(candidateCombination[0], candidateCombination.slice(1), []);

          // Stop searching and update route labels.
          if (foundCombination.isNotEmpty) {
            // Update route labels.
            for (int i = 0; i < foundCombination.length; i++) {
              routeLabels[i].screenCoordinateX = foundCombination[i]?.x;
              routeLabels[i].screenCoordinateY = foundCombination[i]?.y;
              routeLabels[i].routeLabelOrientationVertical = foundCombination[i]?.routeLabelOrientationVertical;
              routeLabels[i].routeLabelOrientationHorizontal = foundCombination[i]?.routeLabelOrientationHorizontal;
              updatedRouteLabels.add(routeLabels[i]);
            }
            combinationFound = true;
          }
        }
      }
    } else {
      // no filtered route labels.
      for (RouteLabel routeLabel in routeLabels) {
        routeLabel.screenCoordinateX = null;
        routeLabel.screenCoordinateY = null;
        routeLabel.routeLabelOrientationVertical = null;
        routeLabel.routeLabelOrientationHorizontal = null;
        updatedRouteLabels.add(routeLabel);
      }
    }

    // Update route labels list.
    setState(() {
      routeLabels = updatedRouteLabels;
    });
  }

  // returns max 4 to the power of combinations. (which are max 2 currently so max 16 elements)
  List<RouteLabelBox?> _findCombinationOrientations(RouteLabelCandidate? routeLabelCandidate,
      List<RouteLabelCandidate?> leftCandidates, List<RouteLabelBox?> routeLabelBoxList) {
    // End reached. Check combination.
    if (leftCandidates.isEmpty) {
      if (routeLabelCandidate == null) {
        routeLabelBoxList.add(null);
        return routeLabelBoxList;
      } else {
        for (RouteLabelBox routeLabelBox in routeLabelCandidate.possibleBoxes) {
          // Add the current orientation.
          routeLabelBoxList.add(routeLabelBox);
          // Recursive call of this function to go through the possible orientations.
          if (!_doesOrientationCombinationIntersect(routeLabelBoxList)) {
            // Return route label box list on first fit.
            return routeLabelBoxList;
          }
        }
      }

      // Return empty list.
      return [];
    }

    if (routeLabelCandidate == null) {
      routeLabelBoxList.add(null);

      List<RouteLabelBox?> workingRouteLabelBox =
          _findCombinationOrientations(leftCandidates[0], leftCandidates.slice(1), routeLabelBoxList);

      // Returns the working orientation back to the first call of the function.
      if (workingRouteLabelBox.isNotEmpty) {
        return workingRouteLabelBox;
      }
    } else {
      for (RouteLabelBox routeLabelBox in routeLabelCandidate.possibleBoxes) {
        // Add the current orientation.
        routeLabelBoxList.add(routeLabelBox);
        // Recursive call of this function to go through the possible orientations.
        List<RouteLabelBox?> workingRouteLabelBox =
            _findCombinationOrientations(leftCandidates[0], leftCandidates.slice(1), routeLabelBoxList);

        // Returns the working orientation back to the first call of the function.
        if (workingRouteLabelBox.isNotEmpty) {
          return workingRouteLabelBox;
        }
      }
    }
    return [];
  }

  // Checks for a given list of orientations and candidates if the geometrically do not intersect.
  bool _doesOrientationCombinationIntersect(List<RouteLabelBox?> routeLabelBoxCombination) {
    // Does not intersect since only one element.
    if (routeLabelBoxCombination.length < 2) return false;

    RouteLabelBox? currentRouteLabelBox = routeLabelBoxCombination[0];
    List<RouteLabelBox?> leftRouteLabelBoxes = routeLabelBoxCombination.slice(1);

    // Compare each route label box.
    for (RouteLabelBox? routeLabelBox in leftRouteLabelBoxes) {
      // Compare and return true if intersect.
      // Return nothing if not intersect.

      if (_doRouteLabelBoxesIntersect(currentRouteLabelBox, routeLabelBox)) {
        return true;
      }
    }

    return _doesOrientationCombinationIntersect(leftRouteLabelBoxes);
  }

  /// Checks if two route label boxes intersect.
  _doRouteLabelBoxesIntersect(RouteLabelBox? routeLabelBox1, RouteLabelBox? routeLabelBox2) {
    // Return false if one box is null since no route label will be shown.
    if (routeLabelBox1 == null || routeLabelBox2 == null) return false;

    // Check if one of the four corners of box 2 is inside box1.
    late double xMin;
    late double xMax;
    late double yMin;
    late double yMax;

    if (routeLabelBox1.width > 0) {
      xMin = routeLabelBox1.x;
      xMax = routeLabelBox1.x + routeLabelBox1.width;
    } else {
      xMin = routeLabelBox1.x + routeLabelBox1.width;
      xMax = routeLabelBox1.x;
    }

    if (routeLabelBox1.height > 0) {
      yMin = routeLabelBox1.y;
      yMax = routeLabelBox1.y + routeLabelBox1.width;
    } else {
      yMin = routeLabelBox1.y + routeLabelBox1.width;
      yMax = routeLabelBox1.y;
    }

    // Test if one of the four corners of the route label box 2 is inside route label box 1.
    // corner 1.
    if (routeLabelBox2.x > xMin && routeLabelBox2.x < xMax && routeLabelBox2.y > yMin && routeLabelBox2.y < yMax) {
      return true;
    }
    // corner 2.
    if (routeLabelBox2.x + routeLabelBox2.width > xMin &&
        routeLabelBox2.x + routeLabelBox2.width < xMax &&
        routeLabelBox2.y > yMin &&
        routeLabelBox2.y < yMax) {
      return true;
    }
    // corner 3.
    if (routeLabelBox2.x > xMin &&
        routeLabelBox2.x < xMax &&
        routeLabelBox2.y + routeLabelBox2.height > yMin &&
        routeLabelBox2.y + routeLabelBox2.height < yMax) {
      return true;
    }
    // corner 4.
    if (routeLabelBox2.x + routeLabelBox2.width > xMin &&
        routeLabelBox2.x + routeLabelBox2.width < xMax &&
        routeLabelBox2.y + routeLabelBox2.height > yMin &&
        routeLabelBox2.y + routeLabelBox2.height < yMax) {
      return true;
    }

    // Do not intersect.
    return false;
  }

  /// Returns possible route label boxes that do not intersect with any route segment.
  List<RouteLabelBox> _getPossibleRouteLabelBoxes(
      ScreenCoordinate candidate, List<List<ScreenCoordinate>> allCoordinates) {
    bool topLeftIntersects = false;
    bool topRightIntersects = false;
    bool bottomLeftIntersects = false;
    bool bottomRightIntersects = false;

    // Check if route label would be out of screen for each position.
    if (candidate.x + routeLabelBoxWidth > widthMid * 2) {
      topLeftIntersects = true;
      bottomLeftIntersects = true;
    }
    if (candidate.x - routeLabelBoxWidth < 0) {
      topRightIntersects = true;
      bottomRightIntersects = true;
    }
    if (candidate.y + routeLabelBoxHeight > heightMid * 2) {}
    if (candidate.y - routeLabelBoxHeight < 0) {
      bottomLeftIntersects = true;
      bottomRightIntersects = true;
    }

    // Add a small offset accordingly to prevent filtering good candidates.
    double pointOffset = RouteLabelIcon.cornerMargin * 0.05;

    // Top left box.
    RouteLabelBox topLeftBox = RouteLabelBox(candidate.x + pointOffset, candidate.y + pointOffset, routeLabelBoxWidth,
        routeLabelBoxHeight, RouteLabelOrientationVertical.top, RouteLabelOrientationHorizontal.left);

    // Top right box.
    RouteLabelBox topRightBox = RouteLabelBox(candidate.x - pointOffset, candidate.y + pointOffset, -routeLabelBoxWidth,
        routeLabelBoxHeight, RouteLabelOrientationVertical.top, RouteLabelOrientationHorizontal.right);

    // Bottom left box.
    RouteLabelBox bottomLeftBox = RouteLabelBox(
        candidate.x + pointOffset,
        candidate.y - pointOffset,
        routeLabelBoxWidth,
        -routeLabelBoxHeight,
        RouteLabelOrientationVertical.bottom,
        RouteLabelOrientationHorizontal.left);

    // Bottom right box.
    RouteLabelBox bottomRightBox = RouteLabelBox(
        candidate.x - pointOffset,
        candidate.y - pointOffset,
        -routeLabelBoxWidth,
        -routeLabelBoxHeight,
        RouteLabelOrientationVertical.bottom,
        RouteLabelOrientationHorizontal.right);

    // The first end second coordinate of a segment.
    ScreenCoordinate? first;
    ScreenCoordinate? second;

    // Check all Coordinates of each route.
    for (List<ScreenCoordinate> screenCoordinateRoute in allCoordinates) {
      // Go through screen coordinates of route.
      for (ScreenCoordinate screenCoordinate in screenCoordinateRoute) {
        // All position intersect remove skip candidate.
        if (topLeftIntersects && topRightIntersects && bottomLeftIntersects && bottomRightIntersects) break;

        // Set second to the next coordinate.
        second = screenCoordinate;

        if (first != null) {
          // Top left.
          // Check top left if we haven't found one yet.
          if (!topLeftIntersects) {
            topLeftIntersects = _checkLineIntersectsRect(
                topLeftBox.x, topLeftBox.y, topLeftBox.width, topLeftBox.height, first.x, first.y, second.x, second.y);
          }

          // Top right.
          // Check top right if we haven't found one yet.
          if (!topRightIntersects) {
            topRightIntersects = _checkLineIntersectsRect(topRightBox.x, topRightBox.y, topRightBox.width,
                topRightBox.height, first.x, first.y, second.x, second.y);
          }

          // Bottom left.
          // Check bottom left if we haven't found one yet.
          if (!bottomLeftIntersects) {
            // If screen coordinate intersects with bounding box.
            bottomLeftIntersects = _checkLineIntersectsRect(bottomLeftBox.x, bottomLeftBox.y, bottomLeftBox.width,
                bottomLeftBox.height, first.x, first.y, second.x, second.y);
          }

          // Bottom right.
          // Check bottom right if we haven't found one yet.
          if (!bottomRightIntersects) {
            // If screen coordinate intersects with bounding box.
            bottomRightIntersects = _checkLineIntersectsRect(bottomRightBox.x, bottomRightBox.y, bottomRightBox.width,
                bottomRightBox.height, first.x, first.y, second.x, second.y);
          }
        }

        // Set first to the last coordinate.
        first = screenCoordinate;
      }
    }

    List<RouteLabelBox> possibleBoxes = [];

    if (!topLeftIntersects) {
      possibleBoxes.add(topLeftBox);
    }
    if (!topRightIntersects) {
      possibleBoxes.add(topRightBox);
    }
    if (!bottomLeftIntersects) {
      possibleBoxes.add(bottomLeftBox);
    }
    if (!bottomRightIntersects) {
      possibleBoxes.add(bottomRightBox);
    }

    return possibleBoxes;
  }

  // Helper function that returns a bool if a line intersects with a rect or not.
  bool _checkLineIntersectsRect(
      startXRect, startYRect, rectWidth, rectHeight, startXLine, startYLine, endXLine, endYLine) {
    // Check if line intersects with one side of the rect.
    // Side 1 (start and width).
    if (_doLinesIntersect(
        startXRect, startYRect, startXRect + rectWidth, startYRect, startXLine, startYLine, endXLine, endYLine)) {
      return true;
    }
    // Side 2 (start and height).
    if (_doLinesIntersect(
        startXRect, startYRect, startXRect, startYRect + rectHeight, startXLine, startYLine, endXLine, endYLine)) {
      return true;
    }
    // Side 3 (start + height and width).
    if (_doLinesIntersect(startXRect, startYRect + rectHeight, startXRect + rectWidth, startYRect + rectHeight,
        startXLine, startYLine, endXLine, endYLine)) {
      return true;
    }
    // Side 4 (start + width and height).
    if (_doLinesIntersect(startXRect + rectWidth, startYRect, startXRect + rectWidth, startYRect + rectHeight,
        startXLine, startYLine, endXLine, endYLine)) {
      return true;
    }

    return false;
  }

  // Helper function that checks if lines intersect.
  bool _doLinesIntersect(x1, y1, x2, y2, x3, y3, x4, y4) {
    // Calculate orientations for the line of 1 to 2 with the points 3 and 4.
    double orientation1 = _orientation(x1, y1, x2, y2, x3, y3);
    double orientation2 = _orientation(x1, y1, x2, y2, x4, y4);

    // Calculate orientations for the line 3 to 4 with points 1 and 2.
    double orientation3 = _orientation(x3, y3, x4, y4, x1, y1);
    double orientation4 = _orientation(x3, y3, x4, y4, x2, y2);

    // Orientation 1 and 2 have to be different (clockwise and anti clockwise). This makes sure that point 3 and 4 are on different side.
    // Orientation 3 and 4 have to be different (clockwise and anti clockwise). This makes sure that point 1 and 2 are on different side.
    // If these conditions are true the lines have to intersect.
    // We leave out collinear lines to simplify this step. It's an edge case we can skip.
    if ((orientation1 * orientation2 < 0) && (orientation3 * orientation4 < 0)) {
      return true;
    }
    return false;
  }

  // Helper function that calculates the orientation of three points.
  // Means if they are collinear, clockwise or anti clockwise oriented.
  // 0 means collinear, <0 means anti clockwise and >0 means clockwise.
  // Formula from:
  // https://math.stackexchange.com/questions/405966/if-i-have-three-points-is-there-an-easy-way-to-tell-if-they-are-collinear
  double _orientation(x1, y1, x2, y2, x3, y3) {
    return (y2 - y1) * (x3 - x2) - (y3 - y2) * (x2 - x1);
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
      ).toJson(),
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

    updateWaypointPixelCoordinates();

    updatePOIPopupScreenPosition();
  }

  /// A callback that is executed when the camera movement changes.
  Future<void> onMapIdle(MapIdleEventData mapIdleEventData) async {
    routeLabelLock.run(() {
      updateRouteLabels().then((value) {
        // Set map not moving.
        if (isMapMoving) {
          setState(() {
            isMapMoving = false;
          });
        }
      });
    });
  }

  /// When the user drags a waypoint.
  void _dragWaypoint() {
    if (draggedWaypoint == null || mapController == null || dragPosition == null) return;

    // check if the user dragged the waypoint to the edge of the screen
    final ScreenEdge screenEdge = getDragScreenEdge(x: dragPosition!.dx, y: dragPosition!.dy, context: context);

    if (screenEdge != ScreenEdge.none) {
      if (screenEdge != currentScreenEdge) {
        currentScreenEdge = screenEdge;
        _animateCameraScreenEdge(screenEdge);
      }
    } else {
      currentScreenEdge = ScreenEdge.none;
    }
  }

  /// Animates the map camera when the user drags a waypoint to the edge of the screen.
  Future<void> _animateCameraScreenEdge(ScreenEdge screenEdge) async {
    if (draggedWaypoint == null || mapController == null || dragPosition == null) return;

    // don't move map if the user dragged the waypoint to the cancel button
    if (_hitCancelButton()) {
      currentScreenEdge = ScreenEdge.none;
      return;
    }

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

    // Note: in the current version ease to is broken on ios devices.
    await mapController?.flyTo(
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
    if (currentScreenEdge != ScreenEdge.none && currentScreenEdge == screenEdge) {
      _animateCameraScreenEdge(screenEdge);
    }
  }

  /// Calculates the screen coordinates for a given route label.
  Future<(List<ScreenCoordinate>?, List<ScreenCoordinate>?)> getScreenCoordinates(RouteLabel routeLabel) async {
    if (mapController == null) return (null, null);

    // Store all visible unique coordinates.
    List<ScreenCoordinate> coordinates = [];
    List<ScreenCoordinate> coordinatesUniqueAndVisible = [];

    for (GHCoordinate coordinate in routing.allRoutes![routeLabel.id].path.points.coordinates) {
      // Check coordinates in screen bounds.
      ScreenCoordinate screenCoordinate = await mapController!.pixelForCoordinate(
        Point(
          coordinates: Position(coordinate.lon, coordinate.lat),
        ).toJson(),
      );

      // Add the screen coordinate to list.
      coordinates.add(screenCoordinate);

      if (routeLabel.uniqueCoordinates.contains(coordinate) && _routeLabelInScreenBounds(screenCoordinate)) {
        // Add the screen coordinate to list if visible and unique.
        coordinatesUniqueAndVisible.add(screenCoordinate);
      }
    }

    return (coordinates, coordinatesUniqueAndVisible);
  }

  /// Calculates the coordinates for the route labels.
  Future<List<ScreenCoordinate>?> getCoordinateCandidatesForRouteLabels(RouteLabel routeLabel) async {
    if (mapController == null) return null;

    // Store all visible unique coordinates.
    List<ScreenCoordinate> coordinatesVisible = [];
    for (GHCoordinate coordinate in routeLabel.uniqueCoordinates) {
      // Check coordinates in screen bounds.
      ScreenCoordinate screenCoordinate = await mapController!.pixelForCoordinate(
        Point(
          coordinates: Position(coordinate.lon, coordinate.lat),
        ).toJson(),
      );

      if (_routeLabelInScreenBounds(screenCoordinate)) {
        coordinatesVisible.add(screenCoordinate);
      }
    }

    return coordinatesVisible;
  }

  /// Returns a List of lists of unique coordinates for every route.
  /// Could be placed in Route service but since we don't always need this we can leave it here.
  List<List<GHCoordinate>> getUniqueCoordinatesPerRoute() {
    List<List<GHCoordinate>> uniqueCoordinatesLists = [];

    // Return a set of unique GHCoordinate lists.
    for (r.Route route in routing.allRoutes!) {
      List<GHCoordinate> uniqueCoordinates = [];

      // Go through all coordinates of the route and check for uniqueness.
      for (GHCoordinate coordinate in route.path.points.coordinates) {
        // Loop through all other routes except the current route.
        bool unique = true;
        for (r.Route routeToBeChecked in routing.allRoutes!) {
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
          uniqueCoordinates.add(coordinate);
        }
      }

      if (uniqueCoordinates.isNotEmpty) {
        // Use the middlemost coordinate.
        uniqueCoordinatesLists.add(uniqueCoordinates);
      }
    }

    return uniqueCoordinatesLists;
  }

  /// Move the waypoint after finish dragging
  Future<void> _moveDraggedWaypoint(BuildContext context, double dx, double dy) async {
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

  /// Check if the user dragged a waypoint to the cancel button to stop dragging
  bool _hitCancelButton() {
    if (dragPosition == null) return false;
    // The x and y position of the cancel button.
    // x: half width screen - half width button.
    // y: 270 from the bottom of the screen. Value tested with different devices.
    // (Maybe we can make this depending on the users device.)
    double cancelButtonX = MediaQuery.of(context).size.width / 2 - cancelButtonIconSize / 2;
    double cancelButtonY = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.bottom - 270;

    // the icon x and y position of the icon starts in the top left corner
    // therefore we need to add half the icon size to the x and y position to get the center of the icon
    cancelButtonX += cancelButtonIconSize;
    cancelButtonY += cancelButtonIconSize;

    if (dragPosition!.dx > cancelButtonX - cancelButtonIconSize &&
        dragPosition!.dx < cancelButtonX + cancelButtonIconSize &&
        dragPosition!.dy > cancelButtonY - cancelButtonIconSize &&
        dragPosition!.dy < cancelButtonY + cancelButtonIconSize) {
      return true;
    }
    return false;
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

  /// Returns a bool whether the given screen coordinate fits for the route label margins.
  bool _routeLabelInScreenBounds(ScreenCoordinate screenCoordinate) {
    if (screenCoordinate.x > routeLabelMarginLeft &&
        screenCoordinate.x < routeLabelMarginRight &&
        screenCoordinate.y > routeLabelMarginTop &&
        screenCoordinate.y < routeLabelMarginBottom) {
      return true;
    } else {
      return false;
    }
  }

  /// Reset variables for dragging
  void _resetDragging() {
    dragPosition = null;
    draggedWaypoint = null;
    draggedWaypointIndex = null;
    draggedWaypointType = null;
    hideDragWaypoint = false;
    currentScreenEdge = ScreenEdge.none;
    highlightCancelButton = false;
  }

  /// Set POI popup.
  Future<void> setPOIPopup() async {}

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
                _checkIfWaypointIsAtTappedPosition(x: details.localPosition.dx, y: details.localPosition.dy);

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

            highlightCancelButton = _hitCancelButton();

            _dragWaypoint();
          },
          onLongPressEnd: (details) async {
            if (draggedWaypoint != null) {
              showAuxiliaryMarking = false;
              currentScreenEdge = ScreenEdge.none;

              // Check if the user released the waypoint over the cancel button
              // if so just refresh to remove the cancel button
              // otherwise move the dragged waypoint to the new position
              final hitCancelButton = _hitCancelButton();
              if (hitCancelButton) {
                setState(() {});
              } else {
                await _moveDraggedWaypoint(context, details.localPosition.dx, details.localPosition.dy);
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
            onMapIdle: onMapIdle,
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
                left: 0,
                top: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.bottom - 270,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        color: highlightCancelButton ? Theme.of(context).colorScheme.primary : Colors.grey,
                        iconSize: cancelButtonIconSize,
                        // do nothing here and handle the cancel button in onLongPressEnd
                        onPressed: () {},
                      ),
                      BoldSmall(
                        context: context,
                        textAlign: TextAlign.center,
                        text: "Abbrechen",
                      )
                    ],
                  ),
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
                child: Container(
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

        ...routeLabels.map(
          (RouteLabel routeLabel) => Positioned(
            left: routeLabel.screenCoordinateX,
            top: routeLabel.screenCoordinateY,
            child: FractionalTranslation(
              translation: Offset(
                routeLabel.routeLabelOrientationHorizontal == RouteLabelOrientationHorizontal.left ? 0 : -1,
                routeLabel.routeLabelOrientationVertical == RouteLabelOrientationVertical.top ? 0 : -1,
              ),
              child: AnimatedOpacity(
                opacity:
                    routeLabel.screenCoordinateX == null || routeLabel.screenCoordinateY == null || isMapMoving ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: GestureDetector(
                  onTap: () {
                    onPressedRouteLabel(routeLabel.id);
                  },
                  child: RouteLabelIcon(
                    routeLabel: routeLabel,
                  ),
                ),
              ),
            ),
          ),
        ),

        if (poiPopup != null)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            // Subtract half the width of the widget to center it.
            left: poiPopup!.screenCoordinateX - (MediaQuery.of(context).size.width * 0.3),
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
