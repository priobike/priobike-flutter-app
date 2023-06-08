import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/status/views/map.dart';

class StatusView extends StatefulWidget {
  const StatusView({Key? key}) : super(key: key);

  @override
  StatusViewState createState() => StatusViewState();
}

class StatusViewState extends State<StatusView> {
  /// The associated prediction status service, which is injected by the provider.
  late PredictionStatusSummary predictionStatusSummary;

  /// The generated text for the status view.
  String? text;

  /// If the text should be highlighted as a problem.
  bool isProblem = false;

  /// The percentage of good predictions, if any.
  double? goodPct;

  /// The animated scale of the status view.
  double animatedScale = 1.0;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    text = loadText();
    goodPct = loadGood();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    predictionStatusSummary = getIt<PredictionStatusSummary>();
    predictionStatusSummary.addListener(update);

    text = loadText();
    goodPct = loadGood();
  }

  @override
  void dispose() {
    predictionStatusSummary.removeListener(update);
    super.dispose();
  }

  /// Load the displayed text.
  String? loadText() {
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
    if (problem != null) {
      triggerAnimations();
      isProblem = true;
      return problem;
    }

    var info = "";

    var ratio = 0.0;
    if (status.numThings != 0) {
      ratio = (status.numPredictions - status.numBadPredictions) / status.numThings;
    }

    if (ratio > 0.95) {
      info += "Sieht sehr gut aus!";
    } else if (ratio > 0.9) {
      info += "Sieht gut aus.";
    } else if (ratio > 0.85) {
      info += "Sieht weitestgehend gut aus.";
    } else if (ratio > 0.8) {
      info += "Mit kleinen Ausnahmen sieht es gut aus.";
    } else if (ratio > 0.75) {
      info += "Es kommt zurzeit zu kleineren Einschränkungen.";
    } else {
      info += "Es kommt zurzeit zu größeren Einschränkungen.";
    }

    info += " ${status.numPredictions} von ${status.numThings} Ampeln sind derzeit verbunden.";
    if (status.numBadPredictions > 0) {
      info +=
          " Bei ${(100 * status.numBadPredictions / status.numPredictions).round()}% der Geschwindigkeitsempfehlungen kann die Prognose schlechter sein als gewohnt.";
    }
    info += " Klicke hier für eine Störungskarte.";

    // If there is no problem, generate a text with interesting information.
    isProblem = false;
    return info;
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
    if (status.numThings == 0) return 0.0;
    return (status.numPredictions - status.numBadPredictions) / status.numThings;
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
          fill: isProblem ? CI.red : Theme.of(context).colorScheme.background,
          shadowIntensity: isProblem ? 0.2 : 0.05,
          shadow: isProblem ? CI.red : Colors.black,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SGStatusMapView())),
          content: Row(
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isProblem
                        ? BoldContent(text: "Vorübergehende Störung", context: context, color: Colors.white)
                        : BoldContent(text: "Datenverfügbarkeit", context: context),
                    const SizedBox(height: 4),
                    isProblem
                        ? Small(text: text ?? "Lade Daten...", context: context, color: Colors.white)
                        : Small(text: text ?? "Lade Daten...", context: context),
                  ],
                ),
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
                        backgroundColor: isProblem ? const Color.fromARGB(255, 120, 0, 50) : CI.green.withOpacity(0.2),
                        valueColor: isProblem
                            ? const AlwaysStoppedAnimation<Color>(Colors.white)
                            : const AlwaysStoppedAnimation<Color>(CI.green),
                      ),
                    ),
                    Opacity(
                      opacity: 0.2,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: isProblem ? Colors.white : CI.green,
                        size: 42,
                      ),
                    ),
                    BoldSmall(
                      text: "${((goodPct ?? 0) * 100).round()}%",
                      context: context,
                      color: isProblem ? Colors.white : Theme.of(context).colorScheme.onBackground,
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
