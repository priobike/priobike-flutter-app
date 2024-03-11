import 'package:flutter/material.dart';
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

  Widget alternativeView(String message) => Container(
        width: widget.size.width * 0.7,
        height: widget.size.width * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
          borderRadius: BorderRadius.circular(200),
        ),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Don't show a countdown if...
    // Not supported crossing.
    if (ride.calcCurrentSG == null) return alternativeView("Nicht\nunterstütze\nKreuzung");

    // Check if we have all auxiliary data that the app calculated.
    if (ride.predictionComponent?.recommendation == null) {
      return alternativeView("Keine\nAmpeldaten\nvorhanden");
    }

    // Prediction quality check.
    if ((ride.predictionComponent?.prediction?.predictionQuality ?? 0) < Ride.qualityThreshold) {
      return alternativeView("Prognose\nzu schlecht");
    }

    final recommendation = ride.predictionComponent!.recommendation!;
    // If the phase change time is null, we hide the countdown.
    if (recommendation.calcCurrentPhaseChangeTime == null) return alternativeView("Prognose\nzu alt");
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
      width: widget.size.width * 0.7,
      height: widget.size.width * 0.7,
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
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    countdownLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 86,
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
                  if (countdownLabel.isNotEmpty)
                    const Text(
                      "s",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
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
                ],
              ),
            ),
          ),
        ],
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
      secondChild: alternativeView(""),
      crossFadeState: showCountdown ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}
