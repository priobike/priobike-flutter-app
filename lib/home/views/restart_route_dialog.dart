import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';

/// Show a sheet to edit the current shortcuts name.
void showRestartRouteDialog(context, int lastRouteID, List<Waypoint> lastRoute) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.4),
    pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      return DialogLayout(
        title: 'Fahrt abgebrochen',
        text:
            "Die letzte Fahrt wurde unerwartet beendet. Willst du die Navigation der Route fortsetzen oder die Route speichern?",
        icon: Icons.warning_rounded,
        iconColor: Theme.of(context).colorScheme.primary,
        actions: [
          BigButton(
            iconColor: Colors.white,
            icon: Icons.directions_bike_rounded,
            label: "Fortsetzen",
            onPressed: () async {
              Routing routing = getIt<Routing>();
              // Set waypoints, load route and load ride view.
              await routing.selectWaypoints(lastRoute);
              await routing.loadRoutes();
              // Select last route if possible (Graphhopper can change!).
              if (routing.allRoutes != null && routing.allRoutes!.length > lastRouteID) {
                await routing.switchToRoute(lastRouteID);
              }
              if (context.mounted && routing.selectedRoute != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const RideView(),
                  ),
                );
              } else {
                // In case there is any error fetching the route.
                if (routing.hadErrorDuringFetch) {
                  // Display error toast message.
                  ToastMessage.showError("Route konnte nicht geladen werden.");
                  // Pop the dialog.
                  Navigator.of(context).pop();
                }
              }
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          ),
          BigButton(
            iconColor: Colors.white,
            icon: Icons.save_rounded,
            label: "Speichern",
            onPressed: () {
              ShortcutRoute shortcutRoute = ShortcutRoute(name: "", waypoints: lastRoute);
              // Set waypoints and load ride view.
              Navigator.pop(context);
              showSaveShortcutSheet(context, shortcut: shortcutRoute);
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          ),
          BigButton(
            iconColor: Colors.white,
            icon: Icons.close_rounded,
            label: "Abbrechen",
            onPressed: () => Navigator.of(context).pop(),
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          )
        ],
      );
    },
  );
}
