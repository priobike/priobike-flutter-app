import 'package:flutter/material.dart';
import 'package:priobike/common/colors.dart';
import 'package:priobike/common/debug.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/views.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/session/services/session.dart';
import 'package:priobike/session/views/toast.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/service.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Debug these views.
void main() => debug(MultiProvider(
  providers: [
    ChangeNotifierProvider<SettingsService>(
      create: (context) => SettingsService(),
    ),
  ],
  child: const SettingsView(),
));

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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24), 
          bottomLeft: Radius.circular(24)
        ),
        fill: Colors.white,
        content: Row(children: [
          BoldContent(text: title),
          const HSpace(),
          if (subtitle != null) Flexible(child: Content(text: subtitle!, color: Colors.blue), fit: FlexFit.tight)
          else Flexible(child: Container()),
          SmallIconButton(icon: icon, onPressed: callback, color: Colors.black, fill: AppColors.lightGrey),
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
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: elements.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Tile(fill: AppColors.lightGrey, content: Row(children: [
              Flexible(child: Content(text: title(elements[index])), fit: FlexFit.tight),
              Expanded(child: Container()),
              SmallIconButton(
                icon: elements[index] == selected
                  ? Icons.check 
                  : Icons.check_box_outline_blank, 
                onPressed: () => callback(elements[index]),
              ),
            ]))
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
  /// The associated settings service, which is injected by the provider.
  late SettingsService settingsService;

  /// The associated shortcuts service, which is injected by the provider.
  late ShortcutsService shortcutsService;

  /// The associated shortcuts service, which is injected by the provider.
  late PositionService positionService;

  /// The associated routing service, which is injected by the provider.
  late RoutingService routingService;

  /// The associated session service, which is injected by the provider.
  late SessionService sessionService;

  @override
  void didChangeDependencies() {
    settingsService = Provider.of<SettingsService>(context);
    shortcutsService = Provider.of<ShortcutsService>(context);
    positionService = Provider.of<PositionService>(context);
    routingService = Provider.of<RoutingService>(context);
    sessionService = Provider.of<SessionService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is executed when a backend is selected.
  Future<void> onSelectBackend(Backend backend) async {
    // Tell the settings service that we selected the new backend.
    await settingsService.selectBackend(backend);

    // Reset the associated services.
    await shortcutsService.reset();
    await routingService.reset();
    await sessionService.reset();

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

  @override 
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(color: AppColors.lightGrey),
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 128),
            Row(children: [
              AppBackButton(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
              const HSpace(),
              SubHeader(text: "Einstellungen"),
            ]),
            const SmallVSpace(),
            const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
            const SmallVSpace(),
            Padding(
              padding: const EdgeInsets.only(left: 32), 
              child: Content(text: "Test-Features"),
            ),
            const VSpace(),
            SettingsElement(
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
            ),
            const SmallVSpace(),
            SettingsElement(
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
            ),
            const SmallVSpace(),
            SettingsElement(title: "Logs", icon: Icons.list, callback: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                return const Scaffold(body: LogsView());
              }));
            }),
            const SmallVSpace(),
            const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
            const SmallVSpace(),
            Padding(
              padding: const EdgeInsets.only(left: 32), 
              child: Content(text: "Nutzbarkeit"),
            ),
            const VSpace(),
            SettingsElement(title: "Problem melden", icon: Icons.thumb_down, callback: () => {
              ToastMessage.showError("Probleme können derzeit noch nicht gemeldet werden.")
            }),
            const SmallVSpace(),
            SettingsElement(title: "Feedback geben", icon: Icons.email, callback: () => {
              ToastMessage.showError("Feedback kann derzeit noch nicht gegeben werden.")
            }),
            const SmallVSpace(),
            const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
            const SmallVSpace(),
            Padding(
              padding: const EdgeInsets.only(left: 32), 
              child: Content(text: "Weitere Informationen"),
            ),
            const VSpace(),
            SettingsElement(title: "Datenschutz", icon: Icons.info, callback: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                return const Scaffold(body: PrivacyPolicyView());
              }));
            }),
            const SmallVSpace(),
            SettingsElement(title: "Lizenzen", icon: Icons.info, callback: () => {
              ToastMessage.showError("Lizenzen sind noch nicht verfügbar.")
            }),
            const SmallVSpace(),
            SettingsElement(title: "Danksagung", icon: Icons.info, callback: () => {
              ToastMessage.showError("Danksagungen sind noch nicht verfügbar.")
            }),
            const SmallVSpace(),
            const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
            const SmallVSpace(),
            FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (
                BuildContext context,
                AsyncSnapshot<PackageInfo> snapshot,
              ) {
                /**
                 * If you want to see the commit hash in the app run it with:
                 * 
                 * flutter run --dart-define=COMMIT_ID=$(git rev-parse --short HEAD~)
                 */

                String commitId = const String.fromEnvironment(
                  'COMMIT_ID',
                  defaultValue: 'Keine Commit ID',
                );

                return snapshot.hasData
                  ? Padding(
                      padding: const EdgeInsets.only(left: 32), 
                      child: Small(text: "PrioBike-App v${snapshot.data?.version ?? '?.?.?'} ($commitId)", color: Colors.grey),
                    )
                  : const Text('Lade Versionsnummer..');
              }),
            const SizedBox(height: 128),
          ],
        ),
      ),
    ]);
  }
}