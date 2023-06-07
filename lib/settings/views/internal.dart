import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/privacy/services.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/models/sg_labels.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/main.dart';
import 'package:priobike/tutorial/service.dart';

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

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);
    position = getIt<Positioning>();
    position.addListener(update);
  }

  @override
  void dispose() {
    settings.removeListener(update);
    position.removeListener(update);
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
                const SmallVSpace(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
