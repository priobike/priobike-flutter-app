import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/positioning/models/snap.dart';
import 'package:provider/provider.dart';

class DangerModal extends StatefulWidget {
  const DangerModal({Key? key, required this.position, required this.onExit}) : super(key: key);

  /// The position of the danger.
  /// We cache the position to avoid the user from traveling away from the
  /// danger, and then reporting it. In this way, we can be sure that the
  /// danger is reported at a near-correct location.
  final Snap? position;

  /// A callback that is called when the modal is closed.
  final void Function() onExit;

  @override
  DangerModalState createState() => DangerModalState();
}

class DangerModalState extends State<DangerModal> {
  @override
  Widget build(BuildContext context) {
    final dangers = Provider.of<Dangers>(context, listen: false);
    return Stack(children: [
      GestureDetector(
        onTap: widget.onExit,
        child: Container(
          color: Colors.black.withOpacity(0.2),
        ),
      ),
      // A small triangle at the top of the modal.
      Positioned(
        top: 72,
        left: 76,
        child: SafeArea(
          child: Transform.rotate(
            angle: 45 * pi / 180,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.07),
                ),
                color: Theme.of(context).colorScheme.background,
              ),
            ),
          ),
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 48, left: 82, right: 16), // Fit the danger button.
          child: Tile(
            fill: Theme.of(context).colorScheme.background,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SubHeader(text: "Gefahr melden", context: context),
                const SmallVSpace(),
                Tile(
                  fill: Theme.of(context).colorScheme.surface,
                  onPressed: () {
                    dangers.submitNew(context, widget.position, "potholes");
                    ToastMessage.showSuccess("Schlechte Straße gemeldet!");
                    widget.onExit();
                  },
                  content: Row(
                    children: [
                      Image.asset("assets/images/potholes.png", height: 50),
                      const SmallHSpace(),
                      Flexible(
                        child: BoldSubHeader(
                          text: "Schlechte Straße",
                          context: context,
                        ),
                      ),
                    ],
                  ),
                ),
                const SmallVSpace(),
                Tile(
                  fill: Theme.of(context).colorScheme.surface,
                  onPressed: () {
                    dangers.submitNew(context, widget.position, "obstacle");
                    ToastMessage.showSuccess("Hindernis gemeldet!");
                    widget.onExit();
                  },
                  content: Row(
                    children: [
                      Image.asset("assets/images/obstacle.png", height: 50),
                      const SmallHSpace(),
                      Flexible(
                        child: BoldSubHeader(
                          text: "Hindernis",
                          context: context,
                        ),
                      ),
                    ],
                  ),
                ),
                const SmallVSpace(),
                Tile(
                  fill: Theme.of(context).colorScheme.surface,
                  onPressed: () {
                    dangers.submitNew(context, widget.position, "dangerspot");
                    ToastMessage.showSuccess("Gefahrenstelle gemeldet!");
                    widget.onExit();
                  },
                  content: Row(
                    children: [
                      Image.asset("assets/images/dangerspot.png", height: 50),
                      const SmallHSpace(),
                      Flexible(
                        child: BoldSubHeader(
                          text: "Gefahrenstelle",
                          context: context,
                        ),
                      ),
                    ],
                  ),
                ),
                const SmallVSpace(),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: CI.green,
                      width: 3,
                    ),
                    color: CI.green.withOpacity(0.25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Content(text: "Position vorgemerkt ✓", context: context),
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}
