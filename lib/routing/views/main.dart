import 'dart:async';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
import 'package:priobike/routing/views/details/shortcuts.dart';
import 'package:priobike/routing/views/layers.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/views/sheet.dart';
import 'package:priobike/routing/views/widgets/center_button.dart';
import 'package:priobike/routing/views/widgets/compass_button.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class RoutingView extends StatefulWidget {
  const RoutingView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingViewState();
}

class RoutingViewState extends State<RoutingView> {
  /// The associated geocoding service, which is injected by the provider.
  Geocoding? geocoding;

  /// The associated routing service, which is injected by the provider.
  Routing? routing;

  /// The associated position service, which is injected by the provider.
  Positioning? positioning;

  /// The associated shortcuts service, which is injected by the provider.
  Shortcuts? shortcuts;

  /// The associated layers service, which is injected by the provider.
  late Layers layers;

  /// The associated MapFunctions service, which is injected by the provider.
  late MapFunctions mapFunctions;

  /// The associated MapValues service, which is injected by the provider.
  late MapValues mapValues;

  /// The stream that receives notifications when the bottom sheet is dragged.
  final sheetMovement = StreamController<DraggableScrollableNotification>();

  /// The threshold for the location accuracy in meter
  /// NOTE: The accuracy will increase if we move and gain more GPS signal data.
  /// Hence, we don't want to set this threshold too low. The threshold should
  /// only detect exceptionally poor GPS quality (such as >1000m radius) that
  /// may be caused by energy saving options or disallowed precise geolocation.
  final int locationAccuracyThreshold = 100;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    // Register Service.
    getIt.registerSingleton<MapFunctions>(MapFunctions());
    getIt.registerSingleton<MapValues>(MapValues());

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        // Calling requestSingleLocation function to fill lastPosition of PositionService
        await positioning?.requestSingleLocation(onNoPermission: () {
          Navigator.of(context).pop();
          showLocationAccessDeniedDialog(context, positioning!.positionSource);
        });
        // Needs to be loaded after we requested the location, because we need the lastPosition if we load the route from
        // a location shortcut instead of a route shortcut.
        await routing?.loadRoutes();
        // Checking threshold for location accuracy
        if (positioning?.lastPosition?.accuracy != null &&
            positioning!.lastPosition!.accuracy >= locationAccuracyThreshold) {
          showAlertGPSQualityDialog();
        }
      },
    );

    geocoding = getIt<Geocoding>();
    geocoding!.addListener(update);
    routing = getIt<Routing>();
    routing!.addListener(update);
    shortcuts = getIt<Shortcuts>();
    shortcuts!.addListener(update);
    positioning = getIt<Positioning>();
    positioning!.addListener(update);
    layers = getIt<Layers>();
    layers.addListener(update);
    mapFunctions = getIt<MapFunctions>();
    mapValues = getIt<MapValues>();
  }

  @override
  void dispose() {
    geocoding!.removeListener(update);
    routing!.removeListener(update);
    shortcuts!.removeListener(update);
    positioning!.removeListener(update);
    layers.removeListener(update);
    sheetMovement.close();

    // Unregister Service since the app will run out of the needed scope.
    getIt.unregister<MapFunctions>(instance: mapFunctions);
    getIt.unregister<MapValues>(instance: mapValues);
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
        pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
          return DialogLayout(
            title: 'Hinweis',
            text:
                'Denke an deine Sicherheit und achte stets auf deine Umgebung. Beachte die Hinweisschilder und die örtlichen Gesetze.',
            icon: Icons.info_rounded,
            iconColor: Theme.of(context).colorScheme.primary,
            actions: [
              BigButton(
                iconColor: Colors.white,
                icon: Icons.check_rounded,
                label: "Ok",
                onPressed: () async {
                  await settings.setDidViewWarning(true);
                  startRide();
                },
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
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
    final backend = getIt<Settings>().backend;
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
                  text: "Tut uns Leid, aber das konnte nicht geladen werden.",
                  context: context,
                  textAlign: TextAlign.center,
                ),
                const SmallVSpace(),

                // if point is outside of supported bounding box
                (routing!.waypointsOutOfBoundaries)
                    ? Column(
                        children: [
                          Small(
                            text:
                                "Das Routing wird aktuell nur innerhalb von ${backend.region} unterstützt. Bitte passe Deine Wegpunkte an.",
                            context: context,
                            textAlign: TextAlign.center,
                          ),
                          const VSpace(),
                          BigButton(
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
                          BigButton(
                            label: "Erneut versuchen",
                            onPressed: () async {
                              await routing?.loadRoutes();
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
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: 'Hinweis',
          text:
              'Deine GPS-Position scheint ungenau zu sein. Solltest du während der Fahrt Probleme mit der Ortung feststellen, prüfe deine Energiespareinstellungen oder erlaube die genaue Positionsbestimmung.',
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
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              systemNavigationBarColor: Theme.of(context).colorScheme.background,
              systemNavigationBarIconBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: Theme.of(context).colorScheme.background,
              systemNavigationBarIconBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.dark,
            ),
      child: Scaffold(
        body: NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            sheetMovement.add(notification);
            return false;
          },
          child: Stack(
            children: [
              RoutingMapView(sheetMovement: sheetMovement.stream),

              if (routing!.isFetchingRoute || geocoding!.isFetchingAddress) renderLoadingIndicator(),
              if (routing!.hadErrorDuringFetch) renderTryAgainButton(),

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
                              width: 58,
                              height: 58,
                              child: Tile(
                                fill: Theme.of(context).colorScheme.background,
                                onPressed: onLayerSelection,
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
                  padding: EdgeInsets.only(top: layers.layersCanBeEnabled ? 145 : 80, left: 8),
                  child: Column(
                    children: const [CenterButton(), SmallVSpace(), CompassButton()],
                  ),
                ),
              ),

              const SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 124),
                    child: ShortcutsRow(),
                  ),
                ),
              ),

              RouteDetailsBottomSheet(
                onSelectStartButton: onStartRide,
                onSelectSaveButton: () => showSaveShortcutSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
