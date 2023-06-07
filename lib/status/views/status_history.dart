import 'package:flutter/material.dart';
import 'package:priobike/main.dart';
import 'package:priobike/status/services/status_history.dart';

class StatusHistoryView extends StatefulWidget {
  const StatusHistoryView({Key? key}) : super(key: key);

  @override
  State<StatusHistoryView> createState() => StatusHistoryViewState();
}

class StatusHistoryViewState extends State<StatusHistoryView> {
  /// The associated status history service, which is injected by the provider.
  late StatusHistory statusHistory;

  /// The maximum value of the status history.
  double maximumValue = 0.0;

  @override
  void initState() {
    super.initState();
    statusHistory = getIt<StatusHistory>();
    statusHistory.addListener(update);
    statusHistory.fetch();
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

  /// Calculates the maximum value of the status history.
  void calculateMaximum() {
    // TODO: Calculate the maximum value of the status history to set the diagram scale.
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 100,
        color: Colors.red,
        child: const Center(
          child: Text("Status History"),
        ),
      ),
    ));
  }
}
