import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';

class RideTrafficLightView extends StatefulWidget {
  /// The size of the speedometer.
  final Size size;

  const RideTrafficLightView({super.key, required this.size});

  @override
  State<StatefulWidget> createState() => RideTrafficLightViewState();
}

class RideTrafficLightViewState extends State<RideTrafficLightView> {
  /// The associated ride service, which is injected by the provider.
  late Ride ride;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    ride = getIt<Ride>();
    ride.addListener(update);
  }

  @override
  void dispose() {
    ride.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alternativeView = Container(
        width: widget.size.width * 0.35,
        height: widget.size.width * 0.35,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
            child: BoldContent(
          textAlign: TextAlign.center,
          text: "Keine\nPrognosen",
          color: Colors.white,
          context: context,
        )));

    // Don't show a countdown if...
    if (ride.calcCurrentSG == null) return alternativeView;

    // Check if we have all auxiliary data that the app calculated.
    if (ride.predictionComponent?.recommendation == null) {
      return alternativeView;
    }
    final recommendation = ride.predictionComponent!.recommendation!;
    // If the phase change time is null, we hide the countdown.
    if (recommendation.calcCurrentPhaseChangeTime == null) return alternativeView;
    // Calculate the countdown.
    final countdown = recommendation.calcCurrentPhaseChangeTime!.difference(DateTime.now()).inSeconds;
    // If the countdown is 0 (or negative), we hide the countdown. In this way the user
    // is not confused if the countdown is at 0 for a few seconds.
    var countdownLabel = countdown > 5 ? "$countdown" : "";
    // Show no countdown label for amber and redamber.
    if (recommendation.calcCurrentSignalPhase == Phase.amber) countdownLabel = "";
    if (recommendation.calcCurrentSignalPhase == Phase.redAmber) countdownLabel = "";

    final currentPhase = recommendation.calcCurrentSignalPhase;

    final trafficLight = Container(
      width: widget.size.width * 0.35,
      height: widget.size.width * 0.35,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          stops: const [0.2, 0.8, 1],
          colors: [
            currentPhase.color,
            currentPhase.color.withOpacity(0.2),
            currentPhase.color.withOpacity(0),
          ],
        ),
        borderRadius: BorderRadius.circular(64),
      ),
      child: Center(
        child: Text(
          countdownLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 64,
            shadows: [
              Shadow(
                blurRadius: 32,
                offset: Offset(0, 0),
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
    );

    var showCountdown = (ride.calcDistanceToNextSG ?? double.infinity) < 500;
    showCountdown =
        showCountdown && (ride.predictionComponent?.prediction?.predictionQuality ?? 0) > Ride.qualityThreshold;

    return AnimatedCrossFade(
      firstCurve: Curves.easeInOutCubic,
      secondCurve: Curves.easeInOutCubic,
      sizeCurve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 500),
      firstChild: trafficLight,
      secondChild: alternativeView,
      crossFadeState: showCountdown ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}
