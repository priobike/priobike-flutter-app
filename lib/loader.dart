import 'package:flutter/material.dart' hide Shortcuts, Feedback;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/main.dart';
import 'package:priobike/http.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Loader extends StatefulWidget {
  const Loader({Key? key}) : super(key: key);

  @override
  LoaderState createState() => LoaderState();
}

class LoaderState extends State<Loader> {
  /// If the app is currently loading.
  var isLoading = true;

  /// If there was an error while loading.
  var hasError = false;

  /// If the animation should morph.
  var shouldMorph = false;

  /// If the home view should be blended in.
  var shouldBlendIn = false;

  /// Initialize everything needed before we can show the home view.
  Future<void> init(BuildContext context) async {
    // Init the HTTP client for all services.
    Http.initClient();

    // Load offline map tiles.
    await AppMap.loadOfflineTiles();

    // Initialize Sentry.
    const dsn = "https://f794ea046ecf420fb65b5964b3edbf53@priobike-sentry.inf.tu-dresden.de/2";
    await SentryFlutter.init((options) => options.dsn = dsn);

    // Load the settings.
    final settings = Provider.of<Settings>(context, listen: false);
    await settings.loadSettings();

    // Load all other services.
    try {
      await Provider.of<Feature>(context, listen: false).load();
      await Provider.of<News>(context, listen: false).getArticles(context);
      await Provider.of<Profile>(context, listen: false).loadProfile();
      await Provider.of<Shortcuts>(context, listen: false).loadShortcuts(context);
      await Provider.of<Statistics>(context, listen: false).loadStatistics();
      await Provider.of<PredictionStatusSummary>(context, listen: false).fetch(context);
      await Provider.of<Layers>(context, listen: false).loadPreferences();
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      HapticFeedback.heavyImpact();
      setState(() => hasError = true);
      return;
    }

    // Finish loading.
    setState(() {
      shouldMorph = true;
      hasError = false;
    });
    // After a short delay, we can show the home view.
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => isLoading = false);
    // Make this an additional step so that the animation is smooth.
    await Future.delayed(const Duration(milliseconds: 10));
    setState(() => shouldBlendIn = true);
  }

  @override
  void initState() {
    super.initState();
    // Init the view once the app is ready.
    SchedulerBinding.instance!.addPostFrameCallback((_) => init(context));
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    return Stack(children: [
      Container(
          color: Theme.of(context).colorScheme.background,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutCubicEmphasized,
            width: frame.size.width,
            height: shouldMorph ? 128 + frame.padding.top : frame.size.height,
            alignment: shouldMorph ? Alignment.center : Alignment.topCenter,
            margin: shouldMorph
                ? EdgeInsets.only(bottom: frame.size.height - frame.padding.top - 128)
                : const EdgeInsets.only(top: 0),
            decoration: shouldMorph
                ? const BoxDecoration(
                    gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: [
                      0.1,
                      0.9,
                    ],
                    colors: [CI.lightBlue, CI.blue],
                  ))
                : const BoxDecoration(
                    gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: [
                      0.1,
                      0.9,
                    ],
                    colors: [CI.blue, CI.blue],
                  )),
          )),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        child: hasError
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Tile(
                    shadowIntensity: 0.2,
                    fill: Theme.of(context).colorScheme.background,
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 48),
                        const VSpace(),
                        BoldContent(
                          text: "Verbindungsfehler",
                          context: context,
                        ),
                        const SmallVSpace(),
                        Content(
                          text:
                              "Die App konnte keine Verbindung zu den PrioBike-Diensten aufbauen. Prüfe deine Verbindung und versuche es später erneut.",
                          context: context,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        BigButton(label: "Erneut versuchen", onPressed: () => init(context)),
                      ],
                    ),
                  ),
                ),
              )
            : Container(),
      ),
      if (!isLoading)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          child: shouldBlendIn ? const HomeView() : Container(),
        )
    ]);
  }
}
