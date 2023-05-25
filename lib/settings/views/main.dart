import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/licenses/views.dart';
import 'package:priobike/main.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/models/tracking.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/beta.dart';
import 'package:priobike/settings/views/internal.dart';
import 'package:priobike/settings/views/text.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/user.dart';

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
              fit: FlexFit.tight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BoldContent(text: title, context: context),
                  if (subtitle != null) const SmallVSpace(),
                  if (subtitle != null) Content(text: subtitle!, color: CI.blue, context: context),
                ],
              ),
            ),
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
                    fit: FlexFit.tight,
                    child: Content(
                      text: title(elements[index]),
                      context: context,
                      color: elements[index] == selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
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

  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  /// The generated user id.
  String userId = "";

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    feature = getIt<Feature>();
    feature.addListener(update);
    settings = getIt<Settings>();
    settings.addListener(update);
    tracking = getIt<Tracking>();
    tracking.addListener(update);

    getUserId();
  }

  @override
  void dispose() {
    feature.removeListener(update);
    settings.removeListener(update);
    tracking.removeListener(update);
    super.dispose();
  }

  /// Get the user id.
  Future<void> getUserId() async {
    userId = await User.getOrCreateId();
    setState(() {});
  }

  /// A callback that is executed when darkMode is changed
  Future<void> onChangeColorMode(ColorMode colorMode) async {
    // Tell the settings service that we selected the new colorModePreference.
    await settings.setColorMode(colorMode);

    if (mounted) Navigator.pop(context);
  }

  /// A callback that is executed when a speed mode is selected.
  Future<void> onSelectSpeedMode(SpeedMode speedMode) async {
    // Tell the settings service that we selected the new speed mode.
    await settings.setSpeedMode(speedMode);

    if (mounted) Navigator.pop(context);
  }

  /// A callback that is executed when a tracking submission policy is selected.
  Future<void> onSelectTrackingSubmissionPolicy(TrackingSubmissionPolicy trackingSubmissionPolicy) async {
    // Tell the settings service that we selected the new tracking submission policy.
    await settings.setTrackingSubmissionPolicy(trackingSubmissionPolicy);
    // Tell the tracking service that we selected the new tracking submission policy.
    tracking.setSubmissionPolicy(trackingSubmissionPolicy);

    if (mounted) Navigator.pop(context);
  }

  /// A callback that is executed when the save battery mode is changed.
  Future<void> onChangeSaveBatteryMode(bool saveBatteryModeEnabled) async {
    // Tell the settings service that we selected the new save battery mode.
    await settings.setSaveBatteryModeEnabled(saveBatteryModeEnabled);

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
                    SubHeader(text: "Einstellungen", context: context),
                  ],
                ),
                const SmallVSpace(),
                Container(
                  margin: const EdgeInsets.only(left: 18, top: 12, bottom: 8, right: 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Content(text: "Version: ", context: context),
                      Flexible(
                        child: BoldContent(
                          text: feature.gitHead.replaceAll("ref: refs/heads/", ""),
                          context: context,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Content(text: ", App-ID: ", context: context),
                      Content(text: userId, context: context),
                    ],
                  ),
                ),
                if (feature.canEnableInternalFeatures) ...[
                  const SmallVSpace(),
                  SettingsElement(
                    title: "Interne Features",
                    icon: Icons.code,
                    callback: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InternalSettingsView()),
                      );
                    },
                  ),
                ],
                if (feature.canEnableBetaFeatures) ...[
                  const SmallVSpace(),
                  SettingsElement(
                    title: "Beta Features",
                    icon: Icons.quiz,
                    callback: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BetaSettingsView()),
                      );
                    },
                  ),
                ],
                const VSpace(),
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
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SettingsElement(
                      title: "Telemetriedaten",
                      subtitle: tracking.uploadingTracks.isEmpty
                          ? settings.trackingSubmissionPolicy.description
                          : "Lädt hoch...",
                      icon: Icons.expand_more,
                      callback: () {
                        // Don't allow to change the submission policy while tracks are uploading.
                        if (tracking.uploadingTracks.isNotEmpty) return;
                        showAppSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SettingsSelection(
                                elements: TrackingSubmissionPolicy.values,
                                selected: settings.trackingSubmissionPolicy,
                                title: (TrackingSubmissionPolicy e) => e.description,
                                callback: onSelectTrackingSubmissionPolicy);
                          },
                        );
                      }),
                ),
                const SmallVSpace(),
                SettingsElement(
                  title: "Akkuverbrauch reduzieren",
                  icon: settings.saveBatteryModeEnabled ? Icons.check_box : Icons.check_box_outline_blank,
                  callback: () => settings.setSaveBatteryModeEnabled(!settings.saveBatteryModeEnabled),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8, right: 24),
                  child: Small(
                    text:
                        "Hinweis: Wenn aktiviert, wird die Qualität der Kartendarstellung während der Fahrt reduziert.",
                    context: context,
                  ),
                ),
                const VSpace(),
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
                const VSpace(),
                const SizedBox(height: 128),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
