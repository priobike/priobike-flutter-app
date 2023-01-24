import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/accelerometer/services/accelerometer.dart';
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
import 'package:priobike/ride/views/speedometer.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/models/rerouting.dart';
import 'package:priobike/settings/services/settings.dart';
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
  static double rerouteDistance = 50;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The lock for the rerouting.
  final lock = Lock(milliseconds: 10000);

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback(
          (_) async {
        final tracking = Provider.of<Tracking>(context, listen: false);
        final positioning = Provider.of<Positioning>(context, listen: false);
        final accelerometer = Provider.of<Accelerometer>(context, listen: false);
        final datastream = Provider.of<Datastream>(context, listen: false);
        final routing = Provider.of<Routing>(context, listen: false);
        final dangers = Provider.of<Dangers>(context, listen: false);

        if (routing.selectedRoute == null) return;
        await positioning.selectRoute(routing.selectedRoute);
        await dangers.fetch(routing.selectedRoute!, context);
        // Start a new session.
        final ride = Provider.of<Ride>(context, listen: false);
        await ride.startNavigation(context); // Sets `sessionId` to a random new value.
        await ride.selectRoute(context, routing.selectedRoute!);
        // Start tracking once the `sessionId` is set.
        await tracking.start(context);
        // Connect the datastream mqtt client, if the user enabled real-time data.
        final settings = Provider.of<Settings>(context, listen: false);
        if (settings.datastreamMode == DatastreamMode.enabled) {
          await datastream.connect(context);
          // Link the ride to the datastream.
          ride.onSelectNextSignalGroup = (sg) => datastream.select(sg: sg);
        }
        // Start fetching accelerometer updates.
        await accelerometer.start();
        // Start geolocating. This must only be executed once.
        await positioning.startGeolocation(
          context: context,
          onNewPosition: () async {
            await dangers.calculateUpcomingAndPreviousDangers(context);
            await ride.updatePosition(context);
            // Notify the accelerometer service.
            await accelerometer.updatePosition(context);
            // If we are > <x>m from the route and rerouting is enabled, we need to reroute.
            if (settings.rerouting == Rerouting.enabled && (positioning.snap?.distanceToRoute ?? 0) > rerouteDistance) {
              // Use a timed lock to avoid rapid refreshing of routes.
              lock.run(() async {
                await routing.selectRemainingWaypoints(context);
                final routes = await routing.loadRoutes(context);
                if (routes != null && routes.isNotEmpty) {
                  await ride.selectRoute(context, routes.first);
                  await positioning.selectRoute(routes.first);
                  await dangers.fetch(routes.first, context);
                }
              });
            }
          },
        );
      },
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

    return Scaffold(
      body: ScreenTrackingView(
        child: Stack(
          alignment: Alignment.center,
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
    );
  }
}