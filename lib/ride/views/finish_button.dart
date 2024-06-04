import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
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

class FinishRideButton extends StatelessWidget {
  final log = Logger("FinishButton");

  FinishRideButton({super.key});

  void showAskForConfirmationDialog(BuildContext context) {
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
          title: 'Fahrt wirklich beenden?',
          text: "Wenn Du die Fahrt beendest, musst Du erst eine neue Route erstellen, um eine neue Fahrt zu starten.",
          actions: [
            BigButtonPrimary(
              label: "Fahrt beenden",
              onPressed: () => endRide(context),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
            ),
            BigButtonTertiary(
              label: "Abbrechen",
              addPadding: false,
              onPressed: () => Navigator.of(context).pop(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
            ),
          ],
        );
      },
    );
  }

  /// A callback that is executed when the cancel button is pressed.
  Future<void> endRide(context) async {
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
    if (context.mounted) {
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

    return Positioned(
      top: 48, // Below the MapBox attribution.
      // Button is on the right in portrait mode and on the left in landscape mode.
      right: isLandscapeMode ? null : 0,
      left: isLandscapeMode ? 8 : null,
      child: SafeArea(
        child: SizedBox(
          width: 72,
          height: 72,
          child: Tile(
            onPressed: () => showAskForConfirmationDialog(context),
            padding: const EdgeInsets.all(10),
            borderRadius: isLandscapeMode
                ? const BorderRadius.all(Radius.circular(24))
                : const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
            fill: Theme.of(context).colorScheme.surfaceVariant,
            content: Icon(
              Icons.close_rounded,
              size: 36,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
