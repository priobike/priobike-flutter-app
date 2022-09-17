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
import 'package:priobike/routingNew/services/geocoding.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/routingNew/views/map.dart';
import 'package:priobike/routingNew/services/mapcontroller.dart';
import 'package:priobike/routingNew/views/widgets/compassButton.dart';
import 'package:priobike/routingNew/views/widgets/filterButton.dart';
import 'package:priobike/routingNew/views/widgets/gpsButton.dart';
import 'package:priobike/routingNew/views/widgets/searchBar.dart';
import 'package:priobike/routingNew/views/widgets/shortcuts.dart';
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
  Geocoding? geocodingService;

  /// The associated routing service, which is injected by the provider.
  Routing? routingService;

  /// The associated shortcuts service, which is injected by the provider.
  Shortcuts? shortcutsService;

  /// The associated position service, which is injected by the provider.
  Positioning? positioning;

  /// The associated shortcuts service, which is injected by the provider.
  MapController? mapControllerService;

  /// The associated shortcuts service, which is injected by the provider.
  Profile? profileService;

  /// The stream that receives notifications when the bottom sheet is dragged.
  final sheetMovement = StreamController<DraggableScrollableNotification>();

  /// The threshold for the location accuracy in meter
  final int locationAccuracyThreshold = 20;


  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      await routingService?.loadRoutes(context);

      /// Calling requestSingleLocation function to fill lastPosition of PositionService
      await positioning?.requestSingleLocation(context);
      /// Checking threshold for location accuracy
      if (positioning?.lastPosition?.accuracy != null && positioning!.lastPosition!.accuracy >= locationAccuracyThreshold) {
        _showAlertGPSQualityDialog();
      }
    });
  }

  @override
  void didChangeDependencies() {
    geocodingService = Provider.of<Geocoding>(context);
    routingService = Provider.of<Routing>(context);
    shortcutsService = Provider.of<Shortcuts>(context);
    mapControllerService = Provider.of<MapController>(context);
    profileService = Provider.of<Profile>(context);
    positioning = Provider.of<Positioning>(context);

    super.didChangeDependencies();
  }

  /// A callback that is fired when the ride is started.
  Future<void> onStartRide() async {
    final settingsService =
        Provider.of<Settings>(context, listen: false);
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
        preferences.getBool("priobike.routing.warning") ?? false;
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
                preferences.setBool("priobike.routing.warning", true);
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
                if (name.isEmpty)
                  ToastMessage.showError("Name darf nicht leer sein.");
                await shortcutsService?.saveNewShortcut(name, context);
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
                              await routingService?.loadRoutes(context);
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
          content: Content( text:
          'Die Qualität der Positionsbestimmung ist nicht optimal. Prüfen sie gegebenenfalls die Einstellungen des GPS für die App.', context: context),
          actions: <Widget>[
            TextButton(
              child: Content(text: 'Okay', context: context, color: Theme.of(context).colorScheme.primary),
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
    mapControllerService?.zoomIn();
  }

  /// Private ZoomOut Function which calls mapControllerService
  void _zoomOut() {
    mapControllerService?.zoomOut();
  }

  /// Private GPS Centralization Function which calls mapControllerService
  void _gpsCentralization() {
    mapControllerService?.setMyLocationTrackingModeTracking();
  }

  /// Private Center North Function which calls mapControllerService
  void _centerNorth() {
    mapControllerService?.centerNorth();
  }

  @override
  Widget build(BuildContext context) {
    if (routingService!.hadErrorDuringFetch) return renderTryAgainButton();

    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            sheetMovement.add(notification);
            return false;
          },
          child: Stack(children: [
            RoutingMapView(sheetMovement: sheetMovement.stream),

            if (routingService!.isFetchingRoute) renderLoadingIndicator(),
            if (geocodingService!.isFetchingAddress) renderLoadingIndicator(),

            // Top Bar
            SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
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
                            child: const SearchBar(fromClicked: false),
                          )
                        ]),
                    const ShortCuts(),
                    Padding(
                      /// Align with FAB
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 20),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CompassButton(centerNorth: _centerNorth),
                            ZoomInAndOutButton(
                                zoomIn: _zoomIn, zoomOut: _zoomOut),
                            FilterButton(profileService: profileService),
                          ]),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GPSButton(
                myLocationTrackingMode:
                    mapControllerService?.myLocationTrackingMode,
                gpsCentralization: _gpsCentralization),
            const SizedBox(
              height: 15,
            ),
            FloatingActionButton(
              onPressed: () => {},
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
        ),
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
