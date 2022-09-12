import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/views/main.dart';
import 'package:priobike/ride/services/position/estimator.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/ride/services/snapping.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:provider/provider.dart';

/// A cancel button to cancel the ride.
class CancelButton extends StatelessWidget {
  /// The border radius of the button.
  final double borderRadius;

  /// The text of the button.
  final String text;

  /// Create a new cancel button.
  const CancelButton({this.borderRadius = 32, this.text = "Fertig", Key? key}) : super(key: key);

  /// A callback that is executed when the cancel button is pressed.
  Future<void> onTap(BuildContext context) async {
    // Calculate a summary of the ride.
    final statisticsService = Provider.of<StatisticsService>(context, listen: false);
    statisticsService.calculateSummary(context);
    
    // End the recommendations.
    final recommendationService = Provider.of<RideService>(context, listen: false);
    await recommendationService.stopNavigation();

    // Stop the geolocation.
    final positionService = Provider.of<PositionService>(context, listen: false);
    await positionService.stopGeolocation();

    // Stop the position estimation.
    final positionEstimatorService = Provider.of<PositionEstimatorService>(context, listen: false);
    positionEstimatorService.stopEstimating();

    // Show the feedback dialog.
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FeedbackView(
      onSubmitted: (context) async {
        // Reset the statistics.
        statisticsService.reset();

        // Reset the snapping service.
        final snappingService = Provider.of<SnappingService>(context, listen: false);
        await snappingService.reset();

        // Reset the recommendation service.
        await recommendationService.reset();

        // Reset the position estimation service.
        await positionEstimatorService.reset();

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
          label: BoldSmall(text: text, context: context, color: Colors.white),
          onPressed: () => onTap(context),
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
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