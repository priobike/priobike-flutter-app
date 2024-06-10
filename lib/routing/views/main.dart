import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/map_values.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/add_waypoint_sheet.dart';
import 'package:priobike/routing/views/details/map_legend.dart';
import 'package:priobike/routing/views/details/shortcuts.dart';
import 'package:priobike/routing/views/edit_waypoint_sheet.dart';
import 'package:priobike/routing/views/layers.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/views/profile.dart';
import 'package:priobike/routing/views/sheet.dart';
import 'package:priobike/routing/views/widgets/center_button.dart';
import 'package:priobike/routing/views/widgets/compass_button.dart';
import 'package:priobike/routing/views/widgets/routing_tutorial.dart';
import 'package:priobike/settings/models/backend.dart' hide Simulator;
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/simulator/views/simulator_state.dart';

class RoutingView extends StatefulWidget {
  const RoutingView({super.key});

  @override
  State<StatefulWidget> createState() => RoutingViewState();
}

class RoutingViewState extends State<RoutingView> {
  /// The associated geocoding service, which is injected by the provider.
  late Geocoding geocoding;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated layers service, which is injected by the provider.
  late Layers layers;

  /// The associated MapFunctions service, which is injected by the provider.
  late MapFunctions mapFunctions;

  /// The associated MapValues service, which is injected by the provider.
  late MapValues mapValues;

  /// The timer that updates the location puck position on the map.
  Timer? timer;

  /// The threshold for the location accuracy in meter
  /// NOTE: The accuracy will increase if we move and gain more GPS signal data.
  /// Hence, we don't want to set this threshold too low. The threshold should
  /// only detect exceptionally poor GPS quality (such as >1000m radius) that
  /// may be caused by energy saving options or disallowed precise geolocation.
  final int locationAccuracyThreshold = 100;

  /// If everything has loaded.
  bool hasInitiallyLoaded = false;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        // Check position permission.
        // Has to be awaited before activating the bottom sheet.
        final hasPermission = await positioning.requestGeolocatorPermission();
        if (!hasPermission) {
          if (!mounted) return;
          // Prevents skipping the home view when pressing back.
          Navigator.of(context).popUntil((route) => route.isFirst);
          showLocationAccessDeniedDialog(context, positioning.positionSource);
        }

        // Calling requestSingleLocation function to fill lastPosition of PositionService initially.
        // Does not have to be awaited since this causes a delay in the initial loading of the map for android.
        positioning.requestSingleLocation(onNoPermission: () {
          if (!mounted) return;
          // Prevents skipping the home view when pressing back.
          Navigator.of(context).popUntil((route) => route.isFirst);
          showLocationAccessDeniedDialog(context, positioning.positionSource);
        });
        // Calling requestSingleLocation function to fill lastPosition of PositionService regularly.
        // Note: using dart timer because geolocator has no options for ios to set the gps interval.
        timer = Timer.periodic(const Duration(seconds: 15), (timer) async {
          await positioning.requestSingleLocation(onNoPermission: () {
            if (!mounted) return;
            // Prevents skipping the home view when pressing back.
            Navigator.of(context).popUntil((route) => route.isFirst);
            showLocationAccessDeniedDialog(context, positioning.positionSource);
          });
          // Move screen if was centered before.
          if (mapValues.isCentered) {
            mapFunctions.setCameraCenterOnUserLocation();
          }
        });

        // Needs to be loaded after we requested the location, because we need the lastPosition if we load the route from
        // a location shortcut instead of a route shortcut.
        await routing.loadRoutes();
        // Checking threshold for location accuracy
        if (positioning.lastPosition?.accuracy != null &&
            positioning.lastPosition!.accuracy >= locationAccuracyThreshold) {
          showAlertGPSQualityDialog();
        }

