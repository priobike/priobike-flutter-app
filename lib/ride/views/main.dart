import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/accelerometer/services/accelerometer.dart';
import 'package:priobike/common/lock.dart';
import 'package:priobike/dangers/views/button.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/positioning/services/snapping.dart';
import 'package:priobike/ride/views/legacy/default.dart';
import 'package:priobike/ride/views/legacy/minimal_countdown.dart';
import 'package:priobike/ride/views/legacy/minimal_recommendation.dart';
import 'package:priobike/ride/views/map.dart';
import 'package:priobike/ride/views/speedometer.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/rerouting.dart';
import 'package:priobike/settings/models/ride.dart';
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

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      final tracking = Provider.of<Tracking>(context, listen: false);
      final positioning = Provider.of<Positioning>(context, listen: false);
      final accelerometer = Provider.of<Accelerometer>(context, listen: false);
      final ride = Provider.of<Ride>(context, listen: false);
      final session = Provider.of<Session>(context, listen: false);
      final snapping = Provider.of<Snapping>(context, listen: false);
      final routing = Provider.of<Routing>(context, listen: false);

      if (routing.selectedRoute == null) return;
      // Start tracking.
      await tracking.start(context);
      // Authenticate a new session.
      await session.openSession(context);
      // Select the ride.
      await ride.selectRide(context, routing.selectedRoute!);
      // Start navigating.
      await ride.startNavigation(context);
      // Start fetching accelerometer updates.
      await accelerometer.start();
      // Start geolocating. This must only be executed once.
      await positioning.startGeolocation(context: context, onNewPosition: (pos) async {
        // Pass new positions to the ride service.
        await ride.updatePosition(context);
        // Notify the snapping service.
        await snapping.updatePosition(context);
        // Notify the accelerometer service.
        await accelerometer.updatePosition(context);
        // If we are > <x>m from the route and rerouting is enabled, we need to reroute.
        if (
          settings.rerouting == Rerouting.enabled &&
          (snapping.distance ?? 0) > rerouteDistance &&
          (snapping.remainingWaypoints?.isNotEmpty ?? false)
        ) {
          // Use a timed lock to avoid rapid refreshing of routes.
          lock.run(() async {
            await routing.selectWaypoints(snapping.remainingWaypoints);
            final routes = await routing.loadRoutes(context);
            if (routes != null && routes.isNotEmpty) {
              await ride.selectRide(context, routes.first);
            }
          });
        }
      });
    });
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

    Widget? view;
    switch (settings.ridePreference) {
      case RidePreference.speedometerView:
        view = Stack(
          alignment: Alignment.center,
          children: const [
            RideMapView(),
            RideSpeedometerView(),
            DangerButton(),
          ]
        );
        break;
      case RidePreference.defaultCyclingView:
        view = const SafeArea(child: DefaultCyclingView()); 
        break;
      case RidePreference.minimalRecommendationCyclingView:
        view = const SafeArea(child: MinimalRecommendationCyclingView()); 
        break;
      case RidePreference.minimalCountdownCyclingView:
        view = const SafeArea(child: MinimalCountdownCyclingView()); 
        break;
      default:
        view = Container();
    }

    return Scaffold(body: view);
  }
}
