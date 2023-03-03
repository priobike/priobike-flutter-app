import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/lock.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/dangers/views/button.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/ride/views/datastream.dart';
import 'package:priobike/ride/views/map.dart';
import 'package:priobike/ride/views/screen_tracking.dart';
import 'package:priobike/ride/views/sg_button.dart';
import 'package:priobike/ride/views/speedometer/view.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tracking/services/tracking.dart';
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
        final deviceWidth = MediaQuery.of(context).size.width;
        final deviceHeight = MediaQuery.of(context).size.height;

        final tracking = getIt<Tracking>();
        final positioning = getIt<Positioning>();
        final datastream = getIt<Datastream>();
        final routing = getIt<Routing>();
        final dangers = getIt<Dangers>();
        final sgStatus = getIt<PredictionSGStatus>();

        if (routing.selectedRoute == null) return;
        await positioning.selectRoute(routing.selectedRoute);
        await dangers.fetch(routing.selectedRoute!.path,
            routing.selectedRoute!.route.map((e) => NavigationNodeMultiLane.fromNavigationNode(e)).toList());
        // Start a new session.
        final ride = getIt<Ride>();
        // Set `sessionId` to a random new value and bind the callbacks.
        await ride.startNavigation(sgStatus.onNewPredictionStatusDuringRide);
        await ride.selectRoute(routing.selectedRoute!);
        // Connect the datastream mqtt client, if the user enabled real-time data.
        final settings = getIt<Settings>();
        if (settings.datastreamMode == DatastreamMode.enabled) {
          await datastream.connect();
          // Link the ride to the datastream.
          ride.onSelectNextSignalGroup = (sg) => datastream.select(sg: sg);
        }
        // Start geolocating. This must only be executed once.
        await positioning.startGeolocation(
          onNoPermission: () {
            Navigator.of(context).pop();
            showLocationAccessDeniedDialog(context, positioning.positionSource);
          },
          onNewPosition: () async {
            await dangers.calculateUpcomingAndPreviousDangers();
            await ride.updatePosition();
            await tracking.updatePosition();
            // If we are > <x>m from the route, we need to reroute.
            if ((positioning.snap?.distanceToRoute ?? 0) > rerouteDistance) {
              // Use a timed lock to avoid rapid refreshing of routes.
              lock.run(() async {
                await routing.selectRemainingWaypoints();
                final routes = await routing.loadRoutes();
                if (routes != null && routes.isNotEmpty) {
                  await ride.selectRoute(routes.first);
                  await positioning.selectRoute(routes.first);
                  await dangers.fetch(
                      routes.first.path,
                      List.from(
                          [routing.selectedRoute!.route.map((e) => NavigationNodeMultiLane.fromNavigationNode(e))]));
                  await tracking.selectRoute(routes.first);
                }
              });
            }
          },
        );

        // Start tracking once the `sessionId` is set and the positioning stream is available.
        await tracking.start(deviceWidth, deviceHeight);
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
