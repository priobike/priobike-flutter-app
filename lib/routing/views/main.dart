import 'dart:async';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/views/selection.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/alerts.dart';
import 'package:priobike/routing/views/layers.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/views/sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// The stream that receives notifications when the bottom sheet is dragged.
  final sheetMovement = StreamController<DraggableScrollableNotification>();

  /// The threshold for the location accuracy in meter
  /// NOTE: The accuracy will increase if we move and gain more GPS signal data.
  /// Hence, we don't want to set this threshold too low. The threshold should
  /// only detect exceptionally poor GPS quality (such as >1000m radius) that
  /// may be caused by energy saving options or disallowed precise geolocation.
  final int locationAccuracyThreshold = 100;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      await routing?.loadRoutes(context);

      // Calling requestSingleLocation function to fill lastPosition of PositionService
      await positioning?.requestSingleLocation(context);
      // Checking threshold for location accuracy
      if (
        positioning?.lastPosition?.accuracy != null && 
        positioning!.lastPosition!.accuracy >= locationAccuracyThreshold
      ) {
        showAlertGPSQualityDialog();
      }
    });
  }

  @override
  void didChangeDependencies() {
    geocoding = Provider.of<Geocoding>(context);
    routing = Provider.of<Routing>(context);
    shortcuts = Provider.of<Shortcuts>(context);
    positioning = Provider.of<Positioning>(context);
    super.didChangeDependencies();
  }

  /// A callback that is fired when the ride is started.
  Future<void> onStartRide() async {
    void startRide () => Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      // Avoid navigation back, only allow stop button to be pressed.
      // Note: Don't use pushReplacement since this will call
      // the result handler of the RouteView's host.
      return WillPopScope(
        onWillPop: () async => false,
        child: const RideSelectionView(),
      );
    }));

    final preferences = await SharedPreferences.getInstance();
    final didViewWarning = preferences.getBool("priobike.routing.warning") ?? false;
    if (didViewWarning) {
      startRide();
    } else {
      showDialog(context: context, builder: (_) => AlertDialog(
        alignment: AlignmentDirectional.center,
        actionsAlignment: MainAxisAlignment.center,
        title: BoldContent(text: 'Denke an deine Sicherheit und achte stets auf deine Umgebung. Beachte die Hinweisschilder und die örtlichen Gesetze.', context: context),
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
            child: BoldContent(text: 'OK', color: Theme.of(context).colorScheme.primary, context: context),
          ),
        ],
      ));
    }
  }

  /// A callback that is fired when the user wants to select the displayed layers.
  void onLayerSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
      builder: (_) => const LayerSelectionView(),
    );
  }

  /// A callback that is fired when the shortcut should be saved but a name is required.
  void onRequestShortcutName() {
    showDialog(
      context: context,
      builder: (_) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: BoldContent(text: 'Bitte gib einen Namen an, unter dem der Shortcut gespeichert werden soll.', context: context),
          content: SizedBox(height: 48, child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Heimweg, Zur Arbeit, ...'),
              ),
            ],
          )),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                if (name.isEmpty) ToastMessage.showError("Name darf nicht leer sein.");
                await shortcuts?.saveNewShortcut(name, context);
                ToastMessage.showSuccess("Route gespeichert!");
                Navigator.pop(context);
              },
              child: BoldContent(text: 'Speichern', color: Theme.of(context).colorScheme.primary, context: context),
            ),
          ],
        );
      },
    );
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Tile(
        fill: Theme.of(context).colorScheme.surface,
        content: Center(child: SizedBox(
          height: 86, 
          width: 256, 
          child: Column(children: [
            const CircularProgressIndicator(),
            const VSpace(),
            BoldContent(text: "Lade...", maxLines: 1, context: context),
          ])
        ))
      )),
    ]);
  }

  /// Render a try again button.
  Widget renderTryAgainButton() {
    return Scaffold(
      body: SafeArea(
        child: Pad(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Expanded(child: Tile(
                fill: Theme.of(context).colorScheme.background,
                content: Center(child: SizedBox(
                  height: 128, 
                  width: 256, 
                  child: Column(children: [
                    BoldSmall(text: "Fehler beim Laden der Route.", maxLines: 1, context: context),
                    const SmallVSpace(),
                    Small(text: "Prüfe deine Verbindung.", maxLines: 1, context: context),
                    const VSpace(),
                    BigButton(label: "Erneut Laden", onPressed: () async {
                      await routing?.loadRoutes(context);
                    }),
                  ])
                ))
              )),
            ],
          ),
        ),
      ),
    );
  }

  /// Alert dialog for location accuracy
  void showAlertGPSQualityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: BoldSubHeader(text: 'Hinweis', context: context),
          content: Content(
            text: 'Deine GPS-Position scheint ungenau zu sein. Solltest du während der Fahrt Probleme mit der Ortung feststellen, prüfe deine Energiespareinstellungen oder erlaube die genaue Positionsbestimmung.',
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

  @override
  Widget build(BuildContext context) {
    if (routing!.hadErrorDuringFetch) return renderTryAgainButton();

    final frame = MediaQuery.of(context);
  
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light 
        ? SystemUiOverlayStyle.dark 
        : SystemUiOverlayStyle.light,
      child: Scaffold(body: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          sheetMovement.add(notification);
          return false;
        },
        child: Stack(children: [
          RoutingMapView(sheetMovement: sheetMovement.stream),

          if (routing!.isFetchingRoute) renderLoadingIndicator(),
          if (geocoding!.isFetchingAddress) renderLoadingIndicator(),
          
          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppBackButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 16),
                SizedBox( // Avoid expansion of alerts view.
                  width: frame.size.width - 80, 
                  child: const AlertsView(),
                )
              ]),
            )
          ),

          // Side Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 80, left: 8),
              child: Column(children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Tile(
                    fill: Theme.of(context).colorScheme.background,
                    onPressed: onLayerSelection,
                    content: Icon(
                      Icons.layers, 
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                )
              ]),
            ),
          ),

          RouteDetailsBottomSheet(onSelectStartButton: onStartRide, onSelectSaveButton: onRequestShortcutName),
        ]),
      ),
    ));
  }

  @override
  void dispose() {
    sheetMovement.close();
    super.dispose();
  }
}
