import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/views/main.dart';
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

  /// A callback that is executed when the cancel button is pressed.
  Future<void> onTap(BuildContext context) async {
    // Stop the reroute service.
    final rerouteService = Provider.of<RerouteService>(context, listen: false);
    await rerouteService.stopRerouteScheduler();

    // End the recommendations.
    final recommendationService = Provider.of<RideService>(context, listen: false);
    await recommendationService.stopNavigation();

    // Stop the geolocation.
    final positionService = Provider.of<PositionService>(context, listen: false);
    await positionService.stopGeolocation();

    // Show the feedback dialog.
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FeedbackView(
      onSubmitted: (context) async {
        // Reset the reroute service.
        await rerouteService.reset();

        // Reset the recommendation service.
        await recommendationService.reset();

        // Reset the position service.
        await positionService.reset();

        // Reset the route service.
        final routingService = Provider.of<RoutingService>(context, listen: false);
        await routingService.reset();

        // Stop the session and reset the session service.
        final sessionService = Provider.of<SessionService>(context, listen: false);
        await sessionService.reset();

        // Leave the feedback view.
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        width: 96,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.done),
          label: BoldSmall(text: "Fertig", color: Theme.of(context).colorScheme.onPrimary),
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
              Theme.of(context).colorScheme.primary
            ),
          )
        ),
      ),
    );
  }
}