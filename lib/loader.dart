import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart' hide Shortcuts, Feedback;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Feature, Settings;
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/load.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/main.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/migration/services.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/profile.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/auth.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/weather/service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Loader extends StatefulWidget {
  final String? shareUrl;

  const Loader({super.key, this.shareUrl});

  @override
  LoaderState createState() => LoaderState();
}

class LoaderState extends State<Loader> {
  final log = Logger("Loader");

  /// If the app is currently loading.
  var isLoading = true;

  /// If there was an error while loading.
  var hasError = false;

  /// If the location is disabled on the device.
  var locationDisabled = false;

  /// If the animation should morph.
  var shouldMorph = false;

  /// If the home view should be blended in.
  var shouldBlendIn = false;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  /// The shortcut loaded by a share link.
  Shortcut? shortcut;

  /// Initialize everything needed before we can show the home view.
  Future<void> init() async {
    // Check the load. If it is too high, later on a fallback backend might be used.
    await getIt<LoadStatus>().checkLoad();

    // We have 2 types of services:
    // 1. Services that are critically needed for the app to work and without which we won't let the user continue.
    // 2. Services that are not critically needed.
    // Loader-functions for non-critical services should handle their own errors
    // while critical services should throw their errors.

    // Critical services:
    try {
      // Check if the authentication service is online and load the auth config.
      // If the authentication service is not reachable, we won't open the app.
      final auth = await Auth.load(settings.city.selectedBackend(true));

      // Note: It is ok to set this once here, as the mapbox access token is not expected to change.
      // If we want to support different mapbox tokens per deployment in the future, we need to
      // add a listener to the settings service and update the token accordingly.
      MapboxOptions.setAccessToken(auth.mapboxAccessToken);

      await Migration.migrate();
      await getIt<Profile>().loadProfile();
      await getIt<Shortcuts>().loadShortcuts();
      await getIt<Layers>().loadPreferences();
      await getIt<MapDesigns>().loadPreferences();

      final tracking = getIt<Tracking>();
      await tracking.loadPreviousTracks();
      await tracking.runUploadRoutine();
      await tracking.setSubmissionPolicy(settings.trackingSubmissionPolicy);

      await getIt<Boundary>().loadBoundaryCoordinates();
      await getIt<Ride>().loadLastRoute();
      await MapboxTileImageCache.pruneUnusedImages();

      // Only allow portrait mode.
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      // Load shared shortcut if app was opened with sharing link
      if (widget.shareUrl != null) {
        String url = widget.shareUrl!;
        final shortcut = await Shortcut.fromLink(url);
        this.shortcut = shortcut;
      }

      settings.incrementUseCounter();
    } catch (e, stacktrace) {
      log.e("Error while loading services $e\n $stacktrace");
      HapticFeedback.heavyImpact();
      setState(() => hasError = true);
      settings.incrementConnectionErrorCounter();
      return;
    }

    // Non critical services:
    getIt<News>().getArticles();
    getIt<PredictionStatusSummary>().fetch();
    getIt<Weather>().fetch();

    // Check location permissions. After this is handled, we can show the home view.
    checkLocation();
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
      transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: 'Persönliche Daten zurücksetzen',
          text:
              "Bist Du Dir sicher, dass Du Deine persönlichen Daten zurücksetzen willst? Nach dem Bestätigen werden Deine Daten unwiderruflich verworfen. Dazu gehören unter anderem Deine erstellten Routen.",
          actions: [
            BigButtonPrimary(
              textColor: Colors.black,
              fillColor: CI.radkulturYellow,
              label: "Zurücksetzen",
              onPressed: () async {
                await _resetData();
                // remove all views and push RestartApp view, so the user can only restart the app
                await Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const RestartApp()),
                  (Route<dynamic> route) => false,
                );
              },
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
            ),
            BigButtonTertiary(
              label: "Abbrechen",
              onPressed: () => Navigator.of(context).pop(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
            )
          ],
        );
      },
    );
  }

  // This should only be called once and only after everything important is loaded.
  Future<void> setFinishLoading() async {
    // Finish loading.
    setState(() {
      shouldMorph = true;
      hasError = false;
      locationDisabled = false;
    });
    settings.resetConnectionErrorCounter();

    // After a short delay, we can show the home view.
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => isLoading = false);
    // Make this an additional step so that the animation is smooth.
    await Future.delayed(const Duration(milliseconds: 10));
    setState(() => shouldBlendIn = true);
  }

  // Request location permissions if not already granted.
  Future<void> checkLocation() async {
    final positioning = getIt<Positioning>();
    await positioning.initializePositionSource();
    LocationPermission? permission = await positioning.checkGeolocatorPermission();
    if (permission == null) {
      // --> Location services are disabled.
      setState(() {
        hasError = true;
        locationDisabled = true;
      });
      return;
    }
    // We shall not show the request dialog again if it got denied forever.
    // Later in the app, we still show dialogs that the location permission is missing and that the user can enable it
    // in the settings.
    if (permission == LocationPermission.deniedForever) {
      setFinishLoading();
      return;
    }
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setFinishLoading();
      return;
    }
    if (!mounted) return;
    // Check location permissions which are required for the app to work.
    // For Android, we need to explain the user why we need the location more explicitly.
    if (Platform.isAndroid) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black.withOpacity(0.4),
        transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
        pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
          return DialogLayout(
            title: 'Standortfreigabe',
            text:
                "PrioBike benötigt deinen Standort für die Navigation und die Anzeige von Orten und Ampeln in deiner Nähe.\n"
                "Wenn Du während der Fahrt die App minimerst oder das Handy sperrst, benutzt die App den Standort im Hintergrund, damit die Fahrt nicht unterbrochen wird und diese beim Zurückkehren zur App direkt wieder fortgesetzt werden kann.\n\n"
                "Standortfreigabe erteilen?",
            actions: [
              BigButtonPrimary(
                label: "Freigeben",
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  // We don't care whether the user has granted the permission or not.
                  // The app won't really work without it, but we still want to show the home view.
                  await positioning.requestGeolocatorPermission();
                  setFinishLoading();
                },
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
              ),
              BigButtonTertiary(
                label: "Abbrechen",
                onPressed: () {
                  Navigator.of(context).pop();
                  positioning.setLocationPermissionDialogShown();
                  setFinishLoading();
                },
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
              )
            ],
          );
        },
      );
    } else {
      // We don't care whether the user has granted the permission or not.
      // The app won't really work without it, but we still want to show the home view.
      await positioning.requestGeolocatorPermission();
      setFinishLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    return AnnotatedRegionWrapper(
      // Set to light to make sure the system bar is displayed in white on the red background of the loader.
      topTextBrightness: Brightness.light,
      bottomBackgroundColor: Theme.of(context).colorScheme.surface,
      colorMode: Brightness.dark,
      child: Stack(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOutCubicEmphasized,
              width: frame.size.width,
              height: shouldMorph ? 128 + frame.padding.top : frame.size.height,
              alignment: shouldMorph ? Alignment.center : Alignment.topCenter,
              margin: shouldMorph
                  ? EdgeInsets.only(bottom: frame.size.height - frame.padding.top - 128)
                  : const EdgeInsets.only(top: 0),
              color: Theme.of(context).colorScheme.primary,
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
                        fill: Theme.of(context).colorScheme.surface,
                        content: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 48),
                            const VSpace(),
                            BoldContent(
                              text: "Fehler beim Starten der App",
                              context: context,
                            ),
                            const SmallVSpace(),
                            Content(
                              text: locationDisabled
                                  ? "Der Standort ist nicht aktiviert auf dem Telefon. Bitte aktiviere den Standort (GPS) und versuche es erneut."
                                  : "Ein unbekannter Fehler ist aufgetreten.\nDie App kann nicht gestartet werden.",
                              context: context,
                              textAlign: TextAlign.center,
                            ),
                            const SmallVSpace(),
                            settings.connectionErrorCounter >= 3 ? const SizedBox(height: 16) : Container(),
                            settings.connectionErrorCounter >= 3
                                ? BigButtonPrimary(
                                    label: "Logs teilen",
                                    onPressed: () async => Share.share(await Logger.read(), subject: 'Logs PrioBike'))
                                : Container(),
                            settings.connectionErrorCounter >= 3 ? const SizedBox(height: 16) : Container(),
                            settings.connectionErrorCounter >= 3
                                ? BigButtonPrimary(
                                    label: "Daten zurücksetzen", onPressed: () => _showResetDialog(context))
                                : Container(),
                            const SizedBox(height: 16),
                            BigButtonPrimary(label: "Erneut versuchen", onPressed: () => init()),
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
              child: shouldBlendIn
                  ? HomeView(
                      shortcut: shortcut,
                    )
                  : Container(),
            )
        ],
      ),
    );
  }
}

class RestartApp extends StatelessWidget {
  const RestartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const VSpace(),
            BoldContent(text: "Bitte App neustarten", context: context),
            const SmallVSpace(),
            Content(
              text: "Die Daten wurden zurückgesetzt.\nDie App muss neu gestartet werden, um fortzufahren.",
              context: context,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
