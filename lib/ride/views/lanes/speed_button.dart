import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning_multi_lane.dart';
import 'package:priobike/positioning/sources/mock.dart';

class SpeedButton extends StatefulWidget {
  const SpeedButton({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SpeedButtonState();
}

class SpeedButtonState extends State<SpeedButton> {
  /// The positioning service which is injected by the provider.
  late PositioningMultiLane positioningMultiLane;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    positioningMultiLane = getIt<PositioningMultiLane>();
    positioningMultiLane.addListener(update);
  }

  @override
  void dispose() {
    positioningMultiLane.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Display nothing if no mock positioning source is used.
    if (positioningMultiLane.positionSource is! PathMockPositionSource) return Container();

    final currentSpeed = positioningMultiLane.lastPosition?.speed ?? 0;

    return Positioned(
      top: 128,
      left: 0,
      child: SafeArea(
        child: Column(
          children: [
            Tile(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(32),
              ),
              fill: Theme.of(context).colorScheme.background.withOpacity(0.75),
              onPressed: () => positioningMultiLane.setDebugSpeed(currentSpeed + 1), // Jump forward.
              content: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
            ),
            Tile(
              borderRadius: const BorderRadius.only(),
              fill: Theme.of(context).colorScheme.background.withOpacity(0.75),
              content: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                    child: Small(
                  text: "${positioningMultiLane.lastPosition?.speed.toString() ?? '0'}m/s",
                  context: context,
                )),
              ),
            ),
            Tile(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(32),
              ),
              fill: Theme.of(context).colorScheme.background.withOpacity(0.75),
              onPressed: () => positioningMultiLane.setDebugSpeed(currentSpeed - 1), // Jump backward.
              content: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
