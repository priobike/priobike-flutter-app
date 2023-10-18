import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/status/services/status_history.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/status/views/status_history_chart.dart';
import 'package:priobike/status/views/status_tabs.dart';

class StatusHistoryView extends StatefulWidget {
  /// Which time period to display.
  final StatusHistoryTime time;

  const StatusHistoryView({Key? key, required this.time}) : super(key: key);

  @override
  State<StatusHistoryView> createState() => StatusHistoryViewState();
}

class StatusHistoryViewState extends State<StatusHistoryView> {
  /// The associated status history service, which is injected by the provider.
  late StatusHistory statusHistory;

  /// The associated prediction summary service, which is injected by the provider.
  late PredictionStatusSummary predictionStatusSummary;

  @override
  void initState() {
    super.initState();

    statusHistory = getIt<StatusHistory>();
    predictionStatusSummary = getIt<PredictionStatusSummary>();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        statusHistory.addListener(update);
        predictionStatusSummary.addListener(update);
      },
    );
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void dispose() {
    statusHistory.removeListener(update);
    predictionStatusSummary.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProblem = predictionStatusSummary.getProblem() == null ? false : true;
    return Container(
      height: 130,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tile(
        fill: isProblem ? CI.radkulturYellow : Theme.of(context).colorScheme.surfaceVariant,
        shadowIntensity: isProblem ? 0.2 : 0.05,
        shadow: isProblem ? CI.radkulturYellow : Colors.black,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BoldContent(
                text: "Datenverfügbarkeit - ${widget.time.name()}",
                context: context,
                color: isProblem || !isDark ? Colors.black : Colors.white),
            const SizedBox(height: 4),
            if (statusHistory.isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            if (!statusHistory.isLoading)
              Expanded(
                child: StatusHistoryChart(time: widget.time, isProblem: isProblem),
              ),
          ],
        ),
      ),
    );
  }
}
