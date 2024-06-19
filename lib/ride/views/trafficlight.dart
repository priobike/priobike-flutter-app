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

  /// Whether the countdown should be displayed.
  bool showCountdown = false;

  /// The current phase of the traffic light.
  Phase? currentPhase;

  /// The time of the phase change.
  DateTime? phaseChangeTime;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    var updateView = false;

    // Check if the countdown needs to be updated with new values.
    final recommendation = ride.predictionProvider!.recommendation!;
    final newPhase = recommendation.calcCurrentSignalPhase;
    if (newPhase != currentPhase) {
      currentPhase = newPhase;
      updateView = true;
    }
    final newPhaseChangeTime = recommendation.calcCurrentPhaseChangeTime;
    if (newPhaseChangeTime != phaseChangeTime) {
      phaseChangeTime = newPhaseChangeTime;
      updateView = true;
    }

    // Check if the countdown should be displayed/hidden.
    // Only display the countdown if the distance to the next crossing is less than 500 meters and the prediction quality is good.
    // Also display the countdown if the user has selected a crossing.
    var showCountdownNew = (ride.calcDistanceToNextSG ?? double.infinity) < 500;
    showCountdownNew =
        showCountdownNew && (ride.predictionProvider?.prediction?.predictionQuality ?? 0) > Ride.qualityThreshold;
    showCountdownNew = ride.userSelectedSG != null ? true : showCountdownNew;
    if (showCountdownNew != showCountdown) {
      showCountdown = showCountdownNew;
      updateView = true;
    }

    if (updateView) setState(() {});
  }

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
    return AnimatedCrossFade(
      firstCurve: Curves.easeInOutCubic,
      secondCurve: Curves.easeInOutCubic,
      sizeCurve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 500),
      firstChild: CountdownView(
        size: widget.size,
        currentPhase: currentPhase!,
        phaseChangeTime: phaseChangeTime!,
      ),
      secondChild: TrafficLightAlternativeInfoView(
        size: widget.size,
      ),
      crossFadeState: showCountdown ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}

class TrafficLightAlternativeInfoView extends StatefulWidget {
  /// The size of the speedometer.
  final Size size;

  const TrafficLightAlternativeInfoView({super.key, required this.size});

  @override
  State<StatefulWidget> createState() => TrafficLightAlternativeInfoViewState();
}

class TrafficLightAlternativeInfoViewState extends State<TrafficLightAlternativeInfoView> {
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

    return alternativeView("");
  }
}

class CountdownView extends StatefulWidget {
  /// The size of the speedometer.
  final Size size;

  /// The current phase of the traffic light.
  final Phase currentPhase;

  /// The time of the phase change.
  final DateTime phaseChangeTime;

  const CountdownView({super.key, required this.size, required this.currentPhase, required this.phaseChangeTime});

  @override
  State<StatefulWidget> createState() => CountdownViewState();
}

class CountdownViewState extends State<CountdownView> {
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the countdown.
    final countdown = widget.phaseChangeTime.difference(DateTime.now()).inSeconds;
    // If the countdown is 0 (or negative), we hide the countdown. In this way the user
    // is not confused if the countdown is at 0 for a few seconds.
    var countdownLabel = countdown > 5 ? "$countdown" : "";
    // Show no countdown label for amber and redamber.
    if (widget.currentPhase == Phase.amber) countdownLabel = "";
    if (widget.currentPhase == Phase.redAmber) countdownLabel = "";

    return Container(
      width: widget.size.width * 0.6,
      height: widget.size.width * 0.6,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          stops: const [0.2, 0.8, 1],
          colors: [
            widget.currentPhase.color,
            widget.currentPhase.color.withOpacity(0.2),
            widget.currentPhase.color.withOpacity(0),
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
  }
}
