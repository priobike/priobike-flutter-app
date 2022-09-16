import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/views/main.dart';
import 'package:priobike/positioning/services/estimator.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/positioning/services/snapping.dart';
import 'package:priobike/routingNew/services/routing.dart';
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
    final statistics = Provider.of<Statistics>(context, listen: false);
    statistics.calculateSummary(context);
    
    // End the recommendations.
    final recommendation = Provider.of<Ride>(context, listen: false);
    await recommendation.stopNavigation();

    // Stop the geolocation.
    final position = Provider.of<Positioning>(context, listen: false);
    await position.stopGeolocation();

    // Stop the position estimation.
    final positionEstimator = Provider.of<PositionEstimator>(context, listen: false);
    positionEstimator.stopEstimating();

    // Show the feedback dialog.
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FeedbackView(
      onSubmitted: (context) async {
        // Reset the statistics.
        statistics.reset();

        // Reset the snapping service.
        final snapping = Provider.of<Snapping>(context, listen: false);
        await snapping.reset();

        // Reset the recommendation service.
        await recommendation.reset();

        // Reset the position estimation service.
        await positionEstimator.reset();

        // Reset the position service.
        await position.reset();

        // Reset the route service.
        final routing = Provider.of<Routing>(context, listen: false);
        await routing.reset();

        // Stop the session and reset the session service.
        final session = Provider.of<Session>(context, listen: false);
        await session.reset();

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