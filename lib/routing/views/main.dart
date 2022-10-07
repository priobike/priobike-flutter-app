import 'dart:async';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/ride/views/selection.dart';
import 'package:priobike/routing/services/bottomSheetState.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/bottomSheet.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/services/mapcontroller.dart';
import 'package:priobike/routing/views/routeSearch.dart';
import 'package:priobike/routing/views/search.dart';
import 'package:priobike/routing/views/widgets/compassButton.dart';
import 'package:priobike/routing/views/widgets/filterButton.dart';
import 'package:priobike/routing/views/widgets/gpsButton.dart';
import 'package:priobike/routing/views/widgets/routingBar.dart';
import 'package:priobike/routing/views/widgets/searchBar.dart';
import 'package:priobike/routing/views/widgets/shortcuts.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/ZoomInAndOutButton.dart';

class RoutingViewNew extends StatefulWidget {
  const RoutingViewNew({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingViewNewState();
}

class RoutingViewNewState extends State<RoutingViewNew> {
  /// The associated geocoding service, which is injected by the provider.
  late Geocoding geocoding;

  /// The associated routingOLD service, which is injected by the provider.
  late Routing routing;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The associated shortcuts service, which is injected by the provider.
  late MapController mapController;

  /// The associated shortcuts service, which is injected by the provider.
  late Profile profile;

  /// The associated BottomSheetState, which is injected by the provider.
  late BottomSheetState bottomSheetState;

  /// The stream that receives notifications when the bottom sheet is dragged.
  final sheetMovement = StreamController<DraggableScrollableNotification>();

  /// The threshold for the location accuracy in meter
  final int locationAccuracyThreshold = 20;

  bool showRoutingBar = true;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      await routing.loadRoutes(context);

      /// Calling requestSingleLocation function to fill lastPosition of PositionService
      await positioning.requestSingleLocation(context);

      /// Checking threshold for location accuracy
      if (positioning.lastPosition?.accuracy != null &&
          positioning.lastPosition!.accuracy >= locationAccuracyThreshold) {
        _showAlertGPSQualityDialog();
      }
    });
  }

  @override
  void didChangeDependencies() {
    geocoding = Provider.of<Geocoding>(context);
    routing = Provider.of<Routing>(context);
    shortcuts = Provider.of<Shortcuts>(context);
    mapController = Provider.of<MapController>(context);
    profile = Provider.of<Profile>(context);
    positioning = Provider.of<Positioning>(context);
    bottomSheetState = Provider.of<BottomSheetState>(context);

    _checkRoutingBarShown();

    super.didChangeDependencies();
  }

  _checkRoutingBarShown() {
    // This seems not to work somehow
    if (routing.selectedWaypoints != null &&
        routing.selectedWaypoints!.isNotEmpty &&
        mapController.controller != null) {
      mapController.controller!
          .updateContentInsets(const EdgeInsets.only(top: 150), true);
    }
  }

  /// A callback that is fired when the ride is started.
  Future<void> onStartRide() async {
    final settingsService = Provider.of<Settings>(context, listen: false);
    final nextView = settingsService.ridePreference == null
        ? const RideSelectionView() // Need to select a ride preference.
        : const RideView();

    void startRide() =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) {
          // Avoid navigation back, only allow stop button to be pressed.
          // Note: Don't use pushReplacement since this will call
          // the result handler of the RouteView's host.
          return WillPopScope(
            onWillPop: () async => false,
            child: nextView,
          );
        }));

    final preferences = await SharedPreferences.getInstance();
    final didViewWarning =
        preferences.getBool("priobike.routingOLD.warning") ?? false;
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
                preferences.setBool("priobike.routingOLD.warning", true);
                startRide();
              },
              child: BoldContent(
                  text: 'OK',
                  color: Theme.of(context).colorScheme.primary,
                  context: context),
            ),
          ],
        ),
      );
    }
  }

  /// A callback that is fired when the shortcut should be saved but a name is required.
  void onRequestShortcutName() {
    showDialog(
      context: context,
      builder: (_) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: BoldContent(
              text:
                  'Bitte gib einen Namen an, unter dem der Shortcut gespeichert werden soll.',
              context: context),
          content: SizedBox(
            height: 48,
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      hintText: 'Heimweg, Zur Arbeit, ...'),
                ),
              ],
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                if (name.isEmpty) {
                  ToastMessage.showError("Name darf nicht leer sein.");
                }
                await shortcuts.saveNewShortcut(name, context);
                ToastMessage.showSuccess("Route gespeichert!");
                Navigator.pop(context);
              },
              child: BoldContent(
                  text: 'Speichern',
                  color: Theme.of(context).colorScheme.primary,
                  context: context),
            ),
          ],
        );
      },
    );
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Tile(
          fill: Theme.of(context).colorScheme.background,
          content: Center(
            child: SizedBox(
              height: 86,
              width: 256,
              child: Column(children: [
                const CircularProgressIndicator(),
                const VSpace(),
                BoldContent(text: "Lade...", maxLines: 1, context: context),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  /// Render a try again button.
  Widget renderTryAgainButton() {
    return Scaffold(
      body: SafeArea(
        child: Pad(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Tile(
                  fill: Theme.of(context).colorScheme.background,
                  content: Center(
                    child: SizedBox(
                      height: 128,
                      width: 256,
                      child: Column(children: [
                        BoldContent(
                            text: "Fehler beim Laden der Route.",
                            maxLines: 1,
                            context: context),
                        const VSpace(),
                        BigButton(
                            label: "Erneut Laden",
                            onPressed: () async {
                              await routing.loadRoutes(context);
                            }),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                  'Die Qualität der Positionsbestimmung ist nicht optimal. Prüfen sie gegebenenfalls die Einstellungen des GPS für die App.',
              context: context),
          actions: <Widget>[
            TextButton(
              child: Content(
                  text: 'Okay',
                  context: context,
                  color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Private ZoomIn Function which calls mapControllerService
  void _zoomIn() {
    mapController.zoomIn(ControllerType.main);
  }

  /// Private ZoomOut Function which calls mapControllerService
  void _zoomOut() {
    mapController.zoomOut(ControllerType.main);
  }

  /// Private GPS Centralization Function which calls mapControllerService
  void _gpsCentralization() {
    mapController.setMyLocationTrackingModeTracking(ControllerType.main);
  }

  /// Private Function which is executed when FAB is pressed
  Future<void> _startRoutingSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RouteSearchView(),
      ),
    );
    if (routing.selectedWaypoints != null &&
        routing.selectedWaypoints!.isNotEmpty) {
      await routing.loadRoutes(context);
    }
  }

  /// Private Function which is executed when search is executed
  Future<void> _startSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchView(index: null),
      ),
    );

    if (routing.selectedWaypoints != null &&
        routing.selectedWaypoints!.isNotEmpty) {
      await routing.loadRoutes(context);
    }
  }

  /// Private Center North Function which calls mapControllerService
  void _centerNorth() {
    mapController.centerNorth(ControllerType.main);
  }

  _calculateRoutingBarHeight(MediaQueryData frame) {
    // case Items between 2 and 5
    if (routing.selectedWaypoints!.length >= 2 &&
        routing.selectedWaypoints!.length <= 5) {
      // routingBar items * 40 + Padding + SystemBar
      return routing.selectedWaypoints!.length * 40 +
          20 +
          frame.viewPadding.top;
    }
    // case 1 item
    if (routing.selectedWaypoints!.length == 1) {
      // 2 routingBar items (40 + 40) + Padding + SystemBar
      return 80 + 20 + frame.viewPadding.top;
    }
    // case more then 5 items
    // Max RoutingBarHeight + Padding + SystemBar
    return frame.size.height * 0.25 + 20 + frame.viewPadding.top;
  }

  /// ShowLessDetails moves the draggableScrollView back to the initial height
  _showLessDetails() {
    bottomSheetState.draggableScrollableController.animateTo(0.15,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    if (routing.hadErrorDuringFetch) return renderTryAgainButton();

    final frame = MediaQuery.of(context);

    bool waypointsSelected = routing.selectedWaypoints != null &&
        routing.selectedWaypoints!.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            sheetMovement.add(notification);
            if (notification.extent <= 0.2) {
              setState(() {
                showRoutingBar = true;
              });
            } else {
              setState(() {
                showRoutingBar = false;
              });
            }
            return false;
          },
          child: Stack(children: [
            RoutingMapView(
                sheetMovement: sheetMovement.stream,
                controllerType: ControllerType.main),

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
                    waypointsSelected
                        ? SizedBox(
                            // number of Elements * 40 + Padding (2*10) + System navigation bar
                            height: _calculateRoutingBarHeight(frame),
                            child: Stack(clipBehavior: Clip.none, children: [
                              Container(),
                              AnimatedPositioned(
                                  // top calculates from maxHeight Routingbar + padding + systembar
                                  top: showRoutingBar
                                      ? 0
                                      : -(frame.size.height * 0.25 +
                                          20 +
                                          frame.viewPadding.top),
                                  duration: const Duration(milliseconds: 250),
                                  child: const RoutingBar(
                                      fromRoutingSearch: false)),
                              !showRoutingBar
                                  ? AnimatedPositioned(
                                      top: bottomSheetState
                                                      .draggableScrollableController
                                                      .size <=
                                                  1 &&
                                              bottomSheetState
                                                      .draggableScrollableController
                                                      .size >=
                                                  0.7
                                          ? 0
                                          : -(40 + 64 + frame.padding.top),
                                      left: 0,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.only(
                                            top: 20 + frame.padding.top,
                                            bottom: 5),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        width: frame.size.width,
                                        height: frame.padding.top + 25 + 64,
                                      ),
                                    )
                                  : Container(),
                              AnimatedPositioned(
                                // top calculates from padding + systembar
                                top: 20 + frame.padding.top,
                                left: showRoutingBar ? -64 : 0,
                                duration: const Duration(milliseconds: 250),
                                child:
                                    AppBackButton(onPressed: _showLessDetails),
                              ),
                            ]),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Hero(
                                  tag: 'appBackButton',
                                  child: AppBackButton(
                                      icon: Icons.chevron_left_rounded,
                                      onPressed: () => Navigator.pop(context),
                                      elevation: 5),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  // Avoid expansion of alerts view.
                                  width: frame.size.width - 80,
                                  child: SearchBar(
                                      fromClicked: false,
                                      startSearch: _startSearch),
                                ),
                              ]),
                    !waypointsSelected ? const ShortCuts() : Container(),
                    showRoutingBar
                        ? Padding(
                            /// Align with FAB
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        CompassButton(
                                            centerNorth: _centerNorth),
                                        const SizedBox(height: 10),
                                        ZoomInAndOutButton(
                                            zoomIn: _zoomIn, zoomOut: _zoomOut),
                                        const SizedBox(height: 10),
                                        FilterButton(profileService: profile),
                                      ]),
                                ]),
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
            routing.selectedWaypoints != null &&
                    routing.selectedWaypoints!.isNotEmpty
                ? Positioned(
                    bottom: frame.size.height * 0.15 + 10,
                    right: 20,
                    child: GPSButton(gpsCentralization: _gpsCentralization),
                  )
                : Container(),
            routing.selectedWaypoints != null &&
                    routing.selectedWaypoints!.isNotEmpty
                ? const BottomSheetDetail()
                : Container(),
          ]),
        ),
        floatingActionButton: routing.selectedWaypoints == null ||
                routing.selectedWaypoints!.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GPSButton(
                      myLocationTrackingMode:
                          mapController.myLocationTrackingMode,
                      gpsCentralization: _gpsCentralization),
                  const SizedBox(
                    height: 15,
                  ),
                  FloatingActionButton(
                    onPressed: () => _startRoutingSearch(),
                    child: const Icon(
                      Icons.directions,
                      color: Colors.white,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    heroTag: "fab2",
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              )
            : Container(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  @override
  void dispose() {
    sheetMovement.close();
    super.dispose();
  }
}
