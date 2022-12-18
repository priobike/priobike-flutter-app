import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/status/views/map.dart';
import 'package:provider/provider.dart';

class StatusView extends StatefulWidget {
  const StatusView({Key? key}) : super(key: key);

  @override
  StatusViewState createState() => StatusViewState();
}

class StatusViewState extends State<StatusView> {
  /// The associated prediction status service, which is injected by the provider.
  late PredictionStatusSummary predictionStatusSummary;

  /// The problem, if any.
  String? problem;

  /// The percentage of good predictions, if any.
  double? goodPct;

  /// The animated scale of the status view.
  double animatedScale = 1.0;

  @override
  void didChangeDependencies() {
    predictionStatusSummary = Provider.of<PredictionStatusSummary>(context);
    problem = loadProblem();
    goodPct = loadGood();
    super.didChangeDependencies();
  }

  /// Loads the problem, if any.
  String? loadProblem() {
    if (predictionStatusSummary.current == null) return null;
    final status = predictionStatusSummary.current!;

    String? problem;
    if (status.mostRecentPredictionTime != null &&
        status.mostRecentPredictionTime! <
            status.statusUpdateTime && // Sometimes we may have a prediction "from the future".
        (status.mostRecentPredictionTime! - status.statusUpdateTime).abs() > const Duration(minutes: 5).inSeconds) {
      // Render the most recent prediction time as hh:mm.
      final time = DateTime.fromMillisecondsSinceEpoch(status.mostRecentPredictionTime! * 1000);
      final formattedTime = "${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}";
      problem =
          "Seit $formattedTime Uhr senden Ampeln keine oder nur noch wenige Daten. Klicke hier für eine Störungskarte.";
    } else if (status.numThings != 0 && status.numPredictions / status.numThings < 0.5) {
      problem =
          "${((status.numPredictions / status.numThings) * 100).round()}% der Ampeln senden gerade Daten. Klicke hier für eine Störungskarte.";
    } else if (status.numPredictions != 0 && status.numBadPredictions / status.numPredictions > 0.5) {
      problem =
          "${((status.numBadPredictions / status.numPredictions) * 100).round()}% der Ampeln senden gerade lückenhafte Daten. Klicke hier für eine Störungskarte.";
    } else if (status.averagePredictionQuality != null && status.averagePredictionQuality! < 0.5) {
      problem =
          "Im Moment kann die Qualität der Geschwindigkeitsempfehlungen für Ampeln niedriger als gewohnt sein. Klicke hier für eine Störungskarte.";
    }

    // Only put emphasis by animating the scale if the problem is not null.
    if (problem != null) triggerAnimations();
    return problem;
  }

  /// Loads the percentage of good predictions.
  double loadGood() {
    if (predictionStatusSummary.current == null) return 0.0;
    final status = predictionStatusSummary.current!;
    if (status.mostRecentPredictionTime == null) return 0.0;
    if (status.mostRecentPredictionTime! - status.statusUpdateTime > const Duration(minutes: 5).inSeconds) {
      // Sometimes we may have a prediction "from the future".
      if (status.mostRecentPredictionTime! < status.statusUpdateTime) return 0.0;
    }
    if (status.numPredictions == 0) return 0.0;
    return (status.numPredictions - status.numBadPredictions) / status.numPredictions;
  }

  /// Trigger the animation of the status view.
  Future<void> triggerAnimations() async {
    setState(() => animatedScale = 1.0);
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => animatedScale = 1.05);
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => animatedScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: animatedScale,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.bounceOut,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Tile(
          fill: problem != null ? CI.red : Theme.of(context).colorScheme.background,
          shadowIntensity: problem != null ? 0.2 : 0.05,
          shadow: problem != null ? CI.red : Colors.black,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SGStatusMapView())),
          content: Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    problem != null
                        ? BoldContent(text: "Vorübergehende Störung", context: context, color: Colors.white)
                        : BoldContent(text: "Datenverfügbarkeit", context: context),
                    const SizedBox(height: 4),
                    problem != null
                        ? Small(text: problem!, context: context, color: Colors.white)
                        : Small(text: "Alles super.", context: context),
                  ],
                ),
                fit: FlexFit.tight,
              ),
              const SmallHSpace(),
              // Show a progress indicator with the pct value.
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        value: predictionStatusSummary.isLoading ? null : goodPct,
                        strokeWidth: 6,
                        backgroundColor: problem != null
                            ? const Color.fromARGB(255, 161, 35, 28)
                            : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        valueColor: problem != null
                            ? const AlwaysStoppedAnimation<Color>(Colors.white)
                            : AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    Opacity(
                      opacity: 0.2,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: problem != null ? Colors.white : Theme.of(context).colorScheme.primary,
                        size: 42,
                      ),
                    ),
                    BoldSmall(
                      text: "${((goodPct ?? 0) * 100).round()}%",
                      context: context,
                      color: problem != null ? Colors.white : Theme.of(context).colorScheme.onBackground,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
