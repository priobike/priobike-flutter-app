import 'package:flutter/material.dart';
import 'package:priobike/v2/common/debug.dart';
import 'package:priobike/v2/ride/services/position/mock.dart';
import 'package:priobike/v2/ride/services/position/position.dart';
import 'package:priobike/v2/ride/services/recommendation/mock.dart';
import 'package:priobike/v2/ride/services/recommendation/recommendation.dart';
import 'package:priobike/v2/ride/views/map.dart';
import 'package:priobike/v2/ride/views/speedometer.dart';
import 'package:priobike/v2/routing/services/mock.dart';
import 'package:priobike/v2/routing/services/routing.dart';
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

  @override
  State<StatefulWidget> createState() => RideViewState();
}

class RideViewState extends State<RideView> {
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
