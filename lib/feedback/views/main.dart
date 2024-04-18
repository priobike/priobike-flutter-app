import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/feedback/views/audio_rating_view.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/track_history_item.dart';

class FeedbackView extends StatefulWidget {
  /// A callback that will be called when the user has submitted feedback.
  final Future<void> Function(BuildContext context) onSubmitted;

  const FeedbackView({required this.onSubmitted, super.key});

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

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  /// The image of the route start icon.
  ui.Image? startImage;

  /// The image of the route destination icon.
  ui.Image? destinationImage;

  Widget? trackHistory;

  /// The bool that stores the state of the audio feedback send.
  bool audioFeedbackSend = false;

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

    if (mounted) {
      // Call the callback.
      await widget.onSubmitted(context);
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
    settings = getIt<Settings>();
    settings.addListener(update);

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        ByteData startBd = await rootBundle.load("assets/images/start-noshadow.png");
        final Uint8List startBytes = Uint8List.view(startBd.buffer);
        final ui.Codec startCodec = await ui.instantiateImageCodec(startBytes);
        startImage = (await startCodec.getNextFrame()).image;

        ByteData destinationBd = await rootBundle.load("assets/images/destination-noshadow.png");
        final Uint8List destinationBytes = Uint8List.view(destinationBd.buffer);
        final ui.Codec destinationCodec = await ui.instantiateImageCodec(destinationBytes);
        destinationImage = (await destinationCodec.getNextFrame()).image;

        if (startImage != null && destinationImage != null) {
          // Create TrackHistory once to prevent getting rebuild on every setState.
          trackHistory = TrackHistoryItemDetailView(
            track: tracking.previousTracks!.last,
            startImage: startImage!,
            destinationImage: destinationImage!,
          );
        }

        setState(() {});

        if (!mounted) return;
        if (tracking.previousTracks!.last.routes.length > 4) _showReroutingWarning(context);
      },
    );
  }

  @override
  void dispose() {
    routing.removeListener(update);
    tracking.removeListener(update);
    feedback.removeListener(update);
    statistics.removeListener(update);
    settings.removeListener(update);
    super.dispose();
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.background,
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

  Future<void> _showReroutingWarning(context) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: 'Hinweis',
          text: "Du scheinst nicht entlang Deiner ursprünglichen Route gefahren zu sein.\n\n"
              "Bitte beachte, dass die App Deine Route benötigt, um die passende Ampel auszuwählen und eine Prognose darzustellen.\n\n"
              "Tipp: Um ein Rerouting zu vermeiden kannst Du Zwischenwegpunkte setzen, um Deine Route besser zu planen.",
          actions: [
            BigButtonPrimary(
              label: "Schließen",
              onPressed: () => Navigator.of(context).pop(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (feedback.isSendingFeedback) return renderLoadingIndicator();
    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) return Container();

    return AnnotatedRegionWrapper(
      bottomBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      colorMode: Theme.of(context).brightness,
      child: Scaffold(
        // To avoid recalculating the map and its painting when the keyboard appears.
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: trackHistory != null ? trackHistory! : Container(),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BigButtonTertiary(
                      fillColor: Theme.of(context).colorScheme.background.withOpacity(0.75),
                      label: "Geplante Route speichern",
                      onPressed: () => showSaveShortcutSheet(context),
                      boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40, minHeight: 64),
                    ),
                    const SmallVSpace(),
                    BigButtonPrimary(
                      label: "Fertig",
                      onPressed: () async {
                        showFinishDriveDialog(context, submit);
                        if (settings.saveAudioInstructionsEnabled && !audioFeedbackSend) {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AudioRatingView()));
                          audioFeedbackSend = true;
                        }
                      },
                      boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40, minHeight: 64),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
