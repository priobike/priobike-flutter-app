import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/logging/logger.dart';

class FinishRideButton extends StatefulWidget {
  final Function(BuildContext) onTapFinishRide;

  const FinishRideButton({Key? key, required this.onTapFinishRide}) : super(key: key);

  @override
  FinishRideButtonState createState() => FinishRideButtonState();
}

class FinishRideButtonState extends State<FinishRideButton> {
  final log = Logger("FinishButton");

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
          onPressed: () => widget.onTapFinishRide(context),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 48, // Below the MapBox attribution.
          right: 0,
          child: SafeArea(
            child: Tile(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => askForConfirmation(context),
              ),
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
