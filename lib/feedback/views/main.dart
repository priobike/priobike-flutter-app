import 'dart:io';

import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/feedback/views/stars.dart';
import 'package:priobike/feedback/views/text.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:provider/provider.dart';

class FeedbackView extends StatefulWidget {
  /// A callback that will be called when the user has submitted feedback.
  final Future<void> Function(BuildContext context) onSubmitted;

  /// A boolean indicating if the view is used isolated or after a ride.
  /// This determines whether a back button should be shown and also whether the option to save a route should be shown.
  final bool isolatedViewUsage;

  const FeedbackView({required this.onSubmitted, this.isolatedViewUsage = false, Key? key}) : super(key: key);

  @override
  FeedbackViewState createState() => FeedbackViewState();
}

class FeedbackViewState extends State<FeedbackView> {
  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  /// The associated feedback service, which is injected by the provider.
  late Feedback feedback;

  /// The associated statistics service, which is injected by the provider.
  late Statistics statistics;

  /// Submit feedback.
  Future<void> submit(BuildContext context) async {
    var didSendSomething = false;

    // Send the feedback and reset the feedback service.
    if (feedback.willSendFeedback) {
      didSendSomething = didSendSomething || await feedback.send(context);
    }
    await feedback.reset();

    // Send the tracking data and reset the tracking service.
    if (tracking.willSendTrack && tracking.canSendTrack) {
      didSendSomething = didSendSomething || await tracking.send(context);
    }
    await tracking.reset();

    if (didSendSomething) {
      ToastMessage.showSuccess("Danke für's Testen!");
    }

    showNavigationBarAndroid();

    // Call the callback.
    await widget.onSubmitted(context);
  }

  /// Reenable the buttom navigation bar on Android after hiding it in Speedometer View
  void showNavigationBarAndroid() {
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
      );
    }
  }

  @override
  void didChangeDependencies() {
    tracking = Provider.of<Tracking>(context);
    feedback = Provider.of<Feedback>(context);
    statistics = Provider.of<Statistics>(context);
    super.didChangeDependencies();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.all(paddingText),
            child: BoldContent(
              text: "Zusammenfassung deiner Fahrt",
              context: context,
            ),
          ),
        ),
        const SmallVSpace(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Table(
            columnWidths: const {
              // make the left column wider than the right column
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: paddingText),
                    child: Content(
                      textAlign: TextAlign.left,
                      text: "Fahrzeit:",
                      context: context,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: paddingText),
                    child: Content(
                      textAlign: TextAlign.right,
                      text: (statistics.currentSummary?.durationSeconds ?? 0.0) >= 60
                          ? "${((statistics.currentSummary?.durationSeconds ?? 0) / 60).toStringAsFixed(2)} Minuten"
                          : "${(statistics.currentSummary?.durationSeconds ?? 0).toStringAsFixed(0)} Sekunden",
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
                      text: "Gefahrene Strecke:",
                      context: context,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: paddingText),
                    child: Content(
                      textAlign: TextAlign.right,
                      text: (statistics.currentSummary?.distanceMeters ?? 0.0) >= 1000
                          ? "${((statistics.currentSummary?.distanceMeters ?? 0.0) / 1000).toStringAsFixed(2)} Kilometer"
                          : "${(statistics.currentSummary?.distanceMeters ?? 0.0).toStringAsFixed(0)} Meter",
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
                      text: "Durchschnittsgeschwindigkeit:",
                      context: context,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: paddingText),
                    child: Content(
                      textAlign: TextAlign.right,
                      text: "${(statistics.currentSummary?.averageSpeedKmH ?? 0.00).toStringAsFixed(2)} km/h",
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
                      text: "CO2 gespart:",
                      context: context,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: paddingText),
                    child: Content(
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
        ),
        const SmallVSpace(),
      ],
    );
  }

  Widget renderSaveRoute() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const VSpace(),
        const Divider(),
        const VSpace(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Small(text: "Hat dir die Route gefallen?", context: context),
        ),
        const SmallVSpace(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: BigButton(label: "Strecke speichern", onPressed: () => showSaveShortcutSheet(context)),
        ),
        const VSpace(),
        const Divider(),
        const VSpace(),
      ],
    );
  }

  Widget renderFeedback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: StarRatingView(text: "Feedback zur App"),
        ),
        VSpace(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: TextFeedbackView(text: "Was können wir verbessern?"),
        ),
        VSpace(),
        Divider(),
        VSpace(),
      ],
    );
  }

  Widget renderSendButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BigButton(
          iconColor: Colors.white,
          icon: Icons.check,
          label: "Fertig",
          onPressed: () => submit(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (feedback.isSendingFeedback || tracking.isSendingTrack) {
      return renderLoadingIndicator();
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      if (widget.isolatedViewUsage)
                        Row(
                          children: [
                            AppBackButton(onPressed: () => Navigator.pop(context)),
                            const HSpace(),
                            SubHeader(text: "Feedback", context: context),
                            const VSpace(),
                            const Divider(),
                          ],
                        ),
                      const SizedBox(height: 24),
                      renderFeedback(),
                      if (!widget.isolatedViewUsage) ...[
                        renderSummary(),
                        renderSaveRoute(),
                      ],
                      renderSendButton(),
                      const SizedBox(height: 128),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
