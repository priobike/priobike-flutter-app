

import 'package:flutter/material.dart';
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

  @override
  void didChangeDependencies() {
    predictionStatusSummary = Provider.of<PredictionStatusSummary>(context);

    // Load once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await predictionStatusSummary.fetch(context);
    });

    super.didChangeDependencies();
  }

  Widget renderStatus() {
    if (predictionStatusSummary.current == null) return Container();
    final status = predictionStatusSummary.current!;

    String? problem;
    if (
      status.mostRecentPredictionTime != null && 
      (status.mostRecentPredictionTime! - status.statusUpdateTime).abs() > const Duration(minutes: 5).inSeconds
    ) {
      // Render the most recent prediction time as hh:mm.
      final time = DateTime.fromMillisecondsSinceEpoch(status.mostRecentPredictionTime! * 1000);
      final formattedTime = "${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}";
      problem = "Seit $formattedTime Uhr senden Ampeln keine oder nur noch wenige Daten. Klicke hier für eine Störungskarte.";
    } else if(
      status.numThings != 0 &&
      status.numPredictions / status.numThings < 0.5
    ) {
      problem = "${((status.numPredictions / status.numThings) * 100).round()}% der Ampeln senden gerade Daten. Klicke hier für eine Störungskarte.";
    } else if(
      status.numPredictions != 0 && 
      status.numBadPredictions / status.numPredictions > 0.5
    ) {
      problem = "${((status.numBadPredictions / status.numPredictions) * 100).round()}% der Ampeln senden gerade lückenhafte Daten. Klicke hier für eine Störungskarte.";
    } else if(
      status.averagePredictionQuality != null &&
      status.averagePredictionQuality! < 0.5
    ) {
      problem = "Im Moment kann die Qualität der Geschwindigkeitsempfehlungen für Ampeln niedriger als gewohnt sein. Klicke hier für eine Störungskarte.";
    }

    bool isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12), 
      child: Tile(
        fill: problem != null
          ? isDark 
            ? const Color.fromARGB(255, 134, 79, 79) 
            : const Color.fromARGB(255, 255, 228, 228)
          : Theme.of(context).colorScheme.background,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SGStatusMapView())),
        content: Row(children: [
          Flexible(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              problem != null 
                ? BoldContent(text: "Vorübergehende Störung", context: context)
                : BoldContent(text: "Aktuelle Datenlage", context: context),
              if (problem != null) const SizedBox(height: 4),
              if (problem != null) Small(text: problem, context: context),
            ]),
            fit: FlexFit.tight,
          ),
          const SmallHSpace(),
          Icon(
            Icons.chevron_right, 
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
      crossFadeState: predictionStatusSummary.current == null 
        ? CrossFadeState.showFirst 
        : CrossFadeState.showSecond,
    );
  }
}