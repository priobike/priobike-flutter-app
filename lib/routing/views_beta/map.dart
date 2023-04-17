import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/common/map/layers/boundary_layers.dart';
import 'package:priobike/common/map/layers/poi_layers.dart';
import 'package:priobike/common/map/layers/route_layers.dart';
import 'package:priobike/common/map/layers/sg_layers.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/map_settings.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views_beta/widgets/calculate_routing_bar_height.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/routing/models/route.dart' as r;

class RoutingMapView extends StatefulWidget {
  /// The stream that receives notifications when the bottom sheet is dragged.
  final Stream<DraggableScrollableNotification>? sheetMovement;

  /// The selected ControllerType
  final ControllerType controllerType;

  /// The bool that decides if the Route will be displayed.
  final bool withRouting;

  const RoutingMapView({required this.sheetMovement, required this.controllerType, required this.withRouting, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingMapViewState();
}

class RoutingMapViewState extends State<RoutingMapView> with TickerProviderStateMixin {
  static const viewId = "routingNew.views.map";

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

  /// The associated settings service, which is injected by the provider.
  late MapSettings mapSettings;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

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

  /// The offset for the draggable bottom sheet.
  double? bottomSheetOffset;

  /// The margins of the attribution.
  math.Point? attributionMargins;

  /// The default map insets.
  final defaultMapInsets = const EdgeInsets.only(
    top: 108,
    bottom: 120,
  );

  /// The extra distance between the bottom sheet and the attribution.
  final sheetPadding = 16.0;

  /// The current mode (dark/light).
  bool isDark = false;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    updateMap();
    setState(() {});
  }

  /// Update the map.
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
    if (routing.needsLayout[viewId] != false ||
        discomforts.needsLayout[viewId] != false ||
        status.needsLayout[viewId] != false) {
      loadRouteMapLayers();
      fitCameraToRouteBounds();
      fitCameraToLatLng();
      routing.needsLayout[viewId] = false;
      discomforts.needsLayout[viewId] = false;
      status.needsLayout[viewId] = false;
    }

    if (mapSettings.centerCameraOnUserLocation) {
      displayCurrentUserLocation();
      fitCameraToUserPosition();
      mapSettings.setCameraCenterOnUserLocation(false);
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
    mapSettings = getIt<MapSettings>();
    mapSettings.addListener(update);

    updateMap();
  }

  @override
  void dispose() {
    animationController.dispose();
    // Unbind the sheet movement listener.
    sheetMovementSubscription?.cancel();
    layers.removeListener(update);
    mapDesigns.removeListener(update);
    positioning.removeListener(update);
    routing.removeListener(update);
    discomforts.removeListener(update);
    status.removeListener(update);
    mapSettings.removeListener(update);
    super.dispose();
  }

  /// Fit the camera to the current user position.
  fitCameraToUserPosition() async {
    if (mapController == null || !mounted) return;
    await mapController?.flyTo(
      CameraOptions(
        center: Point(
            coordinates: Position(
          positioning.lastPosition!.longitude,
          positioning.lastPosition!.latitude,
        )).toJson(),
        zoom: 15,
        pitch: 0,
        bearing: 0,
      ),
      MapAnimationOptions(duration: 1000),
    );
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
    MbxEdgeInsets insets = MbxEdgeInsets(
        // Top routingBar * devicePixelRatio (needed).
        top: calculateRoutingBarHeight(frame, routing.selectedWaypoints?.length ?? 0, true, routing.minimized) *
            frame.devicePixelRatio,
        left: 0,
        // Standard height of bottomSheet * devicePixelRatio (needed).
        bottom: 0.175 * frame.size.height * frame.devicePixelRatio,
        right: 0);
    if (Platform.isIOS) {
      insets.top = insets.top * 0.4;
      insets.bottom = insets.bottom * 0.2;
    }
    final cameraOptionsForBounds = await mapController?.cameraForCoordinateBounds(
      routing.selectedRoute!.paddedBounds,
      // Setting the Padding for the overlaying UI elements.
      insets,
      currentCameraOptions.bearing,
      currentCameraOptions.pitch,
    );
    await mapController?.flyTo(
      cameraOptionsForBounds!,
      MapAnimationOptions(duration: 1000),
    );
  }

  /// Fit the camera to the current waypoint.
  fitCameraToLatLng() async {
    if (mapController == null || !mounted) return;
    // FIXME with changenotifier at some point this condition needs to be adapted.
    // if (routing.selectedRoute == null || mapboxMapController?.isCameraMoving != false) return;
    if (routing.selectedWaypoints == null) return;
    if (routing.selectedWaypoints!.length == 1) {
      // The delay is necessary, otherwise sometimes the camera won't move.
      await Future.delayed(const Duration(milliseconds: 750));
      await mapController?.flyTo(
        CameraOptions(
          center: Point(
              coordinates: Position(
            routing.selectedWaypoints![0].lon,
            routing.selectedWaypoints![0].lat,
          )).toJson(),
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
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
        mapController!.style.updateLayer(
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

  /// Load the map desgin.
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
      BikeAirStationLayer(isDark).install(mapController!);
    } else {
      BikeAirStationLayer.remove(mapController!);
    }
    if (layers.showConstructionSites) {
      ConstructionSitesLayer(isDark).install(mapController!);
    } else {
      ConstructionSitesLayer.remove(mapController!);
    }
    if (layers.showParkingStations) {
      ParkingStationsLayer(isDark).install(mapController!);
    } else {
      ParkingStationsLayer.remove(mapController!);
    }
    if (layers.showRentalStations) {
      RentalStationsLayer(isDark).install(mapController!);
    } else {
      RentalStationsLayer.remove(mapController!);
    }
    if (layers.showRepairStations) {
      BikeShopLayer(isDark).install(mapController!);
    } else {
      BikeShopLayer.remove(mapController!);
    }
    if (layers.showAccidentHotspots) {
      AccidentHotspotsLayer(isDark).install(mapController!);
    } else {
      AccidentHotspotsLayer.remove(mapController!);
    }
  }

  /// Update all map layers.
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
    List<Map> chosenCoordinates = await getChosenCoordinates(mapController!);
    await RouteLabelLayer(chosenCoordinates).install(mapController!, iconSize: ppi / 7, textSize: ppi * 5);
  }

  /// A callback that is called when the user taps a feature.
  onFeatureTapped(QueriedFeature queriedFeature) async {
    if (!widget.withRouting) return;
    // Map the id of the layer to the corresponding feature.
    final id = queriedFeature.feature['id'];
    if ((id as String).startsWith("route-")) {
      final routeIdx = int.tryParse(id.split("-")[1]);
      if (routeIdx == null) return;
      routing.switchToRoute(routeIdx);
      discomforts.unselectDiscomfort();
      discomforts.unselectTrafficLight();
    } else if (id.startsWith("discomfort-")) {
      final discomfortIdx = int.tryParse(id.split("-")[1]);
      if (discomfortIdx == null) return;
      discomforts.selectDiscomfort(discomfortIdx);
    } else if (id.startsWith("traffic-light")) {
      discomforts.selectTrafficLight();
      discomforts.unselectDiscomfort();
    } else if (id.startsWith("routeLabel")) {
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

    final ppi = frame.devicePixelRatio;
    final sheetHeightAbs = frame.padding.bottom + sheetPadding;

    final attributionMargins = math.Point(20 * ppi, sheetHeightAbs * ppi);
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
  Future<void> onMapCreated(MapboxMap controller) async {
    switch (widget.controllerType) {
      case ControllerType.main:
        mapSettings.controller = controller;
        break;
      case ControllerType.selectOnMap:
        mapSettings.controllerSelectOnMap = controller;
        break;
    }

    mapController = controller;
  }

  /// A callback which is executed when the map style was (re-)loaded.
  onStyleLoaded(StyleLoadedEventData styleLoadedEventData) async {
    if (mapController == null || !mounted) return;

    displayCurrentUserLocation();

    // Load all symbols that will be displayed on the map.
    await SymbolLoader(mapController!).loadSymbols();

    // Fit the content below the top and the bottom stuff.
    fitAttributionPosition();

    // Load the boundary layer.
    await BoundaryLayer(isDark).install(mapController!);

    fitCameraToRouteBounds();
    loadGeoLayers();
    loadRouteMapLayers();
  }

  /// A callback that is executed when the map was longclicked.
  onMapLongClick(BuildContext context, double x, double y) async {
    if (!widget.withRouting) return;
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
        layerIds: [
          'routes-layer',
          'discomforts-layer',
          'traffic-lights-icons',
          'offline-crossings-icons',
          'routeLabels-clicklayer'
        ],
      ),
    );

    if (features.isNotEmpty) {
      onFeatureTapped(features[0]!);
    } else {
      if (!widget.withRouting) return;
      if (discomforts.selectedDiscomfort != null) {
        discomforts.unselectDiscomfort();
      }
      if (discomforts.trafficLightClicked) discomforts.unselectTrafficLight();
    }
  }

  /// A callback that is executed when the camera movement changes.
  Future<void> onCameraChanged(CameraChangedEventData cameraChangedEventData) async {}

  Future<List<Map>> getChosenCoordinates(MapboxMap mapController) async {
    // Chosen coordinates and feature object.
    List<Map> chosenCoordinates = [];

    // Search appropriate Point in Route
    for (r.Route route in routing.allRoutes!) {
      GHCoordinate? chosenCoordinate;
      List<GHCoordinate> uniqueInBounceCoordinates = [];

      // go through all coordinates.
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
          ScreenCoordinate screenCoordinate = await mapController.pixelForCoordinate({
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

  /// A callback that is executed when the camera movement of the user stopped.
  Future<void> onCameraIdle(MapIdleEventData mapIdleEventData) async {
    // Check if the route labels have to be positionally adjusted.
    if (mapController != null && !(await mapController!.isUserAnimationInProgress())) {
      // Check if changes are needed.
      if (routing.allRoutes != null && routing.allRoutes!.length == 2 && routing.selectedRoute != null) {
        bool allInBounds = true;
        // Check if current route labels are in bounds still.
        if (routing.routeLabelCoordinates.isNotEmpty) {
          for (Map data in routing.routeLabelCoordinates) {
            // Check out of new bounds.
            ScreenCoordinate screenCoordinate = await mapController!.pixelForCoordinate({
              "coordinates": [data["coordinate"].lon, data["coordinate"].lat]
            });
            if (screenCoordinate.x == -1 || screenCoordinate.y == -1) {
              allInBounds = false;
            }
          }
        } else {
          allInBounds = false;
        }
        if (!allInBounds) {
          // Calculate Chosen Coordinates
          List<Map> chosenCoordinates = await getChosenCoordinates(mapController!);
          await (RouteLabelLayer(chosenCoordinates)).update(mapController!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onMapTap: onMapTap,
            onStyleLoaded: onStyleLoaded,
            onCameraChanged: onCameraChanged,
            onCameraIdle: onCameraIdle,
            // On iOS, the logoViewMargins and attributionButtonMargins will be set by
            // updateContentInsets. This is why we set them to 0 here.
            logoViewMargins: attributionMargins,
            logoViewOrnamentPosition: OrnamentPosition.BOTTOM_LEFT,
            attributionButtonMargins: attributionMargins,
            attributionButtonOrnamentPosition: OrnamentPosition.BOTTOM_RIGHT,
          ),
        ),

        // Show an animation when the user taps the map.
        if (tapPosition != null && widget.withRouting)
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
