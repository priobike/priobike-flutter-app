import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/settings/models/routing.dart';
import 'package:priobike/settings/models/sg_selector.dart';
import 'package:priobike/settings/views/main.dart';
import 'package:priobike/logging/views.dart';
import 'package:priobike/settings/models/rerouting.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class BetaSettingsView extends StatefulWidget {
  const BetaSettingsView({Key? key}) : super(key: key);

  @override
  BetaSettingsViewState createState() => BetaSettingsViewState();
}

class BetaSettingsViewState extends State<BetaSettingsView> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  @override
  void didChangeDependencies() {
    settings = Provider.of<Settings>(context);
    super.didChangeDependencies();
  }

  /// A callback that is executed when a routing endpoint is selected.
  Future<void> onSelectRoutingMode(RoutingEndpoint routingEndpoint) async {
    // Tell the settings service that we selected the new backend.
    await settings.setRoutingEndpoint(routingEndpoint);

    Navigator.pop(context);
  }

  /// A callback that is executed when a rerouting is selected.
  Future<void> onSelectRerouting(Rerouting rerouting) async {
    // Tell the settings service that we selected the new rerouting.
    await settings.setRerouting(rerouting);

    Navigator.pop(context);
  }

  /// A callback that is executed when a sg-selector is selected.
  Future<void> onSelectSGSelector(SGSelector sgSelector) async {
    // Tell the settings service that we selected the new sg-selector.
    await settings.setSGSelector(sgSelector);

    Navigator.pop(context);
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
                      callback: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogsView()))),
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
                const SmallVSpace(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
