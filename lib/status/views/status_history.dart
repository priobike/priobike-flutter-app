import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/status/services/status_history.dart';
import 'package:priobike/status/views/map.dart';
import 'package:priobike/status/views/status_history_chart.dart';
import 'package:priobike/status/views/status_tabs.dart';

class StatusHistoryView extends StatefulWidget {
  final StatusHistoryTime time;

  const StatusHistoryView({Key? key, required this.time}) : super(key: key);

  @override
  State<StatusHistoryView> createState() => StatusHistoryViewState();
}

class StatusHistoryViewState extends State<StatusHistoryView> {
  /// The associated status history service, which is injected by the provider.
  late StatusHistory statusHistory;

  @override
  void initState() {
    super.initState();

    statusHistory = getIt<StatusHistory>();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        statusHistory.addListener(update);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Tile(
        fill: Theme.of(context).colorScheme.background,
        shadowIntensity: 0.05,
        shadow: Colors.black,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SGStatusMapView())),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BoldContent(text: "Datenverfügbarkeit - ${widget.time.name()}", context: context),
            const SizedBox(height: 4),
            if (statusHistory.isLoading) Small(text: "Lade Daten...", context: context),
            StatusHistoryChart(time: widget.time),
          ],
        ),
      ),
    );
  }
}
