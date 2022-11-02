import 'package:flutter/material.dart' hide Shortcuts, Feedback;
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/main.dart';
import 'package:priobike/http.dart';
import 'package:priobike/news/services/news.dart';
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
    await Provider.of<Feature>(context, listen: false).load();
    await Provider.of<News>(context, listen: false).getArticles(context);
    await Provider.of<Profile>(context, listen: false).loadProfile();
    await Provider.of<Shortcuts>(context, listen: false).loadShortcuts(context);
    await Provider.of<Statistics>(context, listen: false).loadStatistics();
    await Provider.of<PredictionStatusSummary>(context, listen: false).fetch(context);

    // Finish loading.
    setState(() => shouldMorph = true);
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
          height: shouldMorph ? 148 + frame.padding.top : frame.size.height,
          alignment: shouldMorph ? Alignment.center : Alignment.topCenter,
          margin: shouldMorph 
            ? EdgeInsets.only(bottom: frame.size.height - 148)
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
                colors: [
                  Color.fromARGB(255, 0, 198, 255),
                  Color.fromARGB(255, 0, 115, 255)
                ],
              )
            )
            : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: [
                  0.1,
                  0.9,
                ],
                colors: [
                  Color.fromARGB(255, 0, 115, 255),
                  Color.fromARGB(255, 0, 115, 255)
                ],
              )
            ),
        )
      ),
      if (!isLoading) AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        child: shouldBlendIn 
          ? const HomeView()
          : Container(),
      )
    ]);
  }
}