import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/feedback/views/main.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/services/status.dart';
import 'package:priobike/logging/views.dart';
import 'package:priobike/news/service.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/routing/services/routing.dart';
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
  late FeatureService featureService;

  /// The associated settings service, which is injected by the provider.
  late SettingsService settingsService;

  /// The associated shortcuts service, which is injected by the provider.
  late ShortcutsService shortcutsService;

  /// The associated prediction status service, which is injected by the provider.
  late PredictionStatusService predictionStatusService;

  /// The associated shortcuts service, which is injected by the provider.
  late PositionService positionService;

  /// The associated routing service, which is injected by the provider.
  late RoutingService routingService;

  /// The associated session service, which is injected by the provider.
  late SessionService sessionService;

  /// The associated news service, which is injected by the provider.
  late NewsService newsService;

  @override
  void didChangeDependencies() {
    featureService = Provider.of<FeatureService>(context);
    settingsService = Provider.of<SettingsService>(context);
    predictionStatusService = Provider.of<PredictionStatusService>(context);
    shortcutsService = Provider.of<ShortcutsService>(context);
    positionService = Provider.of<PositionService>(context);
    routingService = Provider.of<RoutingService>(context);
    sessionService = Provider.of<SessionService>(context);
    newsService = Provider.of<NewsService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is executed when a backend is selected.
  Future<void> onSelectBackend(Backend backend) async {
    // Tell the settings service that we selected the new backend.
    await settingsService.selectBackend(backend);

    // Reset the associated services.
    await predictionStatusService.reset();
    await shortcutsService.reset();
    await routingService.reset();
    await sessionService.reset();
    await newsService.reset();

    Navigator.pop(context);
  }

  /// A callback that is executed when a sg labels mode is selected.
  Future<void> onSelectSGLabelsMode(SGLabelsMode mode) async {
    // Tell the settings service that we selected the new sg labels mode.
    await settingsService.selectSGLabelsMode(mode);

    Navigator.pop(context);
  }

  /// A callback that is executed when a positioning is selected.
  Future<void> onSelectPositioning(Positioning positioning) async {
    // Tell the settings service that we selected the new backend.
    await settingsService.selectPositioning(positioning);
    // Reset the position service since it depends on the positioning.
    await positionService.reset();

    Navigator.pop(context);
  }

  /// A callback that is executed when a rerouting is selected.
  Future<void> onSelectRerouting(Rerouting rerouting) async {
    // Tell the settings service that we selected the new rerouting.
    await settingsService.selectRerouting(rerouting);

    Navigator.pop(context);
  }

  /// A callback that is executed when a ride views preference is selected.
  Future<void> onSelectRidePreference(RidePreference ridePreference) async {
    // Tell the settings service that we selected the new ridePreference.
    await settingsService.selectRidePreference(ridePreference);

    Navigator.pop(context);
  }

  /// A callback that is executed when darkMode is changed
  Future<void> onChangeColorMode(ColorMode colorMode) async {
    // Tell the settings service that we selected the new colorModePreference.
    await settingsService.selectColorMode(colorMode);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 128),
              Row(children: [
                AppBackButton(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
                const HSpace(),
                SubHeader(text: "Einstellungen", context: context),
              ]),
              const SmallVSpace(),

              if (featureService.canEnableInternalFeatures) 
                const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
              if (featureService.canEnableInternalFeatures) 
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8), 
                  child: Content(text: "Interne Testfeatures", context: context),
                ),

              if (featureService.canEnableInternalFeatures)
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Interne Features", 
                  icon: settingsService.enableInternalFeatures ? Icons.check_box : Icons.check_box_outline_blank, 
                  callback: () => settingsService.setEnableInternalFeatures(!settingsService.enableInternalFeatures),
                )),

              if (settingsService.enableInternalFeatures) 
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Testort", 
                  subtitle: settingsService.backend.region, 
                  icon: Icons.expand_more, 
                  callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                    return SettingsSelection(
                      elements: Backend.values, 
                      selected: settingsService.backend,
                      title: (Backend e) => e.region, 
                      callback: onSelectBackend
                    );
                  }),
                )),
                
              if (settingsService.enableInternalFeatures) 
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Ortung", 
                  subtitle: settingsService.positioning.description, 
                  icon: Icons.expand_more, 
                  callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                    return SettingsSelection(
                      elements: Positioning.values, 
                      selected: settingsService.positioning, 
                      title: (Positioning e) => e.description,
                      callback: onSelectPositioning,
                    );
                  }),
                )),

              if (settingsService.enableInternalFeatures) 
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "SG-Info", 
                  subtitle: settingsService.sgLabelsMode.description, 
                  icon: Icons.expand_more, 
                  callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                    return SettingsSelection(
                      elements: SGLabelsMode.values, 
                      selected: settingsService.sgLabelsMode,
                      title: (SGLabelsMode e) => e.description, 
                      callback: onSelectSGLabelsMode,
                    );
                  }),
                )),

              if (settingsService.enableInternalFeatures)
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Tutorials zurücksetzen", 
                  icon: Icons.recycling, 
                  callback: () => Provider.of<TutorialService>(context, listen: false).deleteCompleted(),
                )),

              if (featureService.canEnableBetaFeatures) 
                const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
              if (featureService.canEnableBetaFeatures) 
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8), 
                  child: Content(text: "Beta Testfeatures", context: context),
                ),

              if (featureService.canEnableBetaFeatures)
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Beta Features", 
                  icon: settingsService.enableBetaFeatures ? Icons.check_box : Icons.check_box_outline_blank, 
                  callback: () => settingsService.setEnableBetaFeatures(!settingsService.enableBetaFeatures),
                )),

              if (settingsService.enableBetaFeatures)
                Padding(padding: const EdgeInsets.only(top: 8), child: SettingsElement(
                  title: "Routing", 
                  subtitle: settingsService.rerouting.description, 
                  icon: Icons.expand_more, 
                  callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                    return SettingsSelection(
                      elements: Rerouting.values, 
                      selected: settingsService.rerouting,
                      title: (Rerouting e) => e.description, 
                      callback: onSelectRerouting
                    );
                  }),
                )),

              if (settingsService.enableBetaFeatures)
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
                subtitle: settingsService.colorMode.description,
                icon: Icons.expand_more,
                callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                  return SettingsSelection(
                      elements: ColorMode.values,
                      selected: settingsService.colorMode,
                      title: (ColorMode e) => e.description,
                      callback: onChangeColorMode
                  );
                }),
                ),
              ),
              const SmallVSpace(),
              SettingsElement(
                title: "Fahrtansicht", 
                subtitle: settingsService.ridePreference?.description, 
                icon: Icons.expand_more, 
                callback: () => showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                  return SettingsSelection(
                    elements: RidePreference.values, 
                    selected: settingsService.ridePreference,
                    title: (RidePreference e) => e.description, 
                    callback: onSelectRidePreference
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
                  text: "PrioBike v${featureService.appVersion} ${featureService.gitHead}", 
                  color: Colors.grey,
                  context: context
                ),
              ),

              const SizedBox(height: 128),
            ],
          ),
        ),
      ]),
    ));
  }
}