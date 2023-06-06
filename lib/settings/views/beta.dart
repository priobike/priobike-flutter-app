import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/fcm.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/models/sg_selector.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/main.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/weather/service.dart';
import 'package:share_plus/share_plus.dart';

class BetaSettingsView extends StatefulWidget {
  const BetaSettingsView({Key? key}) : super(key: key);

  @override
  BetaSettingsViewState createState() => BetaSettingsViewState();
}

class BetaSettingsViewState extends State<BetaSettingsView> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated prediction status service, which is injected by the provider.
  late PredictionStatusSummary predictionStatusSummary;

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
    predictionStatusSummary = getIt<PredictionStatusSummary>();
    predictionStatusSummary.addListener(update);
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
    predictionStatusSummary.removeListener(update);
    shortcuts.removeListener(update);
    routing.removeListener(update);
    news.removeListener(update);
    weather.removeListener(update);
    super.dispose();
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
    boundary.loadBoundaryCoordinates(backend);

    // Load stuff for the new backend.
    await news.getArticles();
    await shortcuts.loadShortcuts();
    await predictionStatusSummary.fetch();
    await weather.fetch();

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
                    SubHeader(text: "Beta Features", context: context),
                  ],
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
                        "Innerhalb von Hamburg kannst du das DRN-Routing auswählen. Im Digitalen Radverkehrsnetz (DRN) sind alle Radwege oder durch das Rad befahrbare Straßen in Hamburg enthalten. Die Routenberechnung ist aber noch in Entwicklung und kann derzeit auch zu falschen Routen führen.",
                    context: context,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                    title: "Logs senden",
                    icon: Icons.ios_share_rounded,
                    callback: () => Share.share(Logger.db.join("\n"), subject: 'Logs für PrioBike'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                  child: Small(
                    text:
                        "Wenn du Probleme mit der App hast, kannst du uns gerne die Logs schicken. Dann können wir genau sehen, was bei dir kaputt ist.",
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
                        "Wenn du Probleme mit der Auswahl der Ampeln entlang der Route hast, kannst du diese Einstellung wechseln.",
                    context: context,
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
                  padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                  child: Small(
                    text:
                        "Diese Einstellung steht vorübergehend für interne Testzwecke in Dresden zur Verfügung. Bei Verwendung der App in Hamburg ist die entsprechende Auswahl von \"Hamburg\" erforderlich.",
                    context: context,
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
