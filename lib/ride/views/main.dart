import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/reroute.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/ride/views/button.dart';
import 'package:priobike/ride/views/legacy/default.dart';
import 'package:priobike/ride/views/legacy/default_debug.dart';
import 'package:priobike/ride/views/legacy/minimal_countdown.dart';
import 'package:priobike/ride/views/legacy/minimal_json.dart';
import 'package:priobike/ride/views/legacy/minimal_navigation.dart';
import 'package:priobike/ride/views/legacy/minimal_recommendation.dart';
import 'package:priobike/ride/views/map.dart';
import 'package:priobike/ride/views/speedometer.dart';
import 'package:priobike/ride/views/trafficlight.dart';
import 'package:priobike/routing/services/routing.dart';
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
  /// The associated position service, which is injected by the provider.
  PositionService? positionService;

  /// The associated recommendation service, which is injected by the provider.
  RideService? rideService;

  /// The associated session service, which is injected by the provider.
  SessionService? sessionService;

  /// The associated reroute service, which is injected by the provider.
  RerouteService? rerouteService;

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
      case RidePreference.minimalNavigationCyclingView:
        return 4;
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
      // Check for reroutes.
      await rerouteService?.runRerouteScheduler(context);
      // Start geolocating and pass new positions to the recommendation service.
      await positionService?.startGeolocation(context, (pos) => rideService?.updatePosition(context, pos));
    });
  }

  @override
  void didChangeDependencies() {
    positionService = Provider.of<PositionService>(context);
    rideService = Provider.of<RideService>(context);
    sessionService = Provider.of<SessionService>(context);
    rerouteService = Provider.of<RerouteService>(context);
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
            Positioned(child: SafeArea(child: CancelButton()), top: 8, left: 8)
          ]
        ),

        // RidePreference.defaultCyclingView
        const SafeArea(child: DefaultCyclingView()),

        // RidePreference.minimalRecommendationCyclingView
        const SafeArea(child: MinimalRecommendationCyclingView()),

        // RidePreference.minimalCountdownCyclingView
        const SafeArea(child: MinimalCountdownCyclingView()),

        // RidePreference.minimalNavigationCyclingView
        const SafeArea(child: MinimalNavigationCyclingView()),

        // Other debug views.
        if (kDebugMode) const SafeArea(child: DefaultDebugCyclingView()),
        if (kDebugMode) const SafeArea(child: MinimalDebugCyclingView()),
      ],
    ));
  }
}
