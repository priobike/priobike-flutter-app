import 'package:flutter/material.dart' hide Shortcuts, Feedback;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/gamification/common/services/evaluation_data_service.dart';
import 'package:priobike/gamification/community_event/service/event_service.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/main.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/status_history.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/weather/service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Loader extends StatefulWidget {
  const Loader({Key? key}) : super(key: key);

  @override
  LoaderState createState() => LoaderState();
}

class LoaderState extends State<Loader> {
  final log = Logger("Loader");

  /// If the app is currently loading.
  var isLoading = true;

  /// If there was an error while loading.
  var hasError = false;

  /// If the animation should morph.
  var shouldMorph = false;

  /// If the home view should be blended in.
  var shouldBlendIn = false;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  /// Initialize everything needed before we can show the home view.
  Future<void> init() async {
    // Init the HTTP client for all services.
    Http.initClient();

    // We have 2 types of services:
    // 1. Services that are critically needed for the app to work and without which we won't let the user continue.
    // 2. Services that are not critically needed.
    // Loader-functions for non-critical services should handle their own errors
    // while critical services should throw their errors.

    try {
      await getIt<Profile>().loadProfile();
      await getIt<Shortcuts>().loadShortcuts();
      await getIt<Layers>().loadPreferences();
      await getIt<MapDesigns>().loadPreferences();

      final tracking = getIt<Tracking>();
      await tracking.loadPreviousTracks();
      await tracking.runUploadRoutine();
      await tracking.setSubmissionPolicy(settings.trackingSubmissionPolicy);

      await getIt<News>().getArticles();

      final preditionStatusSummary = getIt<PredictionStatusSummary>();
      await preditionStatusSummary.fetch();
      if (preditionStatusSummary.hadError) throw Exception("Error while fetching prediction status summary");

      await getIt<StatusHistory>().fetch();
      await getIt<Weather>().fetch();
      await getIt<Boundary>().loadBoundaryCoordinates();
      await getIt<Ride>().loadLastRoute();
      await getIt<EventService>().fetchData();
      await MapboxTileImageCache.pruneUnusedImages();
      getIt<EvaluationDataService>().sendUnsentElements();

      settings.incrementUseCounter();
    } catch (e, stacktrace) {
      log.e("Error while loading services $e\n $stacktrace");
      HapticFeedback.heavyImpact();
      setState(() => hasError = true);
      settings.incrementConnectionErrorCounter();
      return;
    }

    // Finish loading.
    setState(() {
      shouldMorph = true;
      hasError = false;
      settings.resetConnectionErrorCounter();
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

    settings = getIt<Settings>();
    settings.addListener(update);

    // Init the view once the app is ready.
    SchedulerBinding.instance.addPostFrameCallback((_) => init());
  }

  @override
  void dispose() {
    settings.removeListener(update);
    super.dispose();
  }

  _resetData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

  void _showResetDialog(context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: 'Persönliche Daten zurücksetzen',
          text:
              "Sind sie sich sicher, dass sie ihre persönlichen Daten zurücksetzen wollen? Nach dem Bestätigen werden ihre Daten unwiderruflich verworfen. Dazu gehören unter Anderem ihre erstellten Routen.",
          icon: Icons.delete_forever_rounded,
          iconColor: CI.radkulturYellow,
          actions: [
            BigButton(
              iconColor: Colors.white,
              icon: Icons.delete_forever_rounded,
              fillColor: CI.radkulturYellow,
              label: "Zurücksetzen",
              onPressed: () async {
                await _resetData();
                ToastMessage.showSuccess("Daten zurück gesetzt!");
                if (mounted) Navigator.of(context).pop();
              },
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            ),
            BigButton(
              label: "Abbrechen",
              onPressed: () => Navigator.of(context).pop(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    return Stack(
      children: [
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
                      colors: [CI.radkulturRed, CI.radkulturRedDark],
                    ),
                  )
                : const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      stops: [
                        0.1,
                        0.9,
                      ],
                      colors: [CI.radkulturRed, CI.radkulturRed],
                    ),
                  ),
          ),
        ),
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
                            text: "Die App konnte keine Verbindung zu den PrioBike-Diensten aufbauen.",
                            context: context,
                            textAlign: TextAlign.center,
                          ),
                          Content(
                            text: "Prüfe deine Verbindung und versuche es später erneut.",
                            context: context,
                            textAlign: TextAlign.center,
                          ),
                          const SmallVSpace(),
                          settings.connectionErrorCounter >= 3 ? const SizedBox(height: 16) : Container(),
                          settings.connectionErrorCounter >= 3
                              ? BigButton(
                                  label: "Logs teilen",
                                  onPressed: () => Share.share(Logger.db.join("\n"), subject: 'Logs PrioBike'))
                              : Container(),
                          settings.connectionErrorCounter >= 3 ? const SizedBox(height: 16) : Container(),
                          settings.connectionErrorCounter >= 3
                              ? BigButton(label: "Daten zurücksetzen", onPressed: () => _showResetDialog(context))
                              : Container(),
                          const SizedBox(height: 16),
                          BigButton(label: "Erneut versuchen", onPressed: () => init()),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          child: isLoading && !hasError && !shouldMorph
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 128),
                    child: CircularProgressIndicator(color: Colors.white),
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
      ],
    );
  }
}
