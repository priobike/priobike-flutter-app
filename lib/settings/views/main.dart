import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/fcm.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/feedback/views/main.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/logging/views.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/models/rerouting.dart';
import 'package:priobike/settings/models/ride.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/text.dart';
import 'package:priobike/tutorial/service.dart';
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

  const SettingsElement({
    required this.title, 
    this.subtitle, 
    required this.icon, 
    required this.callback,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Tile(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24), 
          bottomLeft: Radius.circular(24)
        ),
        fill: Theme.of(context).colorScheme.background,
        content: Row(children: [
          Flexible(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldContent(text: title, context: context),
              if (subtitle != null)
                const SmallVSpace(),
              if (subtitle != null) 
                Content(text: subtitle!, color: Theme.of(context).colorScheme.primary, context: context),
            ],
          ), fit: FlexFit.tight),
          SmallIconButton(
            icon: icon, 
            onPressed: callback,
            fill: Theme.of(context).colorScheme.surface,
          ),
        ]),
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

  const SettingsSelection({
    required this.elements, 
    required this.selected,
    required this.title,
    required this.callback,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      color: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
        itemCount: elements.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Tile(
              fill: elements[index] == selected
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.background, 
              content: Row(children: [
                Flexible(child: Content(
                  text: title(elements[index]), 
                  context: context,
                  color: elements[index] == selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onBackground,
                ), fit: FlexFit.tight),
                Expanded(child: Container()),
                SmallIconButton(
                  icon: elements[index] == selected
                    ? Icons.check 
                    : Icons.check_box_outline_blank, 
                  onPressed: () => callback(elements[index]),
                ),
              ])
            )
          );
        }
      )
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

  /// The associated routingOLD service, which is injected by the provider.
  late Routing routing;

  /// The associated session service, which is injected by the provider.
  late Session session;

  /// The associated news service, which is injected by the provider.
  late News news;

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

  /// A callback that is executed when a routingOLD endpoint is selected.
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

  /// A callback that is executed when a ride views preference is selected.
  Future<void> onSelectRidePreference(RidePreference ridePreference) async {
    // Tell the settings service that we selected the new ridePreference.
    await settings.selectRidePreference(ridePreference);

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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light 
        ? SystemUiOverlayStyle.dark 
        : SystemUiOverlayStyle.light,
      child: Scaffold(body: Stack(children: [
        Container(color: Theme.of(context).colorScheme.surface),
        SingleChildScrollView(
          child: SafeArea(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(children: [
                AppBackButton(onPressed: () => Navigator.pop(context), icon: Icons.chevron_left,),
                const HSpace(),
                SubHeader(text: "Einstellungen", context: context),
              ]),
              const SmallVSpace(),

              if (feature.canEnableInternalFeatures) 
                const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
              if (feature.canEnableInternalFeatures) 
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8), 
                  child: Content(text: "Interne Testfeatures", context: context),
                ),

              if (feature.canEnableInternalFeatures)
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Interne Features", 
                  icon: settings.enableInternalFeatures ? Icons.check_box : Icons.check_box_outline_blank, 
                  callback: () => settings.setEnableInternalFeatures(!settings.enableInternalFeatures),
                )),

              if (settings.enableInternalFeatures) 
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Testort", 
                  subtitle: settings.backend.region, 
                  icon: Icons.expand_more, 
                  callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                    return SettingsSelection(
                      elements: Backend.values, 
                      selected: settings.backend,
                      title: (Backend e) => e.region, 
                      callback: onSelectBackend
                    );
                  }),
                )),
                
              if (settings.enableInternalFeatures) 
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Ortung", 
                  subtitle: settings.positioningMode.description, 
                  icon: Icons.expand_more, 
                  callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                    return SettingsSelection(
                      elements: PositioningMode.values, 
                      selected: settings.positioningMode, 
                      title: (PositioningMode e) => e.description,
                      callback: onSelectPositioningMode,
                    );
                  }),
                )),

              if (settings.enableInternalFeatures) 
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "SG-Info", 
                  subtitle: settings.sgLabelsMode.description, 
                  icon: Icons.expand_more, 
                  callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                    return SettingsSelection(
                      elements: SGLabelsMode.values, 
                      selected: settings.sgLabelsMode,
                      title: (SGLabelsMode e) => e.description, 
                      callback: onSelectSGLabelsMode,
                    );
                  }),
                )),

              if (settings.enableInternalFeatures)
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Tutorials zurücksetzen", 
                  icon: Icons.recycling, 
                  callback: () => Provider.of<Tutorial>(context, listen: false).deleteCompleted(),
                )),

              if (feature.canEnableBetaFeatures) 
                const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
              if (feature.canEnableBetaFeatures) 
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8), 
                  child: Content(text: "Beta Testfeatures", context: context),
                ),

              if (feature.canEnableBetaFeatures)
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Beta Features", 
                  icon: settings.enableBetaFeatures ? Icons.check_box : Icons.check_box_outline_blank, 
                  callback: () => settings.setEnableBetaFeatures(!settings.enableBetaFeatures),
                )),

              if (settings.enableBetaFeatures)
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Routing", 
                  subtitle: settings.routingEndpoint.description, 
                  icon: Icons.expand_more, 
                  callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                    return SettingsSelection(
                      elements: RoutingEndpoint.values, 
                      selected: settings.routingEndpoint,
                      title: (RoutingEndpoint e) => e.description, 
                      callback: onSelectRoutingMode,
                    );
                  }),
                )),

              if (settings.enableBetaFeatures)
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Routenneuberechnung", 
                  subtitle: settings.rerouting.description, 
                  icon: Icons.expand_more, 
                  callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                    return SettingsSelection(
                      elements: Rerouting.values, 
                      selected: settings.rerouting,
                      title: (Rerouting e) => e.description, 
                      callback: onSelectRerouting
                    );
                  }),
                )),

              if (settings.enableBetaFeatures)
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Logs", 
                  icon: Icons.list, 
                  callback: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogsView()))),
                ),

              const Padding(padding: EdgeInsets.only(left: 16, top: 8), child: Divider()),

              const SmallVSpace(),
              Padding(
                padding: const EdgeInsets.only(left: 32), 
                child: Content(text: "Nutzbarkeit", context: context),
              ),
              const SmallVSpace(),
              Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                title: "Farbmodus",
                subtitle: settings.colorMode.description,
                icon: Icons.expand_more,
                callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                  return SettingsSelection(
                      elements: ColorMode.values,
                      selected: settings.colorMode,
                      title: (ColorMode e) => e.description,
                      callback: onChangeColorMode
                  );
                }),
                ),
              ),
              const SmallVSpace(),
              SettingsElement(
                title: "Fahrtansicht", 
                subtitle: settings.ridePreference?.description, 
                icon: Icons.expand_more, 
                callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                  return SettingsSelection(
                    elements: RidePreference.values, 
                    selected: settings.ridePreference,
                    title: (RidePreference e) => e.description, 
                    callback: onSelectRidePreference
                  );
                }),
              ),
              const SmallVSpace(),
              SettingsElement(
                title: "Tacho-Spanne", 
                subtitle: settings.speedMode.description, 
                icon: Icons.expand_more, 
                callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                  return SettingsSelection(
                    elements: SpeedMode.values, 
                    selected: settings.speedMode,
                    title: (SpeedMode e) => e.description, 
                    callback: onSelectSpeedMode
                  );
                }),
              ),
              const SmallVSpace(),
              SettingsElement(title: "Feedback geben", icon: Icons.email, callback: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => FeedbackView(
                  onSubmitted: (context) async { Navigator.pop(context); },
                  showBackButton: true,
                )));
              }),
              const SmallVSpace(),
              const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
              const SmallVSpace(),
              Padding(
                padding: const EdgeInsets.only(left: 32), 
                child: Content(text: "Weitere Informationen", context: context),
              ),
              const VSpace(),
              SettingsElement(title: "Datenschutz", icon: Icons.info, callback: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyView()));
              }),
              const SmallVSpace(),
              SettingsElement(title: "Lizenzen", icon: Icons.info, callback: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                  return const AssetTextView(asset: "assets/text/licenses.txt");
                }));
              }),
              const SmallVSpace(),
              SettingsElement(title: "Danksagung", icon: Icons.info, callback: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                  return const AssetTextView(asset: "assets/text/thanks.txt");
                }));
              }),
              const SmallVSpace(),
              const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
              const SmallVSpace(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32), 
                child: Small(
                  text: "PrioBike v${feature.appVersion} ${feature.gitHead}", 
                  color: Colors.grey,
                  context: context
                ),
              ),

              const SizedBox(height: 128),
            ],
          )),
        ),
      ]),
    ));
  }
}