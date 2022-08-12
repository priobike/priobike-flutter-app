import 'package:flutter/material.dart';
import 'package:priobike/common/debug.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/ride/services/position/mock.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/recommendation/mock.dart';
import 'package:priobike/ride/services/recommendation/recommendation.dart';
import 'package:priobike/ride/views/map.dart';
import 'package:priobike/ride/views/speedometer.dart';
import 'package:priobike/routing/services/mock.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/session/services/session.dart';
import 'package:provider/provider.dart';

void main() => debug(MultiProvider(
  providers: [
    ChangeNotifierProvider<RoutingService>(
      create: (context) => MockRoutingService(),
    ),
    ChangeNotifierProvider<PositionService>(
      create: (context) => StaticMockPositionService(),
    ),
    ChangeNotifierProvider<RecommendationService>(
      create: (context) => MockRecommendationService(),
    ),
  ],
  child: const RideView(),
));

class RideView extends StatefulWidget {
  const RideView({Key? key}) : super(key: key);

  /// Create the view with necessary providers from the app view hierarchy.
  static Widget withinAppHierarchy(BuildContext context) {
    // Fetch the necessary view models from the build context.
    final ss = Provider.of<SessionService>(context, listen: false);
    final rs = Provider.of<RoutingService>(context, listen: false);

    return Scaffold(body: MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionService>(create: (c) => ss),
        ChangeNotifierProvider<RoutingService>(create: (c) => rs),
        // TODO: Use the real position source.
        ChangeNotifierProvider<PositionService>(create: (c) => PathMockPositionService(
          positions: rs.selectedRoute!.nodes.map((e) => LatLng(e.lat, e.lon)).toList(),
          speed: 18 / 3.6,
        )),
        ChangeNotifierProvider<RecommendationService>(create: (c) => RecommendationService()),
      ],
      child: const RideView(),
    ));
  }

  @override
  State<StatefulWidget> createState() => RideViewState();
}

class RideViewState extends State<RideView> {
  /// The associated position service, which is injected by the provider.
  late PositionService ps;

  /// The associated recommendation service, which is injected by the provider.
  late RecommendationService rs;

  @override
  void didChangeDependencies() {
    ps = Provider.of<PositionService>(context);
    rs = Provider.of<RecommendationService>(context);

    // Execute once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // Start navigating.
      await rs.startNavigation(context);
      // Start geolocating and pass new positions to the recommendation service.
      await ps.startGeolocation(context, (pos) => rs.updatePosition(context, pos));
    });

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    ps.stopGeolocation();
    rs.stopNavigation(context);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        RideMapView(),
        RideSpeedometerView(),
      ]
    );
  }
}
