import 'dart:async';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/bottom_sheet_state.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/map_settings.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/layers.dart';
import 'package:priobike/routing/views_beta/bottom_sheet.dart';
import 'package:priobike/routing/views_beta/map.dart';
import 'package:priobike/routing/views_beta/route_search.dart';
import 'package:priobike/routing/views_beta/search.dart';
import 'package:priobike/routing/views_beta/widgets/alerts.dart';
import 'package:priobike/routing/views_beta/widgets/calculate_routing_bar_height.dart';
import 'package:priobike/routing/views_beta/widgets/compass_button.dart';
import 'package:priobike/routing/views_beta/widgets/filter_button.dart';
import 'package:priobike/routing/views_beta/widgets/gps_button.dart';
import 'package:priobike/routing/views_beta/widgets/layer_button.dart';
import 'package:priobike/routing/views_beta/widgets/routing_bar.dart';
import 'package:priobike/routing/views_beta/widgets/search_bar.dart';
import 'package:priobike/routing/views_beta/widgets/shortcuts.dart';
import 'package:priobike/routing/views_beta/widgets/zoom_in_and_out_button.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoutingViewNew extends StatefulWidget {
  const RoutingViewNew({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingViewNewState();
}

class RoutingViewNewState extends State<RoutingViewNew> {
  /// The associated geocoding service, which is injected by the provider.
  late Geocoding geocoding;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The associated shortcuts service, which is injected by the provider.
  late MapSettings mapSettings;

  /// The associated shortcuts service, which is injected by the provider.
  late Profile profile;

  /// The associated BottomSheetState, which is injected by the provider.
  late BottomSheetState bottomSheetState;

  /// The associated Discomfort, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated layers service, which is injected by the provider.
  late Layers layers;

  /// The stream that receives notifications when the bottom sheet is dragged.
  final sheetMovement = StreamController<DraggableScrollableNotification>();

  /// The threshold for the location accuracy in meter
  final int locationAccuracyThreshold = 20;

  /// The attribute which holds the state of which the RoutingBar has to be displayed.
  bool showRoutingBar = true;

  /// The attribute which holds the state of which the route was centered top.
  bool fitCameraTop = false;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        await routing.loadRoutes(context);
        await Provider.of<Places>(context, listen: false).loadPlaces(context);
        // To place the mapbox logo correct when shortcut selected in home screen.
        sheetMovement.add(DraggableScrollableNotification(
            minExtent: 0, context: context, extent: 0.18, initialExtent: 0.2, maxExtent: 0.2));

        // Calling requestSingleLocation function to fill lastPosition of PositionService
        await positioning.requestSingleLocation(context);
        // Checking threshold for location accuracy
        if (positioning.lastPosition?.accuracy != null &&
            positioning.lastPosition!.accuracy >= locationAccuracyThreshold) {
          _showAlertGPSQualityDialog();
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    geocoding = Provider.of<Geocoding>(context);
    routing = Provider.of<Routing>(context);
    shortcuts = Provider.of<Shortcuts>(context);
    mapSettings = Provider.of<MapSettings>(context);
    profile = Provider.of<Profile>(context);
    positioning = Provider.of<Positioning>(context);
    bottomSheetState = Provider.of<BottomSheetState>(context);
    discomforts = Provider.of<Discomforts>(context);
    layers = Provider.of<Layers>(context);

    _checkRoutingBarShown();

    super.didChangeDependencies();
  }

  /// Function which checks if the RoutingBar needs to be shown.
  _checkRoutingBarShown() async {
    // This seems not to work somehow
    if (routing.selectedWaypoints != null && routing.selectedWaypoints!.isNotEmpty && mapSettings.controller != null) {
      await mapSettings.controller!.setCamera(
        mapbox.CameraOptions(
          padding: mapbox.MbxEdgeInsets(bottom: 120, left: 0, top: 150, right: 0),
        ),
      );
    }
  }

  /// A callback that is fired when the ride is started.
  Future<void> onStartRide() async {
    HapticFeedback.heavyImpact();

    void startRide() => Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const RideView(),
          ),
        );

    final preferences = await SharedPreferences.getInstance();
    final didViewWarning = preferences.getBool("priobike.routingNew.warning") ?? false;
    if (didViewWarning) {
      startRide();
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          alignment: AlignmentDirectional.center,
          actionsAlignment: MainAxisAlignment.center,
          title: BoldContent(
              text:
                  'Denke an deine Sicherheit und achte stets auf deine Umgebung. Beachte die Hinweisschilder und die örtlichen Gesetze.',
              context: context),
          content: Container(height: 0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                preferences.setBool("priobike.routingNew.warning", true);
                startRide();
              },
              child: BoldContent(text: 'OK', color: Theme.of(context).colorScheme.primary, context: context),
            ),
          ],
        ),
      );
    }
  }

  /// A callback that is fired when the user wants to select the displayed layers.
  void onLayerSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
      builder: (_) => const LayerSelectionView(),
    );
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Tile(
            fill: Theme.of(context).colorScheme.surface,
            content: Center(
              child: SizedBox(
                height: 86,
                width: 256,
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const VSpace(),
                    BoldContent(text: "Lade...", maxLines: 1, context: context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Render a try again button.
  Widget renderTryAgainButton() {
    final backend = Provider.of<Settings>(context, listen: false).backend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Tile(
            fill: Theme.of(context).colorScheme.surface,
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 48),
                const VSpace(),
                BoldSmall(
                  text: "Tut uns Leid, aber diese Route konnte nicht geladen werden.",
                  context: context,
                  textAlign: TextAlign.center,
                ),
                const SmallVSpace(),
                Small(
                  text:
                      "Achte darauf, dass du mit dem Internet verbunden bist. Das Routing wird aktuell nur innerhalb von ${backend.region} unterstützt. Bitte passe deine Wegpunkte an oder versuche es später noch einmal.",
                  context: context,
                  textAlign: TextAlign.center,
                ),
                const VSpace(),
                BigButton(
                  label: "Erneut versuchen",
                  onPressed: () async {
                    await routing.loadRoutes(context);
                  },
                ),
                // Move the button a bit more up.
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Alert dialog for location accuracy
  void _showAlertGPSQualityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: BoldSubHeader(text: 'Achtung!', context: context),
          content: Content(
            text:
                'Deine GPS-Position scheint ungenau zu sein. Solltest du während der Fahrt Probleme mit der Ortung feststellen, prüfe deine Energiespareinstellungen oder erlaube die genaue Positionsbestimmung.',
            context: context,
          ),
          actions: <Widget>[
            TextButton(
              child: Content(
                text: 'Okay',
                context: context,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  /// Private ZoomIn Function which calls mapControllerService
  void _zoomIn() {
    mapSettings.zoomIn(ControllerType.main);
  }

  /// Private ZoomOut Function which calls mapControllerService
  void _zoomOut() {
    mapSettings.zoomOut(ControllerType.main);
  }

  /// Private GPS Centralization Function which calls mapControllerService
  void _gpsCentralization() {
    mapSettings.setCameraCenterOnUserLocation(true);
  }

  /// Private Function which is executed when FAB is pressed.
  Future<void> _startRoutingSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteSearchView(
          onPressed: _loadShortcutsRoute,
          sheetMovement: sheetMovement,
        ),
      ),
    );
    if (routing.selectedWaypoints != null && routing.selectedWaypoints!.isNotEmpty) {
      await routing.loadRoutes(context);
      // Minimize view when coming from extra search page.
      routing.setMinimized();
      // Set the mapbox logo.
      sheetMovement.add(DraggableScrollableNotification(
          minExtent: 0, context: context, extent: 0.18, initialExtent: 0.2, maxExtent: 0.2));
    }
  }

  /// Private Function which is executed when search is executed.
  Future<void> _startSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchView(index: null, onPressed: _loadShortcutsRoute, fromRouteSearch: false),
      ),
    );

    if (routing.selectedWaypoints != null && routing.selectedWaypoints!.isNotEmpty) {
      await routing.loadRoutes(context);
      // Set the mapbox logo.
      sheetMovement.add(DraggableScrollableNotification(
          minExtent: 0, context: context, extent: 0.18, initialExtent: 0.2, maxExtent: 0.2));
    }
  }

  /// A callback that is executed when the search page is opened.
  Future<void> onSearch(Routing routing, int? index, Function onPressed, bool fromRouteSearch) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchView(index: index, onPressed: onPressed, fromRouteSearch: fromRouteSearch),
      ),
    );

    if (routing.selectedWaypoints != null && routing.selectedWaypoints!.isNotEmpty) {
      await routing.loadRoutes(context);
      // Set the mapbox logo.
      sheetMovement.add(DraggableScrollableNotification(
          minExtent: 0, context: context, extent: 0.18, initialExtent: 0.2, maxExtent: 0.2));
    }
  }

  /// Private Center North Function which calls mapControllerService
  void _centerNorth() {
    mapSettings.centerNorth(ControllerType.main);
  }

  /// ShowLessDetails moves the draggableScrollView back to the initial height
  _showLessDetails() {
    bottomSheetState.animateController(0.175);

    if (bottomSheetState.listController != null) {
      bottomSheetState.listController!.jumpTo(0);
    }
  }

  /// Function which loads Routes from shortcuts view.
  _loadShortcutsRoute(List<Waypoint> waypoints) async {
    await routing.selectWaypoints(waypoints);
    await routing.loadRoutes(context);
    // Set the mapbox logo.
    sheetMovement.add(DraggableScrollableNotification(
        minExtent: 0, context: context, extent: 0.18, initialExtent: 0.2, maxExtent: 0.2));
  }

  @override
  Widget build(BuildContext context) {
    if (routing.hadErrorDuringFetch) return renderTryAgainButton();

    final frame = MediaQuery.of(context);

    bool waypointsSelected = routing.selectedWaypoints != null && routing.selectedWaypoints!.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: WillPopScope(
        onWillPop: () async {
          final completer = Completer<bool>();
          completer.complete(true);
          // The second value in the .pop-method ("true") in that case specifies that we navigate back to
          // the home view (important for the result handler to do the right things)
          Navigator.pop(context, true);
          return completer.future;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              sheetMovement.add(notification);
              // Show routingBar when sheet is at the bottom.
              if (notification.extent <= 0.2) {
                setState(() {
                  showRoutingBar = true;
                });
                if (fitCameraTop == true) {
                  // Trigger center route in top part of screen.
                  mapSettings.fitCameraToRouteBounds(routing, frame);
                  setState(() {
                    fitCameraTop = false;
                  });
                }
              } else {
                // Hide routingBar when sheet is 60% or more.
                if (notification.extent >= 0.6 && notification.extent <= 0.7) {
                  // Trigger center route in top part of screen.
                  if (fitCameraTop == false) {
                    mapSettings.fitCameraToRouteBoundsTop(routing, frame);
                    setState(() {
                      fitCameraTop = true;
                    });
                  }
                }
                setState(() {
                  showRoutingBar = false;
                });
              }
              return false;
            },
            child: Stack(children: [
              RoutingMapView(
                sheetMovement: sheetMovement.stream,
                controllerType: ControllerType.main,
                withRouting: true,
              ),

              if (routing.isFetchingRoute) renderLoadingIndicator(),
              if (geocoding.isFetchingAddress) renderLoadingIndicator(),

              // Top Bar
              SafeArea(
                top: !(waypointsSelected),
                child: Padding(
                  padding: EdgeInsets.only(top: waypointsSelected ? 0 : 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      waypointsSelected && !routing.isFetchingRoute
                          ? SizedBox(
                              // number of Elements * 40 + Padding (2*10) + System navigation bar
                              height: frame.size.height,
                              child: Stack(clipBehavior: Clip.none, children: [
                                AnimatedPositioned(
                                  top: showRoutingBar
                                      ? 0
                                      : -calculateRoutingBarHeight(
                                          frame, routing.selectedWaypoints!.length, true, routing.minimized),
                                  duration: const Duration(milliseconds: 250),
                                  child: RoutingBar(
                                    fromRoutingSearch: false,
                                    onPressed: _loadShortcutsRoute,
                                    onSearch: onSearch,
                                    context: context,
                                    sheetMovement: sheetMovement,
                                  ),
                                ),
                                !showRoutingBar
                                    ? AnimatedPositioned(
                                        top: bottomSheetState.draggableScrollableController != null &&
                                                bottomSheetState.draggableScrollableController!.size <= 1 &&
                                                bottomSheetState.draggableScrollableController!.size >= 0.7
                                            ? 0
                                            : -(40 + 64 + frame.padding.top),
                                        left: 0,
                                        duration: const Duration(milliseconds: 250),
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.only(top: 20 + frame.padding.top, bottom: 5),
                                          color: Theme.of(context).colorScheme.background,
                                          width: frame.size.width,
                                          height: frame.padding.top + 25 + 64,
                                        ),
                                      )
                                    : Container(),
                                !showRoutingBar
                                    ? Positioned(
                                        top: 0,
                                        left: 0,
                                        child: Container(
                                          width: frame.size.width,
                                          height: frame.size.height * 0.36,
                                          color: Colors.transparent,
                                        ),
                                      )
                                    : Container(),
                                AnimatedPositioned(
                                  // top calculates from padding + systemBar.
                                  top: 20 + frame.padding.top,
                                  left: showRoutingBar ? -64 : 0,
                                  duration: const Duration(milliseconds: 250),
                                  child: AppBackButton(onPressed: _showLessDetails),
                                ),
                                AnimatedPositioned(
                                  // top calculates from padding + systemBar.
                                  top: calculateRoutingBarHeight(
                                          frame, routing.selectedWaypoints!.length, true, routing.minimized) +
                                      10,
                                  left: !showRoutingBar ||
                                          (discomforts.selectedDiscomfort == null && !discomforts.trafficLightClicked)
                                      ? -frame.size.width * 0.75
                                      : 0,
                                  duration: const Duration(milliseconds: 250),
                                  child: SizedBox(
                                    width: frame.size.width * 0.75,
                                    child: const AlertsView(),
                                  ),
                                ),
                                showRoutingBar
                                    ? AnimatedPositioned(
                                        // top calculates from padding + systemBar.
                                        top: calculateRoutingBarHeight(
                                            frame, routing.selectedWaypoints!.length, true, routing.minimized),
                                        right: 0,
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeInCubic,
                                        child: Padding(
                                          /// Align with FAB
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                            Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                                              CompassButton(centerNorth: _centerNorth),
                                              const SizedBox(height: 10),
                                              ZoomInAndOutButton(zoomIn: _zoomIn, zoomOut: _zoomOut),
                                              const SizedBox(height: 10),
                                              const FilterButton(),
                                              const SizedBox(height: 10),
                                              const LayerButton(),
                                            ]),
                                          ]),
                                        ))
                                    : Container(),
                              ]),
                            )
                          : !routing.isFetchingRoute
                              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Hero(
                                    tag: 'appBackButton',
                                    child: AppBackButton(
                                        icon: Icons.chevron_left_rounded,
                                        onPressed: () => Navigator.pop(context, true),
                                        elevation: 5),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    // Avoid expansion of alerts view.
                                    width: frame.size.width - 80,
                                    child: SearchBar(fromClicked: false, startSearch: _startSearch),
                                  ),
                                ])
                              : Container(),
                      !waypointsSelected ? ShortCutsRow(onPressed: _loadShortcutsRoute, close: false) : Container(),
                      !waypointsSelected
                          ? Padding(
                              /// Align with FAB
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                                  CompassButton(centerNorth: _centerNorth),
                                  const SizedBox(height: 10),
                                  ZoomInAndOutButton(zoomIn: _zoomIn, zoomOut: _zoomOut),
                                  const SizedBox(height: 10),
                                  const FilterButton(),
                                  const SizedBox(height: 10),
                                  const LayerButton(),
                                ]),
                              ]),
                            )
                          : Container(),
                    ],
                  ),
                ),
              ),
              waypointsSelected && !routing.isFetchingRoute
                  ? Positioned(
                      bottom: frame.size.height * BottomSheetDetailState.bottomSnapRatio + 10,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GPSButton(
                          gpsCentralization: _gpsCentralization,
                        ),
                      ),
                    )
                  : Container(),
              waypointsSelected && !routing.isFetchingRoute ? const BottomSheetDetail() : Container(),
            ]),
          ),
          floatingActionButton: routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GPSButton(gpsCentralization: _gpsCentralization),
                    const SizedBox(
                      height: 15,
                    ),
                    FloatingActionButton(
                      onPressed: () => _startRoutingSearch(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      heroTag: "fab2",
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(
                        Icons.directions,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Container(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  @override
  void dispose() {
    sheetMovement.close();
    super.dispose();
  }
}
