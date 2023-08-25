import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/feedback/views/pictogram.dart';
import 'package:priobike/feedback/views/stars.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/tracking/services/tracking.dart';

class FeedbackView extends StatefulWidget {
  /// A callback that will be called when the user has submitted feedback.
  final Future<void> Function(BuildContext context) onSubmitted;

  const FeedbackView({required this.onSubmitted, Key? key}) : super(key: key);

  @override
  FeedbackViewState createState() => FeedbackViewState();
}

class FeedbackViewState extends State<FeedbackView> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  /// The associated feedback service, which is injected by the provider.
  late Feedback feedback;

  /// The associated statistics service, which is injected by the provider.
  late Statistics statistics;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  /// Submit feedback.
  Future<void> submit() async {
    // Send the feedback and reset the feedback service.
    var didSendSomething = false;
    if (feedback.willSendFeedback) {
      didSendSomething = await feedback.send();
    }
    await feedback.reset();

    if (didSendSomething) {
      ToastMessage.showSuccess("Danke für's Testen!");
    }

    showNavigationBarAndroid();

    if (mounted) {
      // Call the callback.
      await widget.onSubmitted(context);
    }
  }

  /// Reenable the bottom navigation bar on Android after hiding it in Speedometer View
  void showNavigationBarAndroid() {
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
      );
    }
  }

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);
    tracking = getIt<Tracking>();
    tracking.addListener(update);
    feedback = getIt<Feedback>();
    feedback.addListener(update);
    statistics = getIt<Statistics>();
    statistics.addListener(update);
  }

  @override
  void dispose() {
    routing.removeListener(update);
    tracking.removeListener(update);
    feedback.removeListener(update);
    statistics.removeListener(update);
    super.dispose();
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              "Sende Feedback...",
              style: TextStyle(fontSize: 16),
            ),
            TextButton(
              onPressed: () async => await widget.onSubmitted(context),
              child: const Text(
                "Abbrechen",
                style: TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget renderSummary() {
    const paddingText = 4.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.background.withOpacity(0.75),
            spreadRadius: 0,
            blurRadius: 24,
          ),
        ],
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.025),
                  width: 2,
                ),
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: paddingText),
                child: Content(
                  textAlign: TextAlign.left,
                  text: "Fahrtzeit",
                  context: context,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: paddingText),
                child: BoldContent(
                  textAlign: TextAlign.right,
                  text: (statistics.currentSummary?.durationSeconds ?? 0.0) >= 60
                      ? "${((statistics.currentSummary?.durationSeconds ?? 0) / 60).toStringAsFixed(2)} min"
                      : "${(statistics.currentSummary?.durationSeconds ?? 0).toStringAsFixed(0)} s",
                  context: context,
                ),
              ),
            ],
          ),
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.025),
                  width: 2,
                ),
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: paddingText),
                child: Content(
                  textAlign: TextAlign.left,
                  text: "Distanz",
                  context: context,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: paddingText),
                child: BoldContent(
                  textAlign: TextAlign.right,
                  text: (statistics.currentSummary?.distanceMeters ?? 0.0) >= 1000
                      ? "${((statistics.currentSummary?.distanceMeters ?? 0.0) / 1000).toStringAsFixed(2)} km"
                      : "${(statistics.currentSummary?.distanceMeters ?? 0.0).toStringAsFixed(0)} m",
                  context: context,
                ),
              ),
            ],
          ),
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.025),
                  width: 2,
                ),
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: paddingText),
                child: Content(
                  textAlign: TextAlign.left,
                  text: "Geschwindigkeit",
                  context: context,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: paddingText),
                child: BoldContent(
                  textAlign: TextAlign.right,
                  text: "Ø ${(statistics.currentSummary?.averageSpeedKmH ?? 0.00).toStringAsFixed(2)} km/h",
                  context: context,
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: paddingText),
                child: Content(
                  textAlign: TextAlign.left,
                  text: "CO2 gespart",
                  context: context,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: paddingText),
                child: BoldContent(
                  textAlign: TextAlign.right,
                  text: (statistics.currentSummary?.savedCo2inG ?? 0.0) >= 1000
                      ? "${((statistics.currentSummary?.savedCo2inG ?? 0.0) / 1000).toStringAsFixed(2)} kg"
                      : "${(statistics.currentSummary?.savedCo2inG ?? 0.0).toStringAsFixed(2)} g",
                  context: context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (feedback.isSendingFeedback) {
      return renderLoadingIndicator();
    }

    if (tracking.previousTracks == null) return Container();

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          key: UniqueKey(),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 48, 12, 12),
                child: BoldContent(
                  text: () {
                    final start = routing.selectedWaypoints?.first;
                    final end = routing.selectedWaypoints?.last;
                    if (start == null || end == null) {
                      return "Fahrt";
                    }
                    var startStr = start.address?.substring(0, min(12, start.address?.length ?? 0));
                    startStr = startStr ?? "Start";
                    var endStr = end.address?.substring(0, min(12, end.address?.length ?? 0));
                    endStr = endStr ?? "Ziel";
                    return "$startStr... nach $endStr...";
                  }(),
                  context: context,
                  textAlign: TextAlign.center,
                ),
              ),
              const VSpace(),
              BlendIn(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: renderSummary(),
                ),
              ),
              const VSpace(),
              BlendIn(
                child: Container(
                  height: MediaQuery.of(context).size.width - 32,
                  width: MediaQuery.of(context).size.width - 32,
                  padding: const EdgeInsets.all(24),
                  child: TrackPictogram(
                    key: UniqueKey(),
                    track: getIt<Positioning>().positions,
                    sessionId: tracking.previousTracks!.last.sessionId, // TODO: May break if no previous track exists?
                    minSpeedColor: CI.blue,
                    maxSpeedColor: CI.blueLight,
                    blurRadius: 10,
                  ),
                ),
              ),
              const VSpace(),
              Container(
                color: Theme.of(context).colorScheme.primary,
                child: Container(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Column(
                    children: [
                      const SmallVSpace(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: StarRatingView(text: "Dein Feedback zur App"),
                      ),
                      BigButton(
                        iconColor: Colors.white,
                        icon: Icons.check,
                        fillColor: Theme.of(context).colorScheme.background.withOpacity(0.25),
                        label: "Fertig",
                        onPressed: () => submit(),
                        boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 24),
                      ),
                      BigButton(
                        iconColor: Colors.white,
                        icon: Icons.save_rounded,
                        fillColor: Theme.of(context).colorScheme.background.withOpacity(0.25),
                        label: "Strecke speichern",
                        onPressed: () => showSaveShortcutSheet(context),
                        boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 24),
                      ),
                      const VSpace(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
