import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride_multi_lane.dart';

class LaneContainerWidget extends StatefulWidget {
  const LaneContainerWidget({Key? key, required this.sgId}) : super(key: key);

  final String sgId;

  @override
  LaneContainerWidgetState createState() => LaneContainerWidgetState();
}

class LaneContainerWidgetState extends State<LaneContainerWidget> {
  /// The associated ride service, which is injected by the provider.
  /*late RideMultiLane ride;*/

  /// The default gauge color for the speedometer.
  static const defaultGaugeColor = Color.fromARGB(255, 50, 50, 50);

  Timer? gradientUpdateTimer;

  List<double> stops = [];
  List<Color> colors = [];

  /// Called when a listener callback of a ChangeNotifier is fired. Don't rebuild when the gradient gets updated.
/*  void update() {
    updateGradient();
    setState(() {});
  }*/

  @override
  void initState() {
    super.initState();

    /*ride = getIt<RideMultiLane>();
    ride.addListener(update);*/

    gradientUpdateTimer = Timer.periodic(const Duration(milliseconds: 40), (_) => updateGradient());
  }

  @override
  void dispose() {
    gradientUpdateTimer?.cancel();
    /*ride.removeListener(update);*/
    super.dispose();
  }

  Future<void> updateGradient() async {
    if (getIt<RideMultiLane>().predictionServiceMultiLane == null) {
      colors = [defaultGaugeColor, defaultGaugeColor];
      stops = [0.0, 1.0];
      return;
    }

    if (getIt<RideMultiLane>().predictionServiceMultiLane!.predictions[widget.sgId] == null) {
      colors = [defaultGaugeColor, defaultGaugeColor];
      stops = [0.0, 1.0];
      return;
    }

    final prediction = getIt<RideMultiLane>().predictionServiceMultiLane!.predictions[widget.sgId];
    final recommendation = await prediction!.calculateRecommendation();

    if (recommendation == null) {
      colors = [defaultGaugeColor, defaultGaugeColor];
      stops = [0.0, 1.0];
      return;
    }

    final phases = recommendation.calcPhasesFromNow;
    final qualities = recommendation.calcQualitiesFromNow;

    colors = <Color>[];
    for (var i = 0; i < phases.length; i++) {
      final phase = phases[i];
      final quality = max(0, qualities[i]);
      final opacity = quality;
      colors.add(Color.lerp(defaultGaugeColor, phase.color, opacity.toDouble()) ?? defaultGaugeColor);
    }

    colors = colors;

    stops = Iterable<double>.generate(
      colors.length,
      (second) {
        // 0.005m/ms = 5m/s = 18km/h
        final distanceInMeterBeforeStopLine = second * 5;
        final relativeDistance = distanceInMeterBeforeStopLine / RideMultiLane.preDistance;
        final clampedRelativeDistance = relativeDistance.clamp(0.0, 1.0);

        return clampedRelativeDistance;
      },
    ).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        //color: Colors.greenAccent,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors ?? [],
          stops: stops ?? [],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
