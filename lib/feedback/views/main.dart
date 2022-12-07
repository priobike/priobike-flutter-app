import 'package:flutter/material.dart' hide Feedback;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/statistics/models/summary.dart';
import 'dart:convert';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/feedback/views/stars.dart';
import 'package:priobike/feedback/views/text.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/send.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Call the callback.
    await widget.onSubmitted(context);
  }

  @override
  void didChangeDependencies() {
    tracking = Provider.of<Tracking>(context);
    feedback = Provider.of<Feedback>(context);
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

  double? distanceMeters;
  double? durationSeconds;
  double? speedKmh;
  double? co2Gramm;
  List<String>? summaries;
  bool loadedLastRide = false;

  /// Load the statistics from the local storage.
  Future<void> loadLastRide() async {
    if (loadedLastRide) return;

    final storage = await SharedPreferences.getInstance();
    summaries = (storage.getStringList("priobike.statistics.summaries"));

    if (summaries != null) {
      setState(() {
        distanceMeters = Summary.fromJson(jsonDecode(summaries!.last)).distanceMeters;
        durationSeconds = Summary.fromJson(jsonDecode(summaries!.last)).durationSeconds;

        const co2PerKm = 0.1187; // Data according to statista.com in KG
        co2Gramm = (distanceMeters! / 1000) * (durationSeconds! / 3600) * co2PerKm * 1000;
        speedKmh = distanceMeters! / durationSeconds! * 3.6;
        loadedLastRide = true;
      });
    }
  }

  Widget renderSummary() {
    loadLastRide();
    const paddingText = 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(paddingText),
            child: BoldContent(
              text: "Zusammenfassung deiner Fahrt",
              context: context,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Table(
            children: [
              TableRow(
                children: [
                  Container(
                    padding: const EdgeInsets.all(paddingText),
                    child: Content(
                      textAlign: TextAlign.left,
                      text: "Fahrzeit:",
                      context: context,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(paddingText),
                    child: Content(
                      textAlign: TextAlign.right,
                      text: (durationSeconds ?? 0.0) >= 60
                          ? "${(durationSeconds! / 60).toStringAsFixed(2)} Minuten"
                          : "${(durationSeconds!).toStringAsFixed(0)} Sekunden",
                      context: context,
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Container(
                    padding: const EdgeInsets.all(paddingText),
                    child: Content(
                      textAlign: TextAlign.left,
                      text: "Gefahrene Strecke:",
                      context: context,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(paddingText),
                    child: Content(
                      textAlign: TextAlign.right,
                      text: (distanceMeters ?? 0.0) >= 1000
                          ? "${(distanceMeters! / 1000).toStringAsFixed(2)} Kilometer"
                          : "${(distanceMeters!).toStringAsFixed(0)} Meter",
                      context: context,
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Container(
                    padding: const EdgeInsets.all(paddingText),
                    child: Content(
                      textAlign: TextAlign.left,
                      text: "Durchschnittsgeschwindigkeit:",
                      context: context,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(paddingText),
                    child: Content(
                      textAlign: TextAlign.right,
                      text: "${(speedKmh ?? 0.00).toStringAsFixed(2)} km/h",
                      context: context,
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Container(
                    padding: const EdgeInsets.all(paddingText),
                    child: Content(
                      textAlign: TextAlign.left,
                      text: "CO2 gespart:",
                      context: context,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(paddingText),
                    child: Content(
                      textAlign: TextAlign.right,
                      text: (co2Gramm ?? 0.0) >= 1000
                          ? "${(co2Gramm! / 1000).toStringAsFixed(2)} kg"
                          : "${(co2Gramm!).toStringAsFixed(2)} g",
                      context: context,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const VSpace(),
        const Divider(),
        const VSpace(),
      ],
    );
  }

  Widget renderSaveRoute() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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

  Widget renderSendTracking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: SendTrackingView(),
        ),
        const VSpace(),
        const Divider(),
        const VSpace(),
        BigButton(
          iconColor: Colors.white,
          icon:
              feedback.willSendFeedback || (tracking.willSendTrack && tracking.canSendTrack) ? Icons.send : Icons.check,
          label: feedback.willSendFeedback || (tracking.willSendTrack && tracking.canSendTrack) ? "Senden" : "Fertig",
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
                      const VSpace(),
                      renderSummary(),
                      if (!widget.isolatedViewUsage)
                        Column(
                          children: [
                            renderSaveRoute(),
                          ],
                        ),
                      renderFeedback(),
                      renderSendTracking(),
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