        if (!mounted) return;
        setState(() {
          hasInitiallyLoaded = true;
        });
      },
    );

    geocoding = getIt<Geocoding>();
    geocoding.addListener(update);
    routing = getIt<Routing>();
    routing.addListener(update);
    shortcuts = getIt<Shortcuts>();
    shortcuts.addListener(update);
    positioning = getIt<Positioning>();
    positioning.addListener(update);
    layers = getIt<Layers>();
    layers.addListener(update);
    mapFunctions = MapFunctions();
    mapFunctions.addListener(update);
    mapValues = MapValues();
  }

  @override
  void dispose() {
    geocoding.removeListener(update);
    routing.removeListener(update);
    shortcuts.removeListener(update);
    positioning.removeListener(update);
    layers.removeListener(update);
    mapFunctions.removeListener(update);
    timer?.cancel();

    super.dispose();
  }

  /// A callback that is fired when the ride is started.
  Future<void> onStartRide() async {
    HapticFeedback.heavyImpact();

    // We need to send a result (true) to inform the result handler in the HomeView that we do not want to reset
    // the services. This is only wanted when we pop the routing view in case of a back navigation (e.g. by back button)
    // from the routing view to the home view.
    void startRide() {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const RideView(),
        ),
        (route) => false,
      ).whenComplete(() => true);
    }

    final settings = getIt<Settings>();
    if (settings.didViewWarning) {
      startRide();
    } else {
      showGeneralDialog(
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
            title: 'Hinweis',
            text:
                'Denke an Deine Sicherheit und achte stets auf Deine Umgebung. Beachte die Hinweisschilder und die örtlichen Gesetze.',
            actions: [
              BigButtonPrimary(
                label: "Ok",
                onPressed: () async {
                  await settings.setDidViewWarning(true);
                  startRide();
                },
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
              )
            ],
          );
        },
      );
    }
  }

  /// A callback that is fired when the user wants to select the displayed layers.
  void onLayerSelection() {
    showAppSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const LayerSelectionView(),
    );
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: const Center(
        child: SizedBox(
          height: 48,
          width: 48,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  /// Render a try again button.
  Widget renderTryAgainButton() {
    final backend = getIt<Settings>().backend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Tile(
            fill: Theme.of(context).colorScheme.background,
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 48),
                const VSpace(),
                BoldSmall(
                  text: "Tut uns Leid, aber das konnte nicht geladen werden.",
                  context: context,
                  textAlign: TextAlign.center,
                ),
                const SmallVSpace(),

                // if point is outside of supported bounding box
                (routing.waypointsOutOfBoundaries)
                    ? Column(
                        children: [
                          Small(
                            text:
                                "Das Routing wird aktuell nur innerhalb von ${backend.region} unterstützt. Bitte passe Deine Wegpunkte an.",
                            context: context,
                            textAlign: TextAlign.center,
                          ),
                          const VSpace(),
                          BigButtonPrimary(
                            label: "Zurück zum Hauptmenu",
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Small(
                            text:
                                "Achte darauf, dass Du mit dem Internet verbunden bist und versuche es später noch einmal.",
                            context: context,
                            textAlign: TextAlign.center,
                          ),
                          const VSpace(),
                          BigButtonPrimary(
                            label: "Erneut versuchen",
                            onPressed: () async {
                              await routing.loadRoutes();
                            },
                          ),
                        ],
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
  void showAlertGPSQualityDialog() {
    showGeneralDialog(
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
          title: 'Hinweis',
          text:
              'Deine GPS-Position scheint ungenau zu sein. Solltest Du während der Fahrt Probleme mit der Ortung feststellen, prüfe Deine Energiespareinstellungen oder erlaube die genaue Positionsbestimmung.',
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
  }

  @override
  Widget build(BuildContext context) {
    final simulatorEnabled = getIt<Settings>().enableSimulatorMode;

    return AnnotatedRegionWrapper(
      bottomBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      colorMode: Theme.of(context).brightness,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            RoutingMapView(
              mapValues: mapValues,
              mapFunctions: mapFunctions,
            ),

            if (routing.isFetchingRoute || geocoding.isFetchingAddress) renderLoadingIndicator(),
            if (routing.hadErrorDuringFetch) renderTryAgainButton(),

            // Top Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppBackButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // Side Bar
            layers.layersCanBeEnabled
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80, left: 8),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 42,
                            height: 42,
                            child: Tile(
                              fill: Theme.of(context).colorScheme.surfaceVariant,
                              onPressed: onLayerSelection,
                              padding: const EdgeInsets.all(8),
                              borderColor: Theme.of(context).brightness == Brightness.light
                                  ? null
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                              content: Icon(
                                Icons.layers_rounded,
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Container(),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: layers.layersCanBeEnabled ? 128 : 80, left: 8),
                child: Column(
                  children: [
                    CenterButton(
                      mapValues: mapValues,
                      mapFunctions: mapFunctions,
                    ),
                    const SmallVSpace(),
                    CompassButton(
                      mapValues: mapValues,
                      mapFunctions: mapFunctions,
                    ),
                    const SmallVSpace(),
                    const ProfileButton(),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 128),
                  child: ShortcutsRow(
                    mapFunctions: mapFunctions,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 0,
              top: 0,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    simulatorEnabled
                        ? const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: SimulatorState(
                              tileAlignment: TileAlignment.right,
                              onlyShowErrors: false,
                            ),
                          )
                        : Container(),
                    // Side Bar right
                    const Padding(
                      padding: EdgeInsets.only(top: 8, right: 8),
                      child: MapLegend(),
                    ),
                  ],
                ),
              ),
            ),

            const RoutingTutorialView(),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInCubic,
              bottom: mapFunctions.tappedWaypointIdx == null && !mapFunctions.selectPointOnMap ? 0 : -140,
              left: 0,
              child: RouteDetailsBottomSheet(
                onSelectStartButton: onStartRide,
                onSelectSaveButton: () => showSaveShortcutSheet(context),
                hasInitiallyLoaded: hasInitiallyLoaded,
                mapFunctions: mapFunctions,
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInCubic,
              bottom: mapFunctions.tappedWaypointIdx == null ? -140 : 0,
              left: 0,
              child: EditWaypointBottomSheet(
                mapFunctions: mapFunctions,
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInCubic,
              bottom: !mapFunctions.selectPointOnMap ? -140 : 0,
              left: 0,
              child: AddWaypointBottomSheet(
                mapFunctions: mapFunctions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
