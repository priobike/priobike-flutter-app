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

    final problem = predictionStatusSummary.getProblem();

    if (problem != null) {
      isProblem = true;
      return problem;
    }

    final statusText = predictionStatusSummary.getStatusText();

    // If there is no problem, return a text with interesting information.
    isProblem = false;
    return statusText;
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tile(
        fill: isProblem ? CI.red : Theme.of(context).colorScheme.background,
        shadowIntensity: isProblem ? 0.2 : 0.05,
        shadow: isProblem ? CI.red : Colors.black,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SGStatusMapView())),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BoldSmall(
              text: "Jetzt",
              color: isProblem ? Colors.white : Theme.of(context).colorScheme.onBackground,
              context: context,
            ),
            const SmallVSpace(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isProblem
                          ? BoldContent(text: "Vorübergehende Störung", context: context, color: Colors.white)
                          : BoldContent(text: "Datenverfügbarkeit", context: context),
                      const SizedBox(height: 6),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
