

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
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
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

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), 
      child: Tile(
        fill: problem != null
          ? const Color.fromARGB(255, 235, 59, 90)
          : Theme.of(context).colorScheme.background,
        shadowIntensity: problem != null ? 0.2 : 0.05,
        shadow: problem != null ? const Color.fromARGB(255, 235, 59, 90) : Colors.black,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SGStatusMapView())),
        content: Row(children: [
          Flexible(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              problem != null 
                ? BoldContent(text: "Vorübergehende Störung", context: context, color: Colors.white)
                : BoldContent(text: "Aktuelle Datenlage", context: context),
              if (problem != null) const SizedBox(height: 4),
              if (problem != null) Small(text: problem, context: context, color: Colors.white),
            ]),
            fit: FlexFit.tight,
          ),
          const SmallHSpace(),
          Icon(
            Icons.chevron_right, 
            color: problem != null ? Colors.white : Theme.of(context).colorScheme.onBackground,
          ),
        ]),
      )
    );
  }
}