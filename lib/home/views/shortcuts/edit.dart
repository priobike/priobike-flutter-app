import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/routing/views_beta/main.dart';
import 'package:priobike/settings/models/routing_view.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';

class ShortcutsEditView extends StatefulWidget {
  const ShortcutsEditView({Key? key}) : super(key: key);

  @override
  ShortcutsEditViewState createState() => ShortcutsEditViewState();
}

class ShortcutsEditViewState extends State<ShortcutsEditView> {
  late Shortcuts shortcuts;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated discomforts service, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated predictionSGStatus service, which is injected by the provider.
  late PredictionSGStatus predictionSGStatus;

  /// If the view is in the state to delete a shortcut.
  bool deleteMode = false;

  /// The associcated settings service, which is injected by the provider.
  late Settings settings;

  /// he singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  void updateServices() {
    routing = getIt.get<Routing>();
    discomforts = getIt.get<Discomforts>();
    predictionSGStatus = getIt.get<PredictionSGStatus>();
    settings = getIt.get<Settings>();
  }

  @override
  void initState() {
    super.initState();
    update = () {
      updateServices();
      setState(() {});
    };
    shortcuts = getIt.get<Shortcuts>();
    shortcuts.addListener(update);
    updateServices();
  }

  @override
  void dispose() {
    shortcuts.removeListener(update);
    super.dispose();
  }

  /// A callback that is executed when the order of the shortcuts change.
  Future<void> onChangeShortcutOrder(int oldIndex, int newIndex) async {
    if (shortcuts.shortcuts == null || shortcuts.shortcuts!.isEmpty) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reorderedShortcuts = shortcuts.shortcuts!.toList();
    final shortcut = reorderedShortcuts.removeAt(oldIndex);
    reorderedShortcuts.insert(newIndex, shortcut);

    shortcuts.updateShortcuts(reorderedShortcuts);
  }

  /// A callback that is executed when a shortcut should be deleted.
  Future<void> onDeleteShortcut(int idx) async {
    if (shortcuts.shortcuts == null || shortcuts.shortcuts!.isEmpty) return;

    final newShortcuts = shortcuts.shortcuts!.toList();
    newShortcuts.removeAt(idx);

    shortcuts.updateShortcuts(newShortcuts);
  }

  @override
  Widget build(BuildContext context) {
    if (shortcuts.shortcuts == null) return Container();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppBackButton(onPressed: () => Navigator.pop(context)),
                    const HSpace(),
                    SubHeader(text: "Strecken", context: context),
                    Expanded(child: Container()),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: deleteMode
                          ? SmallIconButton(
                              icon: Icons.check_rounded,
                              onPressed: () => setState(() => deleteMode = false),
                              fill: Theme.of(context).colorScheme.primary,
                            )
                          : SmallIconButton(
                              icon: Icons.edit_rounded,
                              onPressed: () => setState(() => deleteMode = true),
                              fill: Theme.of(context).colorScheme.surface,
                            ),
                    ),
                    const SizedBox(width: 18),
                  ],
                ),
                ReorderableListView(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  proxyDecorator: (proxyWidget, idx, anim) {
                    return proxyWidget;
                  },
                  onReorder: onChangeShortcutOrder,
                  children: shortcuts.shortcuts!.asMap().entries.map<Widget>(
                    (entry) {
                      return Container(
                        key: Key("$entry.key"),
                        padding: const EdgeInsets.only(left: 8, top: 8),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                foregroundDecoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                    colors: Theme.of(context).colorScheme.brightness == Brightness.dark
                                        ? [
                                            Theme.of(context).colorScheme.background,
                                            Theme.of(context).colorScheme.background,
                                            Theme.of(context).colorScheme.background.withOpacity(0.9),
                                            Theme.of(context).colorScheme.background.withOpacity(0.8),
                                            Theme.of(context).colorScheme.background.withOpacity(0.7),
                                          ]
                                        : [
                                            Theme.of(context).colorScheme.background,
                                            Theme.of(context).colorScheme.background,
                                            Theme.of(context).colorScheme.background.withOpacity(0.6),
                                            Theme.of(context).colorScheme.background.withOpacity(0.5),
                                            Theme.of(context).colorScheme.background.withOpacity(0.3),
                                          ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    bottomLeft: Radius.circular(24),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    bottomLeft: Radius.circular(24),
                                  ),
                                  child: Image(
                                    image: Theme.of(context).colorScheme.brightness == Brightness.dark
                                        ? const AssetImage('assets/images/map-dark.png')
                                        : const AssetImage('assets/images/map-light.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Tile(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
                              content: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        BoldContent(
                                          text: entry.value.name,
                                          context: context,
                                        ),
                                        const SmallVSpace(),
                                        BoldSmall(
                                          text: "${entry.value.waypoints.length} Stationen",
                                          context: context,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const HSpace(),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: deleteMode
                                        ? SmallIconButton(
                                            icon: Icons.delete,
                                            onPressed: () => onDeleteShortcut(entry.key),
                                            fill: Theme.of(context).colorScheme.surface,
                                          )
                                        : const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Icon(Icons.list_rounded),
                                          ),
                                  ),
                                ],
                              ),
                              onPressed: () {
                                routing.selectWaypoints(entry.value.waypoints);

                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (_) => settings.routingView == RoutingViewOption.stable
                                            ? const RoutingView()
                                            : const RoutingViewNew()))
                                    .then(
                                  (_) {
                                    routing.reset();
                                    discomforts.reset();
                                    predictionSGStatus.reset();
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                ),
                const SizedBox(height: 128),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
