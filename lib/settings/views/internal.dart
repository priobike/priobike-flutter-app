import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/fcm.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/home/services/load.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/migration/services.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/privacy/services.dart';
import 'package:priobike/ride/views/free.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart' hide Simulator;
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/models/sg_selector.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/main.dart';
import 'package:priobike/simulator/services/simulator.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/status/views/status.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/weather/service.dart';
import 'package:share_plus/share_plus.dart';

class InternalSettingsView extends StatefulWidget {
  const InternalSettingsView({super.key});

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

  /// The associated load status service, which is injected by the provider.
  late LoadStatus loadStatus;

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

  /// The simulator service, which is injected by the provider.
  late Simulator simulator;

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
    loadStatus = getIt<LoadStatus>();
    shortcuts = getIt<Shortcuts>();
    shortcuts.addListener(update);
    routing = getIt<Routing>();
    routing.addListener(update);
    news = getIt<News>();
    news.addListener(update);
    weather = getIt<Weather>();
    weather.addListener(update);
    simulator = getIt<Simulator>();
    simulator.addListener(update);
    boundary = getIt<Boundary>();
  }

  @override
  void dispose() {
    settings.removeListener(update);
    position.removeListener(update);
    predictionStatusSummary.removeListener(update);
    shortcuts.removeListener(update);
    routing.removeListener(update);
    news.removeListener(update);
    weather.removeListener(update);
    simulator.removeListener(update);
    super.dispose();
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
    await shortcuts.reset();
    await routing.reset();
    await news.reset();

    // Load stuff for the new backend.
    await news.getArticles();
    await shortcuts.loadShortcuts();
    await predictionStatusSummary.fetch();
    await loadStatus.fetch();
    loadStatus.sendAppStartNotification();
    await weather.fetch();
    await boundary.loadBoundaryCoordinates();

    if (mounted) Navigator.pop(context);
  }

  /// A callback that adds test migration data for testing.
  void addTestMigrationData() {
    Migration.addTestMigrationData();
  }

  /// A callback that is executed when a routing endpoint is selected.
  Future<void> onSelectRoutingMode(RoutingEndpoint routingEndpoint) async {
    // Tell the settings service that we selected the new backend.
    await settings.setRoutingEndpoint(routingEndpoint);

    if (mounted) Navigator.pop(context);
  }

  /// A callback that is executed when a sg-selector is selected.
  Future<void> onSelectSGSelector(SGSelector sgSelector) async {
    // Tell the settings service that we selected the new sg-selector.
    await settings.setSGSelector(sgSelector);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWrapper(
      bottomBackgroundColor: Theme.of(context).colorScheme.background,
      colorMode: Theme.of(context).brightness,
      child: Scaffold(
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
                const VSpace(),
                const Row(
                  children: [
                    SizedBox(width: 10),
                    Expanded(
                      child: StatusView(showPercentage: true),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                const VSpace(),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Freie Fahrt",
                    icon: Icons.directions_bike_rounded,
                    callback: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const FreeRideView(),
                      ),
                      (route) => false,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Freie Fahrt Filter",
                    icon: settings.isFreeRideFilterEnabled ? Icons.check_box : Icons.check_box_outline_blank,
                    callback: () => settings.setFreeRideFilterEnabled(!settings.isFreeRideFilterEnabled),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Sprachausgabe aktivieren",
                    icon: settings.audioInstructionsEnabled ? Icons.check_box : Icons.check_box_outline_blank,
                    callback: () => settings.setAudioInstructionsEnabled(!settings.audioInstructionsEnabled),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                  child: Small(
                    text:
                        "Aktiviere die Sprachausgabe, um während der Fahrt Informationen über Lautsprecher oder Kopfhörer zu erhalten. Du kannst die App somit jetzt auch ohne eingeschaltetes Display aus der Hosentasche heraus nutzen.",
                    context: context,
                  ),
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
                    title: "Erhöhte Genauigkeit der Geschwindigkeit im Tacho",
                    icon: settings.isIncreasedSpeedPrecisionInSpeedometerEnabled
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    callback: () => settings.setIncreasedSpeedPrecisionInSpeedometerEnabled(
                        !settings.isIncreasedSpeedPrecisionInSpeedometerEnabled),
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
                    title: "Ampel-Suchleiste in Status-Ansicht",
                    icon: settings.enableTrafficLightSearchBar ? Icons.check_box : Icons.check_box_outline_blank,
                    callback: () => settings.setEnableTrafficLightSearchBar(!settings.enableTrafficLightSearchBar),
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
                    title: "Routing",
                    subtitle: settings.routingEndpoint.description,
                    icon: Icons.expand_more,
                    callback: () => showAppSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SettingsSelection(
                          elements: RoutingEndpoint.values,
                          selected: settings.routingEndpoint,
                          title: (RoutingEndpoint e) => e.description,
                          callback: onSelectRoutingMode,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                  child: Small(
                    text:
                        "Innerhalb von Hamburg kannst Du das DRN-Routing auswählen. Im Digitalen Radverkehrsnetz (DRN) sind alle Radwege oder durch das Rad befahrbare Straßen in Hamburg enthalten. Die Routenberechnung ist aber noch in Entwicklung und kann derzeit auch zu falschen Routen führen.",
                    context: context,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Logs aufzeichnen",
                    icon: settings.enableLogPersistence ? Icons.check_box : Icons.check_box_outline_blank,
                    callback: () async {
                      await settings.setEnableLogPersistence(!settings.enableLogPersistence);
                      await Logger.init(settings.enableLogPersistence);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Logs senden",
                    icon: Icons.ios_share_rounded,
                    callback: () async => Share.share(await Logger.read(), subject: 'Logs für PrioBike'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Logs öffnen",
                    icon: Icons.open_in_browser_rounded,
                    callback: () => showAppSheet(
                      context: context,
                      builder: (BuildContext context) {
                        // Simple text view
                        return SingleChildScrollView(
                          reverse: true,
                          child: FutureBuilder<String>(
                            future: Logger.read(),
                            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                              if (snapshot.hasData) {
                                return SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                                    child: Small(
                                      text: snapshot.data!.isEmpty ? "Noch keine Logs aufgezeichnet." : snapshot.data!,
                                      context: context,
                                    ),
                                  ),
                                );
                              }
                              return const Center(child: CircularProgressIndicator());
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                  child: Small(
                    text:
                        "Wenn Du Probleme mit der App hast, kannst Du uns gerne die Logs schicken. Dann können wir genau sehen, was bei Dir kaputt ist.",
                    context: context,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Auswahl der Ampeln",
                    subtitle: settings.sgSelector.description,
                    icon: Icons.expand_more,
                    callback: () => showAppSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SettingsSelection(
                          elements: SGSelector.values,
                          selected: settings.sgSelector,
                          title: (SGSelector e) => e.description,
                          callback: onSelectSGSelector,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                  child: Small(
                    text:
                        "Wenn Du Probleme mit der Auswahl der Ampeln entlang der Route hast, kannst Du diese Einstellung wechseln.",
                    context: context,
                  ),
                ),
                const SmallVSpace(),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Simulator nutzen (App-ID: ${getIt<Simulator>().appId})",
                    icon: settings.enableSimulatorMode ? Icons.check_box : Icons.check_box_outline_blank,
                    callback: () => settings.setSimulatorMode(!settings.enableSimulatorMode),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                  child: !settings.enableSimulatorMode
                      ? Small(
                          text: "Hinweis: Startet den Verbindungsprozess mit dem PrioBike Simulator.",
                          context: context,
                        )
                      : !simulator.paired
                          ? simulator.pairingInProgress
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      height: 12,
                                      width: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SmallHSpace(),
                                    Flexible(
                                      child: Small(
                                        text: "Verbindungsanfrage an Simulator gesendet. Bitte warten oder abbrechen.",
                                        context: context,
                                      ),
                                    ),
                                  ],
                                )
                              : simulator.pairAcknowledgements.isNotEmpty
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Small(
                                          text:
                                              "Folgende(r) Simulator(en) stehen für die Verbindung zur Verfüung. Bitte auswählen.",
                                          context: context,
                                        ),
                                        for (var i = 0; i < simulator.pairAcknowledgements.length; i++)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: SettingsElement(
                                              title: "Simulator ${simulator.pairAcknowledgements[i]}",
                                              icon: Icons.computer_rounded,
                                              callback: () =>
                                                  simulator.acknowledgePairing(simulator.pairAcknowledgements[i]),
                                            ),
                                          ),
                                      ],
                                    )
                                  : Small(
                                      text:
                                          "Verbindung mit Simulator konnte nicht hergestellt werden. Grund dafür kann eine zu häufige Anfrage oder ein Fehler im System sein.",
                                      context: context,
                                    )
                          : Small(
                              text: "Verbindung mit Simulator hergestellt. Du kannst jetzt den Simulator verwenden.",
                              context: context,
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
                    title: "Hintergrundbilder löschen (Neustart notw.)",
                    icon: Icons.recycling,
                    callback: () => MapboxTileImageCache.deleteAllImages(true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Nutzertransfer zurücksetzen",
                    icon: Icons.recycling,
                    callback: () async {
                      await getIt<Settings>().setDidViewUserTransfer(false);
                    },
                  ),
                ),
                const SmallVSpace(),
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                  child: Small(
                    text:
                        "Durch das Drücken von Migration testen werden jeweils ein Test-Shortcut und eine Test-Suchanfrage angelegt (staging, production, release). Diese müssten korrekterweise nach einem Neustart der App jeweils in den verschiedenen Versionen mit angezeigt werden.",
                    context: context,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Migration testen",
                    icon: Icons.start,
                    callback: addTestMigrationData,
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
