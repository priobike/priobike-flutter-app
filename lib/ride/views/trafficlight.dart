import 'package:flutter/material.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/ride/views/cancel_button.dart';
import 'package:provider/provider.dart';

class RideTrafficLightView extends StatefulWidget {
  const RideTrafficLightView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideTrafficLightViewState();
}

class RideTrafficLightViewState extends State<RideTrafficLightView> {
  /// The associated ride service, which is injected by the provider.
  late Ride ride;

  @override
  void didChangeDependencies() {
    ride = Provider.of<Ride>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final alternativeView = Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const CancelButton(
        borderRadius: 128,
        text: "Fertig",
      ),
    );

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
    var countdownLabel = countdown > 0 ? "$countdown" : "";
    // Show no countdown label for amber and redamber.
    if (recommendation.calcCurrentSignalPhase == Phase.amber) countdownLabel = "";
    if (recommendation.calcCurrentSignalPhase == Phase.redAmber) countdownLabel = "";

    final currentPhase = recommendation.calcCurrentSignalPhase;

    final trafficLight = Container(
      width: 148,
      height: 148,
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
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -24),
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
            Transform.translate(
              offset: const Offset(0, 24),
              child: const CancelButton(),
            ),
          ],
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
