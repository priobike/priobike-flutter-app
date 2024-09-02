import 'dart:ui';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:uuid/v4.dart';

/// Show a sheet to edit the current shortcuts name.
void showRestartRouteDialog(context, int lastRouteID, List<Waypoint> lastRoute) {
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
        title: 'Fahrt abgebrochen',
        text:
            "Die letzte Fahrt wurde unerwartet beendet. Willst Du die Navigation der Route fortsetzen oder die Route speichern?",
        actions: [
          BigButtonPrimary(
            label: "Fortsetzen",
            onPressed: () async {
              Routing routing = getIt<Routing>();
              // Set waypoints, load route and load ride view.
              Navigator.of(context).pop();
              await routing.selectWaypoints(lastRoute);
              await routing.loadRoutes();
              // Select last route if possible (Graphhopper can change!).
              if (routing.allRoutes != null && routing.allRoutes!.length > lastRouteID) {
                await routing.switchToRoute(lastRouteID);
              }
              if (context.mounted && routing.selectedRoute != null) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const RideView(),
                  ),
                  (route) => false,
                );
              } else {
                // In case there is any error fetching the route.
                if (routing.hadErrorDuringFetch) {
                  // Display error toast message.
                  getIt<Toast>().showError("Route konnte nicht geladen werden.");
                  // Pop the dialog.
                }
              }
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          ),
          BigButtonSecondary(
            label: "Speichern",
            onPressed: () {
              ShortcutRoute shortcutRoute =
                  ShortcutRoute(id: const UuidV4().generate(), name: "", waypoints: lastRoute);
              // Set waypoints and load ride view.
              Navigator.pop(context);
              showSaveShortcutFromShortcutSheet(context, shortcut: shortcutRoute);
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          ),
          BigButtonTertiary(
            label: "Abbrechen",
            onPressed: () => Navigator.of(context).pop(),
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          )
        ],
      );
    },
  );
}
