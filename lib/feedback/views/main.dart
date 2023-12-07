import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/feedback/views/stars.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
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

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  /// The image of the route start icon.
  ui.Image? startImage;

  /// The image of the route destination icon.
  ui.Image? destinationImage;

  Widget? trackHistory;

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

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        ByteData startBd = await rootBundle.load("assets/images/start.drawio.png");
        final Uint8List startBytes = Uint8List.view(startBd.buffer);
        final ui.Codec startCodec = await ui.instantiateImageCodec(startBytes);
        startImage = (await startCodec.getNextFrame()).image;

        ByteData destinationBd = await rootBundle.load("assets/images/destination.drawio.png");
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
      },
    );
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

  @override
  Widget build(BuildContext context) {
    if (feedback.isSendingFeedback) return renderLoadingIndicator();
    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) return Container();

    // get street names
    final start = routing.selectedWaypoints!.first.address?.split(",")[0] ?? "";
    final end = routing.selectedWaypoints!.last.address?.split(",")[0] ?? "";

    // 2 * 36 (buttons) + 16 Padding + 1/6 height (stars).
    final bottomSheetHeight = 2 * 36 + 16 + MediaQuery.of(context).size.height / 6;

    return AnnotatedRegionWrapper(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      brightness: Theme.of(context).brightness,
      systemNavigationBarIconBrightness: Brightness.light,
      child: Scaffold(
        body: SizedBox(
          height: MediaQuery.of(context).size.height - bottomSheetHeight,
          child: SingleChildScrollView(
            key: const ValueKey("feedback_scroll_view"),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 0),
                  child: () {
                    if (start == "" || end == "") {
                      return BoldContent(
                        text: "Fahrt",
                        context: context,
                        textAlign: TextAlign.center,
                      );
                    } else {
                      return Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        direction: Axis.horizontal,
                        runSpacing: 8,
                        children: [
                          Content(
                            text: "Von ",
                            context: context,
                          ),
                          Content(
                            text: start,
                            context: context,
                          ),
                          Content(
                            text: " nach ",
                            context: context,
                          ),
                          Content(
                            text: end,
                            context: context,
                          )
                        ],
                      );
                    }
                  }(),
                ),
                const SmallVSpace(),
                trackHistory != null ? trackHistory! : Container(),
              ],
            ),
          ),
        ),
        bottomSheet: Container(
          width: MediaQuery.of(context).size.width,
          height: bottomSheetHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: StarRatingView(
                  text: "Dein Feedback zur App",
                  displayQuestion: true,
                ),
              ),
              BigButtonPrimary(
                // iconColor: Colors.white,
                // icon: Icons.check,
                // fillColor: Theme.of(context).colorScheme.background.withOpacity(0.25),
                label: "Fertig",
                onPressed: () => submit(),
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40, minHeight: 36),
              ),
              BigButtonPrimary(
                // iconColor: Colors.white,
                // icon: Icons.save_rounded,
                // fillColor: Theme.of(context).colorScheme.background.withOpacity(0.25),
                label: "Strecke speichern",
                onPressed: () => showSaveShortcutSheet(context),
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
