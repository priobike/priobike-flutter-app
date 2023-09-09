import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/fcm.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/services/challenges_profile_service.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/privacy/services.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/main.dart';
import 'package:priobike/status/services/status_history.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/weather/service.dart';

class InternalSettingsView extends StatefulWidget {
  const InternalSettingsView({Key? key}) : super(key: key);

  @override
  InternalSettingsViewState createState() => InternalSettingsViewState();
}

class InternalSettingsViewState extends State<InternalSettingsView> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated shortcuts service, which is injected by the provider.
  late Positioning position;

  /// The associated prediction status service, which is injected by the provider.
  late PredictionStatusSummary predictionStatusSummary;

  /// The associated status history service, which is injected by the provider.
  late StatusHistory statusHistory;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated news service, which is injected by the provider.
  late News news;

  /// The associated weather service, which is injected by the provider.
  late Weather weather;

  /// The associated bounding box service, which is injected by the provider.
  late Boundary boundary;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);
    position = getIt<Positioning>();
    position.addListener(update);
    predictionStatusSummary = getIt<PredictionStatusSummary>();
    predictionStatusSummary.addListener(update);
    statusHistory = getIt<StatusHistory>();
    statusHistory.addListener(update);
    shortcuts = getIt<Shortcuts>();
    shortcuts.addListener(update);
    routing = getIt<Routing>();
    routing.addListener(update);
    news = getIt<News>();
    news.addListener(update);
    weather = getIt<Weather>();
    weather.addListener(update);
    boundary = getIt<Boundary>();
  }

  @override
  void dispose() {
    settings.removeListener(update);
    position.removeListener(update);
    predictionStatusSummary.removeListener(update);
    statusHistory.removeListener(update);
    shortcuts.removeListener(update);
    routing.removeListener(update);
    news.removeListener(update);
    weather.removeListener(update);
    super.dispose();
  }

  /// A callback that is executed when a predictor mode is selected.
  Future<void> onSelectPredictionMode(PredictionMode predictionMode) async {
    // Tell the settings service that we selected the new predictor mode.
    await settings.setPredictionMode(predictionMode);

    if (mounted) Navigator.pop(context);
  }

  /// A callback that is executed when a sg labels mode is selected.
  Future<void> onSelectSGLabelsMode(SGLabelsMode mode) async {
    // Tell the settings service that we selected the new sg labels mode.
    await settings.setSGLabelsMode(mode);

    if (mounted) Navigator.pop(context);
  }

  /// A callback that is executed when a positioning is selected.
  Future<void> onSelectPositioningMode(PositioningMode positioningMode) async {
    // Tell the settings service that we selected the new backend.
    await settings.setPositioningMode(positioningMode);
    // Reset the position service since it depends on the positioning.
    await position.reset();

    if (mounted) Navigator.pop(context);
  }

  /// A callback that is executed when a datastream mode is selected.
  Future<void> onSelectDatastreamMode(DatastreamMode datastreamMode) async {
    // Tell the settings service that we selected the new datastream mode.
    await settings.setDatastreamMode(datastreamMode);

    if (mounted) Navigator.pop(context);
  }

  /// A callback that is executed when a backend is selected.
  Future<void> onSelectBackend(Backend backend) async {
    // Tell the settings service that we selected the new backend.
    await settings.setBackend(backend);

    // Tell the fcm service that we selected the new backend.
    await FCM.selectTopic(backend);

    // Reset the associated services.
    await predictionStatusSummary.reset();
    await statusHistory.reset();
    await shortcuts.reset();
    await routing.reset();
    await news.reset();

    // Load stuff for the new backend.
    await news.getArticles();
    await shortcuts.loadShortcuts();
    await predictionStatusSummary.fetch();
    await statusHistory.fetch();
    await weather.fetch();
    await boundary.loadBoundaryCoordinates();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppBackButton(onPressed: () => Navigator.pop(context)),
                    const HSpace(),
                    SubHeader(text: "Interne Features", context: context),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Performance-Overlay",
                    icon: settings.enablePerformanceOverlay ? Icons.check_box : Icons.check_box_outline_blank,
                    callback: () => settings.setEnablePerformanceOverlay(!settings.enablePerformanceOverlay),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Prognosealgorithmus",
                    subtitle: settings.predictionMode.description,
                    icon: Icons.expand_more,
                    callback: () => showAppSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SettingsSelection(
                            elements: PredictionMode.values,
                            selected: settings.predictionMode,
                            title: (PredictionMode e) => e.description,
                            callback: onSelectPredictionMode);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Ortung",
                    subtitle: settings.positioningMode.description,
                    icon: Icons.expand_more,
                    callback: () => showAppSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SettingsSelection(
                          elements: PositioningMode.values,
                          selected: settings.positioningMode,
                          title: (PositioningMode e) => e.description,
                          callback: onSelectPositioningMode,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Ort",
                    subtitle: settings.backend.region,
                    icon: Icons.expand_more,
                    callback: () => showAppSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SettingsSelection(
                            elements: Backend.values,
                            selected: settings.backend,
                            title: (Backend e) => e.region,
                            callback: onSelectBackend);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "SG-Info",
                    subtitle: settings.sgLabelsMode.description,
                    icon: Icons.expand_more,
                    callback: () => showAppSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SettingsSelection(
                          elements: SGLabelsMode.values,
                          selected: settings.sgLabelsMode,
                          title: (SGLabelsMode e) => e.description,
                          callback: onSelectSGLabelsMode,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Echtzeitdaten",
                    subtitle: settings.datastreamMode.description,
                    icon: Icons.expand_more,
                    callback: () => showAppSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SettingsSelection(
                          elements: DatastreamMode.values,
                          selected: settings.datastreamMode,
                          title: (DatastreamMode e) => e.description,
                          callback: onSelectDatastreamMode,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Tutorials zurücksetzen",
                    icon: Icons.recycling,
                    callback: () => getIt<Tutorial>().deleteCompleted(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Datenschutz zurücksetzen",
                    icon: Icons.recycling,
                    callback: () => getIt<PrivacyPolicy>().deleteStoredPolicy(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Sicherheits-Warnung zurücksetzen",
                    icon: Icons.recycling,
                    callback: () => getIt<Settings>().setDidViewWarning(false),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Umfrage zurücksetzen",
                    icon: Icons.recycling,
                    callback: () => getIt<Settings>().setDismissedSurvey(false),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    callback: () => AppDatabase.instance.challengeDao.clearObjects(),
                    title: 'Challenges zurücksetzen',
                    icon: Icons.recycling,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Game-Profil zurücksetzen",
                    icon: Icons.recycling,
                    callback: () async {
                      await getIt<GamificationUserService>().reset();
                      await getIt<ChallengesProfileService>().reset();
                      await getIt<UserGoalsService>().reset();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Gamification",
                    icon: settings.enableGamification ? Icons.check_box : Icons.check_box_outline_blank,
                    callback: () => settings.setEnableGamification(!settings.enableGamification),
                  ),
                ),
                const SmallVSpace(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
