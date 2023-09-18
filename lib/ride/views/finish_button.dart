import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/feedback/views/main.dart';
import 'package:priobike/gamification/community/service/community_service.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tracking/services/tracking.dart';

class FinishRideButton extends StatefulWidget {
  const FinishRideButton({Key? key}) : super(key: key);

  @override
  FinishRideButtonState createState() => FinishRideButtonState();
}

class FinishRideButtonState extends State<FinishRideButton> {
  final log = Logger("FinishButton");

  void showAskForConfirmationDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: 'Fahrt wirklich beenden?',
          text: "Wenn du die Fahrt beendest, musst du erst eine neue Route erstellen, um eine neue Fahrt zu starten.",
          icon: Icons.question_mark_rounded,
          iconColor: Theme.of(context).colorScheme.primary,
          actions: [
            BigButton(
              iconColor: Colors.white,
              icon: Icons.flag_rounded,
              label: "Ja",
              onPressed: () => onTap(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            ),
            BigButton(
              iconColor: Colors.white,
              icon: Icons.close_rounded,
              label: "Nein",
              onPressed: () => Navigator.of(context).pop(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            ),
          ],
        );
      },
    );
  }

  /// A callback that is executed when the cancel button is pressed.
  Future<void> onTap() async {
    // End the tracking and collect the data.
    final tracking = getIt<Tracking>();
    await tracking.end(); // Performs all needed resets.

    // Calculate a summary of the ride.
    final statistics = getIt<Statistics>();
    await statistics.calculateSummary();

    // If there is an active event, check if the user passed some of the event locations.
    await getIt<CommunityService>().checkLocations();

    // Disconnect from the mqtt broker.
    final datastream = getIt<Datastream>();
    await datastream.disconnect();

    // End the recommendations.
    final ride = getIt<Ride>();
    await ride.stopNavigation();
    // Remove last route since the ride continues.
    ride.removeLastRoute();

    // Stop the geolocation.
    final position = getIt<Positioning>();
    await position.stopGeolocation();

    if (mounted) {
      // Show the feedback dialog.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WillPopScope(
            onWillPop: () async => false,
            child: FeedbackView(
              onSubmitted: (context) async {
                // Reset the statistics.
                await statistics.reset();

                // Reset the ride service.
                await ride.reset();

                // Reset the position service.
                await position.reset();

                // Reset the route service.
                final routing = getIt<Routing>();
                await routing.reset();

                // Reset the prediction sg status.
                final predictionSGStatus = getIt<PredictionSGStatus>();
                await predictionSGStatus.reset();

                if (context.mounted) {
                  // Leave the feedback view.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 48, // Below the MapBox attribution.
          right: 0,
          child: SafeArea(
            child: Tile(
              onPressed: () => showAskForConfirmationDialog(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              padding: const EdgeInsets.all(4),
              fill: Colors.black.withOpacity(0.4),
              content: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                    ),
                    const SmallHSpace(),
                    BoldSmall(
                      text: "Ende",
                      context: context,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
