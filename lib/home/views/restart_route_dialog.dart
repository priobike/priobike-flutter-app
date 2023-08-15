import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/views/shortcuts/save_shortcut_dialog.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';

class RestartRouteDialog extends AlertDialog {
  RestartRouteDialog({
    Key? key,
    required int lastRouteID,
    required List<Waypoint> lastRoute,
    required BuildContext context,
  }) : super(
          key: key,
          title: BoldSubHeader(
            text: 'Fahrt abgebrochen',
            context: context,
          ),
          content: BoldContent(
            text:
                'Die letzte Fahrt wurde unerwartet beendet. Willst du die Navigation der Route fortsetzen oder die Route speichern?',
            context: context,
          ),
          buttonPadding: const EdgeInsets.symmetric(horizontal: 5),
          // actionsPadding: ,
          actionsAlignment: MainAxisAlignment.start,
          actionsOverflowAlignment: OverflowBarAlignment.center,
          actions: [
            TextButton(
              child: BoldContent(text: 'Fortsetzen', color: Theme.of(context).colorScheme.primary, context: context),
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
            ),
            TextButton(
              child: BoldContent(text: 'Speichern', color: Theme.of(context).colorScheme.primary, context: context),
              onPressed: () {
                ShortcutRoute shortcutRoute = ShortcutRoute(name: "", waypoints: lastRoute);
                // Set waypoints and load ride view.
                Navigator.pop(context);
                showSaveShortcutSheet(context, shortcutRoute);
              },
            ),
            TextButton(
              child: BoldContent(text: 'Abbrechen', color: Theme.of(context).colorScheme.primary, context: context),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
}
