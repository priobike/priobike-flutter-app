import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/logging/toast.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';

class RestartRouteDialog extends AlertDialog {
  RestartRouteDialog({
    Key? key,
    required int lastRouteID,
    required List<Waypoint> lastRoute,
    required Ride ride,
    required Routing routing,
    required BuildContext context,
  }) : super(
          key: key,
          title: const Text('Fahrt abgebrochen'),
          content: const Text(
              'Die letzte Fahrt wurde unerwartet beendet. Wollen sie die Navigation der Route fortsetzen oder die Route speichern?'),
          actions: [
            TextButton(
              child: const Text('Verwerfen'),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Fortsetzen'),
              onPressed: () async {
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
                  // Remove last route after loading is complete.
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
              child: const Text('Speichern'),
              onPressed: () {
                // TODO route speichern.
                // Set waypoints and load ride view.

              },
            ),
          ],
        );
}
