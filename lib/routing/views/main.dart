import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/ride/views/selection.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/alerts.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/views/sheet.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoutingView extends StatefulWidget {
  const RoutingView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingViewState();
}

class RoutingViewState extends State<RoutingView> {
  /// The associated routing service, which is injected by the provider.
  RoutingService? routingService;

  /// The associated shortcuts service, which is injected by the provider.
  ShortcutsService? shortcutsService;

  /// The stream that receives notifications when the bottom sheet is dragged.
  final sheetMovement = StreamController<DraggableScrollableNotification>();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      await routingService?.loadRoutes(context);
    });
  }

  @override
  void didChangeDependencies() {
    routingService = Provider.of<RoutingService>(context);
    shortcutsService = Provider.of<ShortcutsService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is fired when the ride is started.
  Future<void> onStartRide() async {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final nextView = settingsService.ridePreference == null 
      ? const RideSelectionView() // Need to select a ride preference.
      : const RideView();

    void startRide () => Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      // Avoid navigation back, only allow stop button to be pressed.
      // Note: Don't use pushReplacement since this will call
      // the result handler of the RouteView's host.
      return WillPopScope(
        onWillPop: () async => false,
        child: nextView,
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
            child: BoldContent(text: 'OK', color: Colors.blue, context: context),
          ),
        ],
      ));
    }
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
                await shortcutsService?.saveNewShortcut(name, context);
                ToastMessage.showSuccess("Route gespeichert!");
                Navigator.pop(context);
              },
              child: BoldContent(text: 'Speichern', color: Colors.blue, context: context),
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
        fill: Theme.of(context).colorScheme.background,
        content: Center(child: SizedBox(
          height: 86, 
          width: 256, 
          child: Column(children: [
            const CircularProgressIndicator(),
            const VSpace(),
            BoldContent(text: "Lade Route...", maxLines: 1, context: context),
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
                    BoldContent(text: "Fehler beim Laden der Route.", maxLines: 1, context: context),
                    const VSpace(),
                    BigButton(label: "Erneut Laden", onPressed: () async {
                      await routingService?.loadRoutes(context);
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

  @override
  Widget build(BuildContext context) {
    if (routingService!.hadErrorDuringFetch) return renderTryAgainButton();
  
    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(body: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          sheetMovement.add(notification);
          return false;
        },
        child: Stack(children: [
          RoutingMapView(sheetMovement: sheetMovement.stream),

          if (routingService!.isFetchingRoute) renderLoadingIndicator(),
          
          // Top Bar
          SafeArea(
            minimum: const EdgeInsets.only(top: 64),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppBackButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 16),
              SizedBox( // Avoid expansion of alerts view.
                width: frame.size.width - 80, 
                child: const AlertsView(),
              )
            ]),
          ),

          RouteDetailsBottomSheet(onSelectStartButton: onStartRide, onSelectSaveButton: onRequestShortcutName),
        ]),
      )),
    );
  }

  @override
  void dispose() {
    sheetMovement.close();
    super.dispose();
  }
}
