import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/positioning/services/estimator.dart';
import 'package:priobike/positioning/services/position.dart';
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

  /// The associated position service, which is injected by the provider.
  PositionService? positionService;

  /// The associated position estimation service, which is injected by the provider.
  PositionEstimatorService? positionEstimatorService;

  /// The associated recommendation service, which is injected by the provider.
  RideService? rideService;

  /// The associated session service, which is injected by the provider.
  SessionService? sessionService;

  /// The associated snapping service, which is injected by the provider.
  SnappingService? snappingService;

  /// The associated routing service, which is injected by the provider.
  RoutingService? routingService;

  /// The associated settings service, which is injected by the provider.
  SettingsService? settingsService;

  /// Get the initial page index.
  /// Note: Make sure that the indices match the order of the pages.
  int get initialPage {
    switch (settingsService?.ridePreference) {
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

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      if (routingService?.selectedRoute == null) return;
      // Authenticate a new session.
      await sessionService?.openSession(context);
      // Select the ride.
      await rideService?.selectRide(context, routingService!.selectedRoute!);
      // Start navigating.
      await rideService?.startNavigation(context);
      // Start the position estimation.
      await positionEstimatorService?.startEstimating(context);
      // Start geolocating. This must only be executed once.
      await positionService?.startGeolocation(context: context, onNewPosition: (pos) async {
        // Pass new positions to the ride service.
        await rideService?.updatePosition(context);
        // Notify the snapping service.
        await snappingService?.updatePosition(context);
        // If we are > <x>m from the route and rerouting is enabled, we need to reroute.
        if (
          settingsService?.rerouting == Rerouting.enabled && 
          (snappingService?.distance ?? 0) > rerouteDistance && 
          (snappingService?.remainingWaypoints?.isNotEmpty ?? false)
        ) {
          await routingService?.selectWaypoints(snappingService!.remainingWaypoints);
          final response = await routingService?.loadRoutes(context);
          if (response != null || response!.routes.isNotEmpty) {
            await rideService?.selectRide(context, response.routes.first);
          }
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    positionService = Provider.of<PositionService>(context);
    positionEstimatorService = Provider.of<PositionEstimatorService>(context);
    rideService = Provider.of<RideService>(context);
    sessionService = Provider.of<SessionService>(context);
    snappingService = Provider.of<SnappingService>(context);
    routingService = Provider.of<RoutingService>(context);
    settingsService = Provider.of<SettingsService>(context);
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
