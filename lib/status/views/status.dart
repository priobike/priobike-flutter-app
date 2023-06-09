import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
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

    String? problem = predictionStatusSummary.getProblem();

    if (problem != null) {
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
    //if (status.numBadPredictions > 0) {
    info +=
        " Bei ${(100 * status.numBadPredictions / status.numPredictions).round()}% der Geschwindigkeitsempfehlungen kann die Prognose schlechter sein als gewohnt.";
    //}
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tile(
        fill: isProblem ? CI.red : Theme.of(context).colorScheme.background,
        shadowIntensity: isProblem ? 0.2 : 0.05,
        shadow: isProblem ? CI.red : Colors.black,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SGStatusMapView())),
        content: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FittedBox(
            // Scale the text to fit the width.
            fit: BoxFit.contain,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      isProblem
                          ? BoldContent(text: "Vorübergehende Störung", context: context, color: Colors.white)
                          : BoldContent(text: "Datenverfügbarkeit", context: context),
                      const SizedBox(height: 4),
                      isProblem
                          ? Small(
                              text: text ?? "Lade Daten...",
                              context: context,
                              color: Colors.white,
                            )
                          : Small(
                              text: text ?? "Lade Daten...",
                              context: context,
                            ),
                    ],
                  ),
                ),
                // Show a progress indicator with the pct value.
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Padding(
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
                            backgroundColor:
                                isProblem ? const Color.fromARGB(255, 120, 0, 50) : CI.green.withOpacity(0.2),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
