import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/lock.dart';
import 'package:priobike/positioning/services/estimator.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/positioning/services/snapping.dart';
import 'package:priobike/ride/views/legacy/default.dart';
import 'package:priobike/ride/views/legacy/default_debug.dart';
import 'package:priobike/ride/views/legacy/minimal_countdown.dart';
import 'package:priobike/ride/views/legacy/minimal_json.dart';
import 'package:priobike/ride/views/legacy/minimal_navigation.dart';
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

  /// The associated tracking service, which is injected by the provider.
  Tracking? tracking;

  /// The associated position service, which is injected by the provider.
  Positioning? positioning;

  /// The associated position estimation service, which is injected by the provider.
  PositionEstimator? positionEstimator;

  /// The associated recommendation service, which is injected by the provider.
  Ride? ride;

  /// The associated session service, which is injected by the provider.
  Session? session;

  /// The associated snapping service, which is injected by the provider.
  Snapping? snapping;

  /// The associated routing service, which is injected by the provider.
  Routing? routing;

  /// The associated settings service, which is injected by the provider.
  Settings? settings;

  /// Get the initial page index.
  /// Note: Make sure that the indices match the order of the pages.
  int get initialPage {
    switch (settings?.ridePreference) {
      case RidePreference.speedometerView:
        return 0;
      case RidePreference.defaultCyclingView:
        return 1;
      case RidePreference.minimalRecommendationCyclingView:
        return 2;
      case RidePreference.minimalCountdownCyclingView:
        return 3;
      default:
        return 0;
    }
  }

  /// The lock for the rerouting.
  final lock = Lock(milliseconds: 10000);

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      if (routing?.selectedRoute == null) return;
      // Start tracking.
      await tracking?.start(context);
      // Authenticate a new session.
      await session?.openSession(context);
      // Select the ride.
      await ride?.selectRide(context, routing!.selectedRoute!);
      // Start navigating.
      await ride?.startNavigation(context);
      // Start the position estimation.
      await positionEstimator?.startEstimating(context);
      // Start geolocating. This must only be executed once.
      await positioning?.startGeolocation(context: context, onNewPosition: (pos) async {
        // Pass new positions to the ride service.
        await ride?.updatePosition(context);
        // Notify the snapping service.
        await snapping?.updatePosition(context);
        // If we are > <x>m from the route and rerouting is enabled, we need to reroute.
        if (
          settings?.rerouting == Rerouting.enabled &&
          (snapping?.distance ?? 0) > rerouteDistance &&
          (snapping?.remainingWaypoints?.isNotEmpty ?? false)
        ) {
          // Use a timed lock to avoid rapid refreshing of routes.
          lock.run(() async {
            await routing?.selectWaypoints(snapping!.remainingWaypoints);
            final routes = await routing?.loadRoutes(context);
            if (routes != null && routes.isNotEmpty) {
              await ride?.selectRide(context, routes.first);
            }
          });
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    tracking = Provider.of<Tracking>(context);
    positioning = Provider.of<Positioning>(context);
    positionEstimator = Provider.of<PositionEstimator>(context);
    ride = Provider.of<Ride>(context);
    session = Provider.of<Session>(context);
    snapping = Provider.of<Snapping>(context);
    routing = Provider.of<Routing>(context);
    settings = Provider.of<Settings>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the device active during navigation.
    Wakelock.enable();

    final PageController controller = PageController(initialPage: initialPage);
    return Scaffold(body: PageView(
      controller: controller,
      children: <Widget>[
        // RidePreference.speedometerView
        Stack(
          alignment: Alignment.center,
          children: const [
            RideMapView(),
            RideSpeedometerView(),
          ]
        ),

        // RidePreference.defaultCyclingView
        const SafeArea(child: DefaultCyclingView()),

        // RidePreference.minimalRecommendationCyclingView
        const SafeArea(child: MinimalRecommendationCyclingView()),

        // RidePreference.minimalCountdownCyclingView
        const SafeArea(child: MinimalCountdownCyclingView()),

        // Other debug views.
        if (kDebugMode) const SafeArea(child: MinimalNavigationCyclingView()),
        if (kDebugMode) const SafeArea(child: DefaultDebugCyclingView()),
        if (kDebugMode) const SafeArea(child: MinimalDebugCyclingView()),
      ],
    ));
  }
}
