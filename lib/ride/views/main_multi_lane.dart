import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/lock.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/dangers/views/button.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning_multi_lane.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/ride/services/ride_multi_lane.dart';
import 'package:priobike/ride/views/cancel_button_multi_lane.dart';
import 'package:priobike/ride/views/lanes/view_demo.dart';
import 'package:priobike/ride/views/map_multi_lane.dart';
import 'package:priobike/routing/services/routing_multi_lane.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:wakelock/wakelock.dart';

class RideMultiLaneView extends StatefulWidget {
  const RideMultiLaneView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideMultiLaneViewState();
}

class RideMultiLaneViewState extends State<RideMultiLaneView> {
  /// The distance in meters at which a new route is requested.
  static double rerouteDistance = 50;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// A lock that avoids rapid rerouting.
  final lock = Lock(milliseconds: 10000);

  /// Indicating whether the widgets can be loaded or the loading screen should be shown.
  bool ready = false;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);

    // Wait a moment for a clean disposal of the map in the routing view.
    // Without that at the moment it won't dispose correctly causing some weird bugs.
    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
        ready = true;
      });
    });

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        final positioning = getIt<PositioningMultiLane>();
        final routing = getIt<RoutingMultiLane>();
        final dangers = getIt<Dangers>();
        final sgStatus = getIt<PredictionSGStatus>();

        if (routing.selectedRoute == null) return;
        await positioning.selectRoute(routing.selectedRoute);
        await dangers.fetch(routing.selectedRoute!.path, routing.selectedRoute!.route);
        // Start a new session.
        final rideMultiLane = getIt<RideMultiLane>();
        // Set `sessionId` to a random new value and bind the callbacks.
        await rideMultiLane.startNavigation(sgStatus.onNewPredictionStatusDuringRide);
        await rideMultiLane.selectRoute(routing.selectedRoute!);
        // Start geolocating. This must only be executed once.
        await positioning.startGeolocation(
          onNoPermission: () {
            Navigator.of(context).pop();
            showLocationAccessDeniedDialog(context, positioning.positionSource);
          },
          onNewPosition: () async {
            await dangers.calculateUpcomingAndPreviousDangers();
            await rideMultiLane.updatePosition();
            // If we are > <x>m from the route, we need to reroute.
            if ((positioning.snap?.distanceToRoute ?? 0) > rerouteDistance) {
              // Use a timed lock to avoid rapid refreshing of routes.
              lock.run(() async {
                await routing.selectRemainingWaypoints();
                final routes = await routing.loadRoutes();
                if (routes != null && routes.isNotEmpty) {
                  await rideMultiLane.selectRoute(routes.first);
                  await positioning.selectRoute(routes.first);
                  await dangers.fetch(routes.first.path, routes.first.route);
                }
              });
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    settings.removeListener(update);
    super.dispose();
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Tile(
            fill: Theme.of(context).colorScheme.surface,
            content: Center(
              child: SizedBox(
                height: 86,
                width: 256,
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const VSpace(),
                    BoldContent(text: "Lade...", maxLines: 1, context: context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the device active during navigation.
    Wakelock.enable();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: !ready
            ? renderLoadingIndicator()
            : Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: const [
                  RideMapMultiLaneView(),
                  LanesDemoView(),
                  CancelButtonMultiLane(),
                  DangerButton(),
                ],
              ),
      ),
    );
  }
}
