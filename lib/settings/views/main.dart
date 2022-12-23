import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/fcm.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/feedback/views/main.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/licenses/views.dart';
import 'package:priobike/privacy/services.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/logging/views.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/models/rerouting.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/text.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/weather/service.dart';
import 'package:provider/provider.dart';

class SettingsElement extends StatelessWidget {
  /// The title of the settings element.
  final String title;

  /// The subtitle of the settings element.
  final String? subtitle;

  /// The icon of the settings element.
  final IconData icon;

  /// The callback when the element was selected.
  final void Function() callback;

  const SettingsElement({required this.title, this.subtitle, required this.icon, required this.callback, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Tile(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        fill: Theme.of(context).colorScheme.background,
        onPressed: callback,
        content: Row(
          children: [
            Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoldContent(text: title, context: context),
                    if (subtitle != null) const SmallVSpace(),
                    if (subtitle != null)
                      Content(text: subtitle!, color: Theme.of(context).colorScheme.primary, context: context),
                  ],
                ),
                fit: FlexFit.tight),
            SizedBox(
              height: 48,
              width: 48,
              child: Icon(icon),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSelection<E> extends StatelessWidget {
  /// The elements of the selection.
  final List<E> elements;

  /// The selected element.
  final E? selected;

  /// The title for each element.
  final String Function(E e) title;

  /// The callback when the element was selected.
  final void Function(E e) callback;

  const SettingsSelection(
      {required this.elements, required this.selected, required this.title, required this.callback, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 2,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 64),
        itemCount: elements.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Tile(
              fill: elements[index] == selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.background,
              onPressed: () => callback(elements[index]),
              content: Row(
                children: [
                  Flexible(
                      child: Content(
                        text: title(elements[index]),
                        context: context,
                        color: elements[index] == selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onBackground,
                      ),
                      fit: FlexFit.tight),
                  Expanded(
                    child: Container(),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(elements[index] == selected ? Icons.check : Icons.check_box_outline_blank),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  SettingsViewState createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  /// The associated feature service, which is injected by the provider.
  late Feature feature;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated prediction status service, which is injected by the provider.
  late PredictionStatusSummary predictionStatusSummary;

  /// The associated shortcuts service, which is injected by the provider.
  late Positioning position;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated session service, which is injected by the provider.
  late Session session;

  /// The associated news service, which is injected by the provider.
  late News news;

  /// The associated weather service, which is injected by the provider.
  late Weather weather;

  @override
  void didChangeDependencies() {
    feature = Provider.of<Feature>(context);
    settings = Provider.of<Settings>(context);
    predictionStatusSummary = Provider.of<PredictionStatusSummary>(context);
    shortcuts = Provider.of<Shortcuts>(context);
    position = Provider.of<Positioning>(context);
    routing = Provider.of<Routing>(context);
    session = Provider.of<Session>(context);
    news = Provider.of<News>(context);
    weather = Provider.of<Weather>(context);
    super.didChangeDependencies();
  }

  /// A callback that is executed when a backend is selected.
  Future<void> onSelectBackend(Backend backend) async {
    // Tell the settings service that we selected the new backend.
    await settings.selectBackend(backend);

    // Tell the fcm service that we selected the new backend.
    await FCM.selectBackend(backend);

    // Reset the associated services.
    await predictionStatusSummary.reset();
    await shortcuts.reset();
    await routing.reset();
    await session.reset();
    await news.reset();

    // Load stuff for the new backend.
    await news.getArticles(context);
    await shortcuts.loadShortcuts(context);
    await predictionStatusSummary.fetch(context);
    await weather.fetch(context);

    Navigator.pop(context);
  }

  /// A callback that is executed when a predictor mode is selected.
  Future<void> onSelectPredictionMode(PredictionMode predictionMode) async {
    // Tell the settings service that we selected the new predictor mode.
    await settings.selectPredictionMode(predictionMode);

    Navigator.pop(context);
  }

  /// A callback that is executed when a sg labels mode is selected.
  Future<void> onSelectSGLabelsMode(SGLabelsMode mode) async {
    // Tell the settings service that we selected the new sg labels mode.
    await settings.selectSGLabelsMode(mode);

    Navigator.pop(context);
  }

  /// A callback that is executed when a positioning is selected.
  Future<void> onSelectPositioningMode(PositioningMode positioningMode) async {
    // Tell the settings service that we selected the new backend.
    await settings.selectPositioningMode(positioningMode);
    // Reset the position service since it depends on the positioning.
    await position.reset();

    Navigator.pop(context);
  }

  /// A callback that is executed when a routing endpoint is selected.
  Future<void> onSelectRoutingMode(RoutingEndpoint routingEndpoint) async {
    // Tell the settings service that we selected the new backend.
    await settings.selectRoutingEndpoint(routingEndpoint);

    Navigator.pop(context);
  }

  /// A callback that is executed when a rerouting is selected.
  Future<void> onSelectRerouting(Rerouting rerouting) async {
    // Tell the settings service that we selected the new rerouting.
    await settings.selectRerouting(rerouting);

    Navigator.pop(context);
  }

  /// A callback that is executed when darkMode is changed
  Future<void> onChangeColorMode(ColorMode colorMode) async {
    // Tell the settings service that we selected the new colorModePreference.
    await settings.selectColorMode(colorMode);

    Navigator.pop(context);
  }

  /// A callback that is executed when a speed mode is selected.
  Future<void> onSelectSpeedMode(SpeedMode speedMode) async {
    // Tell the settings service that we selected the new speed mode.
    await settings.selectSpeedMode(speedMode);

    Navigator.pop(context);
  }

  /// A callback that is executed when a datastream mode is selected.
  Future<void> onSelectDatastreamMode(DatastreamMode datastreamMode) async {
    // Tell the settings service that we selected the new datastream mode.
    await settings.selectDatastreamMode(datastreamMode);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: Theme.of(context).colorScheme.surface),
            SingleChildScrollView(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppBackButton(onPressed: () => Navigator.pop(context)),
                        const HSpace(),
                        SubHeader(text: "Einstellungen", context: context),
                      ],
                    ),
                    const SmallVSpace(),
                    if (feature.canEnableInternalFeatures) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 8),
                        child: Content(text: "Interne Testfeatures", context: context),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SettingsElement(
                          title: "Interne Features",
                          icon: settings.enableInternalFeatures ? Icons.check_box : Icons.check_box_outline_blank,
                          callback: () => settings.setEnableInternalFeatures(!settings.enableInternalFeatures),
                        ),
                      ),
                    ],
                    if (settings.enableInternalFeatures) ...[
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
                          title: "Testort",
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
                          callback: () => Provider.of<Tutorial>(context, listen: false).deleteCompleted(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SettingsElement(
                          title: "Datenschutz zurücksetzen",
                          icon: Icons.recycling,
                          callback: () => Provider.of<PrivacyPolicy>(context, listen: false).deleteStoredPolicy(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SettingsElement(
                          title: "Sicherheits-Warnung zurücksetzen",
                          icon: Icons.recycling,
                          callback: () => Provider.of<Settings>(context, listen: false).deleteWarning(),
                        ),
                      ),
                    ],
                    if (feature.canEnableBetaFeatures) ...[
                      const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 8),
                        child: Content(text: "Beta Testfeatures", context: context),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SettingsElement(
                          title: "Beta Features",
                          icon: settings.enableBetaFeatures ? Icons.check_box : Icons.check_box_outline_blank,
                          callback: () => settings.setEnableBetaFeatures(!settings.enableBetaFeatures),
                        ),
                      ),
                    ],
                    if (settings.enableBetaFeatures) ...[
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
                          title: "Routenneuberechnung",
                          subtitle: settings.rerouting.description,
                          icon: Icons.expand_more,
                          callback: () => showAppSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SettingsSelection(
                                  elements: Rerouting.values,
                                  selected: settings.rerouting,
                                  title: (Rerouting e) => e.description,
                                  callback: onSelectRerouting);
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SettingsElement(
                            title: "Logs",
                            icon: Icons.list,
                            callback: () =>
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogsView()))),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                        child: Small(
                          text:
                              "Wenn du Probleme mit der App hast, kannst du uns gerne die Logs schicken. Dann können wir genau sehen, was bei dir kaputt ist.",
                          context: context,
                        ),
                      ),
                    ],
                    const Padding(padding: EdgeInsets.only(left: 16, top: 8), child: Divider()),
                    const SmallVSpace(),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Content(text: "Nutzbarkeit", context: context),
                    ),
                    const SmallVSpace(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SettingsElement(
                        title: "Farbmodus",
                        subtitle: settings.colorMode.description,
                        icon: Icons.expand_more,
                        callback: () => showAppSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SettingsSelection(
                                elements: ColorMode.values,
                                selected: settings.colorMode,
                                title: (ColorMode e) => e.description,
                                callback: onChangeColorMode);
                          },
                        ),
                      ),
                    ),
                    const SmallVSpace(),
                    SettingsElement(
                      title: "Tacho-Spanne",
                      subtitle: settings.speedMode.description,
                      icon: Icons.expand_more,
                      callback: () => showAppSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SettingsSelection(
                              elements: SpeedMode.values,
                              selected: settings.speedMode,
                              title: (SpeedMode e) => e.description,
                              callback: onSelectSpeedMode);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                      child: Small(
                        text:
                            "Hinweis zur Tacho-Spanne: Du bist immer selbst verantwortlich, wie schnell du mit unserer App fahren möchtest. Bitte achte trotzdem immer auf deine Umgebung und passe deine Geschwindigkeit den Verhältnissen an.",
                        context: context,
                      ),
                    ),
                    const SmallVSpace(),
                    SettingsElement(
                      title: "Feedback geben",
                      icon: Icons.email,
                      callback: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FeedbackView(
                              onSubmitted: (context) async {
                                Navigator.pop(context);
                              },
                              isolatedViewUsage: true,
                            ),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                      child: Small(
                        text: "Feedback ist jederzeit auch möglich an: 📧 priobike@tu-dresden.de",
                        context: context,
                      ),
                    ),
                    const SmallVSpace(),
                    const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
                    const SmallVSpace(),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Content(text: "Weitere Informationen", context: context),
                    ),
                    const VSpace(),
                    SettingsElement(
                      title: "Datenschutz",
                      icon: Icons.info_outline_rounded,
                      callback: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyView()));
                      },
                    ),
                    const SmallVSpace(),
                    SettingsElement(
                      title: "Lizenzen",
                      icon: Icons.info_outline_rounded,
                      callback: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => LicenseView(appName: feature.appName, appVersion: feature.appVersion)));
                      },
                    ),
                    const SmallVSpace(),
                    SettingsElement(
                      title: "Danksagung",
                      icon: Icons.info_outline_rounded,
                      callback: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) {
                              return const AssetTextView(asset: "assets/text/thanks.txt");
                            },
                          ),
                        );
                      },
                    ),
                    const SmallVSpace(),
                    const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
                    const SmallVSpace(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Small(
                          text: "Info für Nerds: PrioBike v${feature.appVersion} ${feature.gitHead}",
                          color: Colors.grey,
                          context: context),
                    ),
                    const SizedBox(height: 128),
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
