

import 'package:flutter/material.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/reroute.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

/// A cancel button to cancel the ride.
class CancelButton extends StatelessWidget {
  /// Create a new cancel button.
  const CancelButton({Key? key}) : super(key: key);

  /// End the ride.
  /// TODO: Here, we should not reset all services but rather show the feedback section.
  Future<void> endRide(BuildContext context) async {
    // Stop the reroute service.
    final rerouteService = Provider.of<RerouteService>(context, listen: false);
    await rerouteService.reset();

    // Reset the route service.
    final routingService = Provider.of<RoutingService>(context, listen: false);
    await routingService.reset();

    // End the recommendations and reset the recommendation service.
    final recommendationService = Provider.of<RideService>(context, listen: false);
    await recommendationService.reset();

    // Stop the geolocation and reset the position service.
    final positionService = Provider.of<PositionService>(context, listen: false);
    await positionService.reset();

    // Stop the session and reset the session service.
    final session = Provider.of<SessionService>(context, listen: false);
    await session.reset();
  }

  /// A callback that is executed when the cancel button is pressed.
  Future<void> onTap(BuildContext context) async {
    await endRide(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        width: 164,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.stop),
          label: const Text("Fahrt Beenden"),
          onPressed: () => onTap(context),
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color.fromARGB(255, 236, 240, 241))
              )
            ),
            foregroundColor: MaterialStateProperty.all<Color>(
              const Color.fromARGB(255, 236, 240, 241)
            ),
            backgroundColor: MaterialStateProperty.all<Color>(
              const Color.fromARGB(255, 44, 62, 80)
            ),
          )
        ),
      ),
    );
  }
}