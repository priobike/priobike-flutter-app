import 'dart:async';

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

  /// The timer to update the ui when the countdown changes.
  late Timer _timer;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    ride = getIt<Ride>();
    ride.addListener(update);

    _startTimer();
  }

  /// Function that starts the timer to update the ui when the countdown changes.
  void _startTimer() async {
    // Set the timer to 250ms but only update every 4th tick. (reduce battery consumption)
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final currentPhaseTimeChange = ride.predictionProvider?.recommendation?.calcCurrentPhaseChangeTime;
      if (currentPhaseTimeChange == null) return;
      final countdown = currentPhaseTimeChange.difference(DateTime.now()).inMilliseconds;

      // Only update in the top 250ms of a second, because in this range the new second is max 250 ms old.
      // So updating the ui in this range is the most accurate.
      if (countdown % 1000 < 750) return;

      // Only update if the countdown is currently displayed.
      if (!_showCountdown()) return;
      if (ride.calcDistanceToNextSG != null && ride.calcDistanceToNextSG! > 500) return;
      if (ride.calcCurrentSG == null && ride.userSelectedSG == null) return;
      if (ride.predictionProvider?.recommendation == null) return;
      if ((ride.predictionProvider?.prediction?.predictionQuality ?? 0) < Ride.qualityThreshold) return;
      if (ride.predictionProvider!.recommendation!.calcCurrentPhaseChangeTime == null) return;

      // Countdown currently displayed and therefore needs to be updated.
      setState(() {});
    });
  }

  @override
  void dispose() {
    ride.removeListener(update);
    _timer.cancel();
    super.dispose();
  }

  Widget alternativeView(String message) => Container(
        width: widget.size.width * 0.45,
        height: widget.size.width * 0.45,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: BoldContent(
            textAlign: TextAlign.center,
            text: message,
            color: Colors.white,
            context: context,
          ),
        ),
      );

  // Function that returns the bool if the countdown should be shown.
  bool _showCountdown() {
    // Only display the countdown if the distance to the next crossing is less than 500 meters and the prediction quality is good.
    // Also display the countdown if the user has selected a crossing.
    var showCountdown = (ride.calcDistanceToNextSG ?? double.infinity) < 500;
    showCountdown =
        showCountdown && (ride.predictionProvider?.prediction?.predictionQuality ?? 0) > Ride.qualityThreshold;
    showCountdown = ride.userSelectedSG != null ? true : showCountdown;

    return showCountdown;
  }

  @override
  Widget build(BuildContext context) {
    // Don't show a countdown if...
    // Not supported crossing.
    if (ride.calcCurrentSG == null && ride.userSelectedSG == null) {
      return alternativeView("Nicht\nunterstütze\nKreuzung");
    }

    // Check if we have all auxiliary data that the app calculated.
    if (ride.predictionProvider?.recommendation == null) {
      return alternativeView("Keine\nAmpeldaten\nvorhanden");
    }

    // Prediction quality check.
    if ((ride.predictionProvider?.prediction?.predictionQuality ?? 0) < Ride.qualityThreshold) {
      return alternativeView("Prognose\nzu schlecht");
    }

    final recommendation = ride.predictionProvider!.recommendation!;
    // If the phase change time is null, we hide the countdown.
    if (recommendation.calcCurrentPhaseChangeTime == null) {
      final uniqueColors = recommendation.calcPhasesFromNow.toSet();
      if (uniqueColors.length == 1) {
        final color = uniqueColors.first;
        return alternativeView("Bleibt\n${color.description}");
      }
      return alternativeView("Prognose\nzu alt");
    }

    // The gauge is not displayed if the distance to the next signal is too large.
    // But still display the distance to the next signal.
    if (ride.calcDistanceToNextSG != null && ride.calcDistanceToNextSG! > 500) {
      // Display the distance to the next signal in m or km.
      final distance = ride.calcDistanceToNextSG! < 1000
          ? "${ride.calcDistanceToNextSG!.toStringAsFixed(0)} m"
          : "${(ride.calcDistanceToNextSG! / 1000).toStringAsFixed(1)} km";
      return alternativeView("Ampel in \n$distance");
    }

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
      width: widget.size.width * 0.6,
      height: widget.size.width * 0.6,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
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
        ],
      ),
    );

    return AnimatedCrossFade(
      firstCurve: Curves.easeInOutCubic,
      secondCurve: Curves.easeInOutCubic,
      sizeCurve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 500),
      firstChild: trafficLight,
      secondChild: alternativeView(""),
      crossFadeState: _showCountdown() ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}
