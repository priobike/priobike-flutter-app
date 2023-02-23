import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/ride/services/ride.dart';

class RideSGButton extends StatefulWidget {
  const RideSGButton({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideSGButtonState();
}

class RideSGButtonState extends State<RideSGButton> {
  /// The ride service which is injected by the provider.
  late Ride ride;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  @override
  void initState() {
    super.initState();
    update = () => setState(() {});
    ride = getIt.get<Ride>();
    ride.addListener(update);
  }

  @override
  void dispose() {
    ride.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Display nothing if there are no signal groups.
    if (ride.route?.signalGroups == null || ride.route!.signalGroups.isEmpty) return Container();
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
              onPressed: () => ride.jumpToSG(step: 1), // Jump forward.
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
              onPressed: ride.unselectSG,
              content: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: ride.userSelectedSG == null ? 1 : 0.2,
                        child: Image(
                          image: AssetImage(
                            Theme.of(context).brightness == Brightness.light
                                ? "assets/images/trafficlights/traffic-light-light.png"
                                : "assets/images/trafficlights/traffic-light-dark.png",
                          ),
                        ),
                      ),
                      ride.userSelectedSG == null
                          ? Container()
                          : Icon(
                              Icons.close_rounded,
                              size: 24,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                    ],
                  ),
                ),
              ),
            ),
            Tile(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(32),
              ),
              fill: Theme.of(context).colorScheme.background.withOpacity(0.75),
              onPressed: () => ride.jumpToSG(step: -1), // Jump backward.
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
