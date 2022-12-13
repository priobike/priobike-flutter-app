import 'package:flutter/material.dart';
import 'package:priobike/accelerometer/services/accelerometer.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/feedback/views/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/positioning/services/snapping.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tracking/services/tracking.dart';
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
    // End the tracking and collect the data.
    final tracking = Provider.of<Tracking>(context, listen: false);
    await tracking.end(context);

    // Calculate a summary of the ride.
    final statistics = Provider.of<Statistics>(context, listen: false);
    await statistics.calculateSummary(context);

    // Disconnect from the mqtt broker.
    final datastream = Provider.of<Datastream>(context, listen: false);
    await datastream.disconnect();

    // End the recommendations.
    final recommendation = Provider.of<Ride>(context, listen: false);
    await recommendation.stopNavigation();

    // End the accelerometer updates.
    final accelerometer = Provider.of<Accelerometer>(context, listen: false);
    await accelerometer.stop();

    // Stop the geolocation.
    final position = Provider.of<Positioning>(context, listen: false);
    await position.stopGeolocation();

    // Show the feedback dialog.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: FeedbackView(
            onSubmitted: (context) async {
              // Reset the tracking.
              await tracking.reset();

              // Reset the statistics.
              await statistics.reset();

              // Reset the snapping service.
              final snapping = Provider.of<Snapping>(context, listen: false);
              await snapping.reset();

              // Reset the recommendation service.
              await recommendation.reset();

              // Reset the accelerometer service.
              await accelerometer.reset();

              // Reset the position service.
              await position.reset();

              // Reset the route service.
              final routing = Provider.of<Routing>(context, listen: false);
              await routing.reset();

              // Stop the session and reset the session service.
              final session = Provider.of<Session>(context, listen: false);
              await session.reset();

              // Reset the prediction sg status.
              final predictionSGStatus = Provider.of<PredictionSGStatus>(context, listen: false);
              await predictionSGStatus.reset();

              // Reset the dangers.
              final dangers = Provider.of<Dangers>(context, listen: false);
              await dangers.reset();

              // Leave the feedback view.
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      ),
    );
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
                side: const BorderSide(color: Color.fromARGB(255, 236, 240, 241)),
              ),
            ),
            foregroundColor: MaterialStateProperty.all<Color>(const Color.fromARGB(255, 236, 240, 241)),
            backgroundColor: MaterialStateProperty.all<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
