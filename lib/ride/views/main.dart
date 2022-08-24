import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/ride/messages/recommendation.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/reroute.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/ride/views/legacy/default.dart';
import 'package:priobike/ride/views/legacy/default_debug.dart';
import 'package:priobike/ride/views/legacy/minimal_countdown.dart';
import 'package:priobike/ride/views/legacy/minimal_json.dart';
import 'package:priobike/ride/views/legacy/minimal_navigation.dart';
import 'package:priobike/ride/views/legacy/minimal_recommendation.dart';
import 'package:priobike/ride/views/map.dart';
import 'package:priobike/ride/views/speedometer.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/ride.dart';
import 'package:priobike/settings/service.dart';
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

  /// Render an info bar (TODO).
  Widget renderInfoBar(Recommendation r) {
    return Positioned(
      top: 64,
      right: 0,
      child: Tile(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24), 
          bottomLeft: Radius.circular(24)
        ),
        fill: Colors.white,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            BoldSubHeader(
              text: "Noch ${r.countdown}s ${r.isGreen ? 'grün' : 'rot'}",
              color: r.isGreen 
                ? const Color.fromARGB(255, 50, 180, 50) 
                : const Color.fromARGB(255, 208, 19, 19),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the device active during navigation.
    Wakelock.enable();

    final PageController controller = PageController();
    return Scaffold(body: PageView(
      /// [PageView.scrollDirection] defaults to [Axis.horizontal].
      /// Use [Axis.vertical] to scroll vertically.
      controller: controller,
      physics: settingsService?.rideViewsMode == RideViewsMode.onlySpeedometerView
        ? const NeverScrollableScrollPhysics() 
        : null,
      children: <Widget>[
        Stack(
          alignment: Alignment.center,
          children: [
            const RideMapView(),
            const RideSpeedometerView(),
            if (rideService?.currentRecommendation != null && !rideService!.currentRecommendation!.error) 
              renderInfoBar(rideService!.currentRecommendation!),
          ]
        ),

        // Alternative ride views.
        const SafeArea(child: DefaultCyclingView()),
        const SafeArea(child: MinimalRecommendationCyclingView()),
        const SafeArea(child: MinimalCountdownCyclingView()),
        const SafeArea(child: MinimalNavigationCyclingView()),
        const SafeArea(child: DefaultDebugCyclingView()),
        const SafeArea(child: MinimalDebugCyclingView()),
      ],
    ));
  }
}
