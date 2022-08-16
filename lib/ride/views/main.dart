import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/debug.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/ride/messages/recommendation.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/recommendation/mock.dart';
import 'package:priobike/ride/services/recommendation/recommendation.dart';
import 'package:priobike/ride/views/map.dart';
import 'package:priobike/ride/views/speedometer.dart';
import 'package:priobike/routing/services/mock.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

void main() => debug(MultiProvider(
  providers: [
    ChangeNotifierProvider<RoutingService>(
      create: (context) => MockRoutingService(),
    ),
    ChangeNotifierProvider<PositionService>(
      create: (context) => PositionService(),
    ),
    ChangeNotifierProvider<RecommendationService>(
      create: (context) => MockRecommendationService(),
    ),
  ],
  child: const RideView(),
));

class RideView extends StatefulWidget {
  const RideView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideViewState();
}

class RideViewState extends State<RideView> {
  /// The associated position service, which is injected by the provider.
  PositionService? ps;

  /// The associated recommendation service, which is injected by the provider.
  RecommendationService? rs;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      // Start navigating.
      await rs?.startNavigation(context);
      // Start geolocating and pass new positions to the recommendation service.
      await ps?.startGeolocation(context, (pos) => rs?.updatePosition(context, pos));
    });
  }

  @override
  void didChangeDependencies() {
    ps = Provider.of<PositionService>(context);
    rs = Provider.of<RecommendationService>(context);
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
              text: "Noch ${r.countdown}s ${r.green ? 'grün' : 'rot'}",
              color: r.green 
                ? const Color.fromARGB(255, 0, 255, 0) 
                : const Color.fromARGB(255, 255, 0, 0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const RideMapView(),
        const RideSpeedometerView(),
        if (rs?.currentRecommendation != null) renderInfoBar(rs!.currentRecommendation!),
      ]
    );
  }
}
