

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/status/services/status.dart';
import 'package:provider/provider.dart';

class StatusView extends StatefulWidget {
  const StatusView({Key? key}) : super(key: key);

  @override 
  StatusViewState createState() => StatusViewState();
}

class StatusViewState extends State<StatusView> {
  /// The associated prediction status service, which is injected by the provider.
  late PredictionStatus predictionStatus;

  @override
  void didChangeDependencies() {
    predictionStatus = Provider.of<PredictionStatus>(context);

    // Load once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await predictionStatus.fetchStatus(context);
    });

    super.didChangeDependencies();
  }

  Widget renderStatus() {
    if (predictionStatus.status == null) return Container();
    final status = predictionStatus.status!;

    String? problem;
    if (
      status.mostRecentPredictionTime != null && 
      (status.mostRecentPredictionTime! - status.statusUpdateTime).abs() > const Duration(minutes: 5).inSeconds
    ) {
      // Render the most recent prediction time as hh:mm.
      final time = DateTime.fromMillisecondsSinceEpoch(status.mostRecentPredictionTime! * 1000);
      final formattedTime = "${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}";
      problem = "Seit $formattedTime Uhr stehen keine Ampeldaten zur Verfügung.";
    } else if(
      status.numThings != 0 &&
      status.numPredictions / status.numThings < 0.5
    ) {
      problem = "Im Moment gibt es nur für ${((status.numPredictions / status.numThings) * 100).round()}% der Ampeln Prognosen.";
    } else if(
      status.numPredictions != 0 && 
      status.numBadPredictions / status.numPredictions > 0.5
    ) {
      problem = "Im Moment kann die Qualität der Prognosen für ${((status.numBadPredictions / status.numPredictions) * 100).round()}% der Ampeln niedriger als gewohnt sein.";
    } else if(
      status.averagePredictionQuality != null &&
      status.averagePredictionQuality! < 0.5
    ) {
      problem = "Im Moment kann die Qualität der Vorhersagen für Ampeln niedriger als gewohnt sein.";
    }

    if (problem == null) return Container();

    bool isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0), 
      child: Tile(
        fill: isDark 
        ? const Color.fromARGB(255, 134, 79, 79) 
        : const Color.fromARGB(255, 255, 228, 228),
        content: Row(children: [
          Flexible(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldContent(text: "Vorübergehende Störung", context: context),
              const SizedBox(height: 4),
              Small(text: problem, context: context),
            ]),
          ),
          const SmallHSpace(),
          Icon(
            Icons.report_problem, 
            color: isDark ? Colors.white : Colors.black,
          ),
        ]),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      firstChild: Container(),
      secondChild: renderStatus(),
      crossFadeState: predictionStatus.status == null 
        ? CrossFadeState.showFirst 
        : CrossFadeState.showSecond,
    );
  }
}