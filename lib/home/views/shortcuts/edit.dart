import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/shortcuts/import.dart';
import 'package:priobike/home/views/shortcuts/qr_code.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/routing/views_beta/main.dart';
import 'package:priobike/settings/models/routing_view.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';

/// Show a sheet to edit the current shortcuts name.
void showEditShortcutSheet(context, int idx) {
  final shortcuts = GetIt.instance.get<Shortcuts>();
  showDialog(
    context: context,
    builder: (_) {
      final nameController = TextEditingController();
      return AlertDialog(
        title: BoldContent(
          text: 'Bitte gib einen neuen Namen an, unter dem die Strecke gespeichert werden soll.',
          context: context,
        ),
        content: SizedBox(
          height: 78,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                maxLength: 20,
                decoration: const InputDecoration(hintText: 'Heimweg, Zur Arbeit, ...'),
              ),
            ],
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final name = nameController.text;
              if (name.trim().isEmpty) {
                ToastMessage.showError("Name darf nicht leer sein.");
                return;
              }
              await shortcuts.updateShortcutName(name, idx);
              ToastMessage.showSuccess("Routen Name gespeichert!");
              Navigator.pop(context);
            },
            child: BoldContent(
              text: 'Speichern',
              color: Theme.of(context).colorScheme.primary,
              context: context,
            ),
          ),
        ],
      );
    },
  );
}

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
  bool editMode = false;

  /// The associcated settings service, which is injected by the provider.
  late Settings settings;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    shortcuts = getIt<Shortcuts>();
    shortcuts.addListener(update);
    routing = getIt<Routing>();
    discomforts = getIt<Discomforts>();
    predictionSGStatus = getIt<PredictionSGStatus>();
    settings = getIt<Settings>();
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

  /// A callback that is executed when a shortcut should be edited.
  Future<void> onEditShortcut(int idx) async {
    if (shortcuts.shortcuts == null || shortcuts.shortcuts!.isEmpty || shortcuts.shortcuts!.length <= idx) return;

    showEditShortcutSheet(context, idx);
  }

  @override
  Widget build(BuildContext context) {
    if (shortcuts.shortcuts == null) return Container();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                    SmallIconButton(
                      onPressed: () => showAppSheet(
                        context: context,
                        builder: (context) => const ImportShortcutDialog(),
                      ),
                      icon: Icons.download_rounded,
                      fill: Theme.of(context).colorScheme.surface,
                    ),
                    const SmallHSpace(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: editMode
                          ? SmallIconButton(
                              icon: Icons.check_rounded,
                              onPressed: () => setState(() => editMode = false),
                              fill: Theme.of(context).colorScheme.primary,
                            )
                          : SmallIconButton(
                              icon: Icons.edit_rounded,
                              onPressed: () => setState(() => editMode = true),
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
                                topLeft: Radius.circular(24),
                                bottomLeft: Radius.circular(24),
                              ),
                              showShadow: false,
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
                                          text: "${entry.value.waypoints.length} Wegpunkte",
                                          context: context,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const HSpace(),
                                  Row(
                                    children: [
                                      const HSpace(),
                                      editMode
                                          ? SmallIconButton(
                                              icon: Icons.edit,
                                              onPressed: () => onEditShortcut(entry.key),
                                              fill: Theme.of(context).colorScheme.surface,
                                            )
                                          : SmallIconButton(
                                              icon: Icons.qr_code_2_rounded,
                                              onPressed: () => Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (BuildContext context) => QRCodeView(shortcut: entry.value),
                                                ),
                                              ),
                                              fill: Theme.of(context).colorScheme.background,
                                            ),
                                      const SmallHSpace(),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: editMode
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
                                ],
                              ),
                              onPressed: () {
                                routing.selectWaypoints(List.from(entry.value.waypoints));

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
