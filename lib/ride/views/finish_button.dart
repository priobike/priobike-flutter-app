import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/feedback/views/main.dart';
import 'package:priobike/home/views/main.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FinishRideButton extends StatefulWidget {
  const FinishRideButton({super.key});

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
          text: "Wenn Du die Fahrt beendest, musst Du erst eine neue Route erstellen, um eine neue Fahrt zu starten.",
          iconColor: Theme.of(context).colorScheme.primary,
          actions: [
            BigButtonPrimary(
              icon: Icons.flag_rounded,
              label: "Fahrt beenden",
              onPressed: () => onTap(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            ),
            BigButtonTertiary(
              icon: Icons.close_rounded,
              label: "Abbrechen",
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
    // Allows only portrait mode again when leaving the ride view.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // End the tracking and collect the data.
    final tracking = getIt<Tracking>();
    await tracking.end(); // Performs all needed resets.

    // Calculate a summary of the ride.
    final statistics = getIt<Statistics>();
    await statistics.calculateSummary();

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

    // Disable the wakelock which was set when the ride started.
    WakelockPlus.disable();

    // Show the feedback view.
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => FeedbackView(
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
                // Return to the home view.
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (BuildContext context) => const HomeView()),
                );
              }
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscapeMode = orientation == Orientation.landscape;

    return Stack(
      children: [
        Positioned(
          top: 48, // Below the MapBox attribution.
          // Button is on the right in portrait mode and on the left in landscape mode.
          right: isLandscapeMode ? null : 0,
          left: isLandscapeMode ? 0 : null,
          child: SafeArea(
            child: Tile(
              onPressed: () => showAskForConfirmationDialog(context),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(24),
                bottomLeft: const Radius.circular(24),
                topRight: isLandscapeMode ? const Radius.circular(24) : const Radius.circular(0),
                bottomRight: isLandscapeMode ? const Radius.circular(24) : const Radius.circular(0),
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
