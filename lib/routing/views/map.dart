import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:priobike/common/map/layers/poi_layers.dart';
import 'package:priobike/common/map/layers/route_layers.dart';
import 'package:priobike/common/map/layers/sg_layers.dart';
import 'package:priobike/common/map/symbols.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/map_settings.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';
import 'package:turf/helpers.dart' as turf;

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

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  /// The associated mapController service, which is injected by the provider.
  late MapSettings mapSettings;

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

  /// The margins of the attribution.
  Point? attributionMargins;

  /// The default map insets.
  final defaultMapInsets = const EdgeInsets.only(
    top: 108,
    bottom: 130,
  );

  /// The extra distance between the bottom sheet and the attribution.
  final sheetPadding = 16.0;

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
  }

  @override
  void didChangeDependencies() {
    // Check if the selected map layers have changed.
    layers = Provider.of<Layers>(context);
    if (layers.needsLayout[viewId] != false) {
      loadGeoLayers();
      loadMapDesign();
      layers.needsLayout[viewId] = false;
    }

    // Check if the position has changed.
    positioning = Provider.of<Positioning>(context);
    if (positioning.needsLayout[viewId] != false) {
      displayCurrentUserLocation();
      positioning.needsLayout[viewId] = false;
    }

    // Check if route-related stuff has changed.
    routing = Provider.of<Routing>(context);
    if (routing.needsLayout[viewId] != false) {
      loadRouteMapLayers(); // Update all layers to keep them in z-order.
      fitCameraToRouteBounds();
      routing.needsLayout[viewId] = false;
    }

    // Check if the discomforts have changed.
    discomforts = Provider.of<Discomforts>(context);
    if (discomforts.needsLayout[viewId] != false) {
      loadRouteMapLayers(); // Update all layers to keep them in z-order.
      discomforts.needsLayout[viewId] = false;
    }

    // Check if the status has changed.
    status = Provider.of<PredictionSGStatus>(context);
    if (status.needsLayout[viewId] != false) {
      loadRouteMapLayers(); // Update all layers to keep them in z-order.
      status.needsLayout[viewId] = false;
    }

    mapSettings = Provider.of<MapSettings>(context);

    super.didChangeDependencies();
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
          ? layers.mapDesign.lightStyle
          : layers.mapDesign.darkStyle,
    );
  }

  /// Load the map layers.
  loadGeoLayers() async {
    if (mapController == null || !mounted) return;
    // Load the map features.
    if (layers.showAirStations) {
      if (!mounted) return;
      await BikeAirStationLayer(context).install(mapController!);
    } else {
      if (!mounted) return;
      await BikeAirStationLayer(context).remove(mapController!);
    }
    if (layers.showConstructionSites) {
      if (!mounted) return;
      await ConstructionSitesLayer(context).install(mapController!);
    } else {
      if (!mounted) return;
      await ConstructionSitesLayer(context).remove(mapController!);
    }
    if (layers.showParkingStations) {
      if (!mounted) return;
      await ParkingStationsLayer(context).install(mapController!);
    } else {
      if (!mounted) return;
      await ParkingStationsLayer(context).remove(mapController!);
    }
    if (layers.showRentalStations) {
      if (!mounted) return;
      await RentalStationsLayer(context).install(mapController!);
    } else {
      if (!mounted) return;
      await RentalStationsLayer(context).remove(mapController!);
    }
    if (layers.showRepairStations) {
      if (!mounted) return;
      await BikeShopLayer(context).install(mapController!);
    } else {
      if (!mounted) return;
      await BikeShopLayer(context).remove(mapController!);
    }
    if (layers.showAccidentHotspots) {
      if (!mounted) return;
      await AccidentHotspotsLayer(context).install(mapController!);
    } else {
      if (!mounted) return;
      await AccidentHotspotsLayer(context).remove(mapController!);
    }
  }

  /// Update all map layers.
  loadRouteMapLayers() async {
    if (mapController == null) return;
    final ppi = MediaQuery.of(context).devicePixelRatio;

    if (!mounted) return;
    final offlineCrossings = await OfflineCrossingsLayer(context).install(
      mapController!,
      iconSize: ppi / 5,
    );
    if (!mounted) return;
    final trafficLights = await TrafficLightsLayer(context).install(
      mapController!,
      iconSize: ppi / 5,
      below: offlineCrossings,
    );
    if (!mounted) return;
    final waypoints = await WaypointsLayer(context).install(
      mapController!,
      iconSize: 0.2,
      below: trafficLights,
    );
    if (!mounted) return;
    final discomforts = await DiscomfortsLayer(context).install(
      mapController!,
      iconSize: ppi / 8,
      below: waypoints,
    );
    if (!mounted) return;
    final selectedRoute = await SelectedRouteLayer(context).install(
      mapController!,
      below: discomforts,
    );
    if (!mounted) return;
    await AllRoutesLayer(context).install(
      mapController!,
      below: selectedRoute,
    );
  }

  /// A callback that is called when the user taps a feature.
  onFeatureTapped(QueriedFeature queriedFeature) async {
    // Map the id of the layer to the corresponding feature.
    final id = queriedFeature.feature['id'];
    if ((id as String).startsWith("route-")) {
      final routeIdx = int.tryParse(id.split("-")[1]);
      if (routeIdx == null) return;
      routing.switchToRoute(context, routeIdx);
    } else if (id.startsWith("discomfort-")) {
      final discomfortIdx = int.tryParse(id.split("-")[1]);
      if (discomfortIdx == null) return;
      discomforts.selectDiscomfort(discomfortIdx);
    }
  }

  /// Fit the attribution position to the position of the bottom sheet.
  fitAttributionPosition({double? sheetHeightRelative}) {
    final frame = MediaQuery.of(context);
    final sheetHeightAbs = sheetHeightRelative == null
        ? 124 + frame.padding.bottom + sheetPadding // Default value.
        : sheetHeightRelative * frame.size.height + sheetPadding;
    final maxBottomInset = frame.size.height - frame.padding.top - 100;
    double newBottomInset = min(maxBottomInset, sheetHeightAbs);
    mapController!.setCamera(
      CameraOptions(
        padding: MbxEdgeInsets(
            bottom: newBottomInset,
            left: defaultMapInsets.left,
            top: defaultMapInsets.top,
            right: defaultMapInsets.left),
      ),
    );
    setState(
      () {
        final ppi = frame.devicePixelRatio;
        attributionMargins =
            Point(20 * ppi, 124 / frame.size.height + (frame.padding.bottom / frame.size.height) + 130 * ppi);
      },
    );
  }

  /// A callback which is executed when the map was created.
  onMapCreated(MapboxMap controller) async {
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

    fitCameraToRouteBounds();
    loadGeoLayers();
    loadRouteMapLayers();
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
      turf.Point(
        coordinates: turf.Position(
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
        layerIds: ['routes-layer', 'discomforts-layer'],
      ),
    );

    if (features.isNotEmpty) {
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
    final geocoding = Provider.of<Geocoding>(context, listen: false);
    String fallback = "Wegpunkt ${(routing.selectedWaypoints?.length ?? 0) + 1}";
    final pointCoord = turf.Point.fromJson(Map<String, dynamic>.from(coord));
    final longitude = pointCoord.coordinates.lng.toDouble();
    final latitude = pointCoord.coordinates.lat.toDouble();
    final coordLatLng = LatLng(latitude, longitude);
    String address = await geocoding.reverseGeocode(context, coordLatLng) ?? fallback;
    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) {
      await routing.addWaypoint(Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude));
    }
    await routing.addWaypoint(Waypoint(latitude, longitude, address: address));
    await routing.loadRoutes(context);
  }

  @override
  void dispose() {
    animationController.dispose();
    // Unbind the sheet movement listener.
    sheetMovementSubscription?.cancel();
    super.dispose();
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
            onStyleLoaded: onStyleLoaded,
            onMapTap: onMapTap,
            // On iOS, the logoViewMargins and attributionButtonMargins will be set by
            // updateContentInsets. This is why we set them to 0 here.
            logoViewMargins: attributionMargins,
            logoViewOrnamentPosition: OrnamentPosition.BOTTOM_LEFT,
            attributionButtonMargins: attributionMargins,
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
                    opacity: max(0, min(1, (animation.value) * 4)),
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
                    opacity: max(0, (animation.value - 0.5) * 2),
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
                  top: min(12 + tapPosition!.dy - 256 + 256 * max(0, (animation.value - 0.25) * 4 / 3),
                          tapPosition!.dy) -
                      12,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Opacity(
                      opacity: max(0, (animation.value - 0.5) * 2),
                      child: Image.asset(
                        'assets/images/pin.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: tapPosition!.dx - 12,
                  top: (tapPosition!.dy - 256 + 256 * max(0, (animation.value - 0.25) * 4 / 3)) - 12,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Opacity(
                      opacity: max(0, (animation.value - 0.5) * 2),
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
