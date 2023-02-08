import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/lock.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/dangers/views/button.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/ride/views/datastream.dart';
import 'package:priobike/ride/views/map.dart';
import 'package:priobike/ride/views/screen_tracking.dart';
import 'package:priobike/ride/views/sg_button.dart';
import 'package:priobike/ride/views/speedometer/view.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

class RideView extends StatefulWidget {
  const RideView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideViewState();
}

class RideViewState extends State<RideView> {
  /// The distance in meters at which a new route is requested.
  static double rerouteDistance = 20;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// A lock that avoids rapid rerouting.
  final lock = Lock(milliseconds: 10000);

  /// Indicating whether the widgets can be loaded or the loading screen should be shown.
  bool ready = false;

  @override
  void initState() {
    super.initState();

    // Wait a moment for a clean disposal of the map in the routing view.
    // Without that at the moment it won't dispose correctly causing some weird bugs.
    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
        ready = true;
      });
    });

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        final tracking = Provider.of<Tracking>(context, listen: false);
        final positioning = Provider.of<Positioning>(context, listen: false);
        final datastream = Provider.of<Datastream>(context, listen: false);
        final routing = Provider.of<Routing>(context, listen: false);
        final dangers = Provider.of<Dangers>(context, listen: false);
        final sgStatus = Provider.of<PredictionSGStatus>(context, listen: false);

        if (routing.selectedRoute == null) return;
        await positioning.selectRoute(routing.selectedRoute);
        await dangers.fetch(routing.selectedRoute!, context);
        // Start a new session.
        final ride = Provider.of<Ride>(context, listen: false);
        // Set `sessionId` to a random new value and bind the callbacks.
        await ride.startNavigation(context, sgStatus.onNewPredictionStatusDuringRide);
        await ride.selectRoute(context, routing.selectedRoute!);
        // Connect the datastream mqtt client, if the user enabled real-time data.
        final settings = Provider.of<Settings>(context, listen: false);
        if (settings.datastreamMode == DatastreamMode.enabled) {
          await datastream.connect(context);
          // Link the ride to the datastream.
          ride.onSelectNextSignalGroup = (sg) => datastream.select(sg: sg);
        }
        // Start geolocating. This must only be executed once.
        await positioning.startGeolocation(
          context: context,
          onNewPosition: () async {
            await dangers.calculateUpcomingAndPreviousDangers(context);
            await ride.updatePosition(context);
            await tracking.updatePosition(context);
            // If we are > <x>m from the route, we need to reroute.
            if ((positioning.snap?.distanceToRoute ?? 0) > rerouteDistance) {
              // Use a timed lock to avoid rapid refreshing of routes.
              lock.run(() async {
                await routing.selectRemainingWaypoints(context);
                final routes = await routing.loadRoutes(context);
                if (routes != null && routes.isNotEmpty) {
                  await ride.selectRoute(context, routes.first);
                  await positioning.selectRoute(routes.first);
                  await dangers.fetch(routes.first, context);
                  await tracking.selectRoute(routes.first);
                }
              });
            }
          },
        );
        // Start tracking once the `sessionId` is set and the positioning stream is available.
        await tracking.start(context);
      },
    );
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
  void didChangeDependencies() {
    settings = Provider.of<Settings>(context);
    super.didChangeDependencies();
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
            : ScreenTrackingView(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: const [
                    RideMapView(),
                    RideSpeedometerView(),
                    DatastreamView(),
                    RideSGButton(),
                    DangerButton(),
                  ],
                ),
              ),
      ),
    );
  }
}
