import 'dart:async';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/map_values.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/alerts.dart';
import 'package:priobike/routing/views/details/shortcuts.dart';
import 'package:priobike/routing/views/layers.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/views/sheet.dart';
import 'package:priobike/routing/views/widgets/center_button.dart';
import 'package:priobike/routing/views/widgets/compass_button.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

/// Show a sheet to save the current route as a shortcut.
void showSaveShortcutSheet(context) {
  final shortcuts = GetIt.instance.get<Shortcuts>();
  showDialog(
    context: context,
    builder: (_) {
      final nameController = TextEditingController();
      return AlertDialog(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        insetPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40.0),
        title: BoldContent(
          text: 'Bitte gib einen Namen an, unter dem die Strecke gespeichert werden soll.',
          context: context,
        ),
        content: SizedBox(
          height: 78,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                maxLength: 20,
                decoration: const InputDecoration(hintText: 'Heimweg, Zur Arbeit, ...'),
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
              if (name.trim().isEmpty) {
                ToastMessage.showError("Name darf nicht leer sein.");
                return;
              }
              await shortcuts.saveNewShortcutRoute(name);
              ToastMessage.showSuccess("Route gespeichert!");
              Navigator.pop(context);
            },
            child: BoldContent(
              text: 'Speichern',
              color: Theme.of(context).colorScheme.primary,
              context: context,
            ),
          ),
        ],
      );
    },
  );
}

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
    void startRide() => Navigator.pushReplacement<void, bool>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const RideView(),
        ),
        result: true);

    final settings = getIt<Settings>();
    if (settings.didViewWarning) {
      startRide();
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
          alignment: AlignmentDirectional.center,
          actionsAlignment: MainAxisAlignment.center,
          content: BoldContent(
              text:
                  'Denke an deine Sicherheit und achte stets auf deine Umgebung. Beachte die Hinweisschilder und die örtlichen Gesetze.',
              context: context),
          actions: [
            TextButton(
              onPressed: () async {
                await settings.setDidViewWarning(true);
                startRide();
              },
              child: BoldContent(
                text: 'OK',
                color: Theme.of(context).colorScheme.primary,
                context: context,
              ),
            ),
          ],
        ),
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
                  text: "Tut uns Leid, aber diese Route konnte nicht geladen werden.",
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
                            label: "Letzten Wegpunkt löschen",
                            onPressed: () async {
                              if (routing!.selectedWaypoints != null && routing!.selectedWaypoints!.isNotEmpty) {
                                routing!.selectedWaypoints!.removeLast();
                              } else {
                                log.e("Tried to delete last waypoint, but there is no waypoint to delete");
                              }
                              await routing!.loadRoutes();
                            },
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
          title: BoldSubHeader(text: 'Hinweis', context: context),
          content: Content(
            text:
                'Deine GPS-Position scheint ungenau zu sein. Solltest du während der Fahrt Probleme mit der Ortung feststellen, prüfe deine Energiespareinstellungen oder erlaube die genaue Positionsbestimmung.',
            context: context,
          ),
          actions: <Widget>[
            TextButton(
              child: BoldContent(
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

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppBackButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 16),
                      SizedBox(
                        // Avoid expansion of alerts view.
                        width: frame.size.width - 80,
                        child: const AlertsView(),
                      )
                    ],
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
