import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning_multi_lane.dart';
import 'package:priobike/ride/services/ride_multi_lane.dart';
import 'package:priobike/routing/services/routing_multi_lane.dart';
import 'package:priobike/status/services/sg.dart';

class CancelButtonMultiLane extends StatefulWidget {
  /// The border radius of the button.
  final double borderRadius;

  /// The text of the button.
  final String text;

  /// Create a new cancel button.
  const CancelButtonMultiLane({this.borderRadius = 32, this.text = "Fertig", Key? key}) : super(key: key);

  @override
  CancelButtonMulitLaneState createState() => CancelButtonMulitLaneState();
}

/// A cancel button to cancel the ride.
class CancelButtonMulitLaneState extends State<CancelButtonMultiLane> {
  Widget askForConfirmation(BuildContext context) {
    return AlertDialog(
      //contentPadding: const EdgeInsets.all(30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
      title: SubHeader(
        text: "Fahrt wirklich beenden?",
        context: context,
      ),
      content: Content(
        text: "Wenn du die Fahrt beendest, musst du erst eine neue Route erstellen, um eine neue Fahrt zu starten.",
        context: context,
      ),
      actions: [
        TextButton(
          onPressed: () => onTap(),
          style: ButtonStyle(
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: BoldSubHeader(
            text: 'Ja',
            context: context,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ButtonStyle(
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: BoldSubHeader(
            text: 'Nein',
            context: context,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// A callback that is executed when the cancel button is pressed.
  Future<void> onTap() async {
    // End the recommendations.
    final ride = getIt<RideMultiLane>();
    await ride.stopNavigation();

    // Stop the geolocation.
    final position = getIt<PositioningMultiLane>();
    await position.stopGeolocation();

    // Reset the ride service.
    await ride.reset();

    // Reset the position service.
    await position.reset();

    // Reset the route service.
    final routing = getIt<RoutingMultiLane>();
    await routing.reset();

    // Reset the prediction sg status.
    final predictionSGStatus = getIt<PredictionSGStatus>();
    await predictionSGStatus.reset();

    // Reset the dangers.
    final dangers = getIt<Dangers>();
    await dangers.reset();

    if (context.mounted) {
      // Leave the feedback view.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.flag_rounded),
          label: BoldSmall(
            text: widget.text,
            context: context,
            color: Colors.white,
          ),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => askForConfirmation(context),
          ),
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
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
