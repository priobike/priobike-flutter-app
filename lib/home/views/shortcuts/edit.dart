import 'dart:convert';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/shortcuts/import.dart';
import 'package:priobike/home/views/shortcuts/qr_code.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:share_plus/share_plus.dart';

/// Show a sheet to edit the current shortcuts name.
void showEditShortcutSheet(context, int idx) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.4),
    pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      final nameController = TextEditingController();
      return DialogLayout(
        title: 'Aktualisieren',
        text: "Bitte gib einen neuen Namen ein.",
        icon: Icons.update_rounded,
        iconColor: Theme.of(context).colorScheme.primary,
        actions: [
          TextField(
            autofocus: false,
            controller: nameController,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: "Heimweg, Zur Arbeit, ...",
              fillColor: Theme.of(context).colorScheme.surface,
              filled: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide.none,
              ),
              suffixIcon: const Icon(Icons.bookmark),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          BigButton(
            iconColor: Colors.white,
            icon: Icons.save_rounded,
            label: "Speichern",
            onPressed: () async {
              final name = nameController.text;
              if (name.trim().isEmpty) {
                ToastMessage.showError("Name darf nicht leer sein.");
                return;
              }
              await getIt<Shortcuts>().updateShortcutName(name, idx);
              ToastMessage.showSuccess("Name gespeichert!");
              Navigator.pop(context);
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          )
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

  /// A callback that is executed when a shortcut should be shared.
  Future<void> onShareShortcut(int idx) async {
    if (shortcuts.shortcuts == null || shortcuts.shortcuts!.isEmpty || shortcuts.shortcuts!.length <= idx) return;
    final Shortcut shortcut = shortcuts.shortcuts!.toList()[idx];
    final Map<String, dynamic> shortcutJson = shortcut.toJson();
    final str = json.encode(shortcutJson);
    final bytes = utf8.encode(str);
    final base64Str = base64.encode(bytes);
    const scheme = 'https';
    const host = 'priobike.inf.tu-dresden.de';
    const route = 'import';
    String shortcutTypeText = '';
    shortcut.type == "ShortcutLocation" ? shortcutTypeText = 'meinen Ort' : shortcutTypeText = 'meine Route';
    final text = 'Probiere $shortcutTypeText in der PrioBike-App aus:';
    final shareLink = '$scheme://$host/$route/$base64Str';
    const getAppText = 'Falls du die Priobike App noch nicht hast, kannst du sie die hier holen:';
    const playStoreLink = 'https://play.google.com/apps/testing/de.tudresden.priobike';
    const appStoreLink = 'https://testflight.apple.com/join/GXdqWpdn';
    await Share.share('$text \n $shareLink \n $getAppText \n $playStoreLink \n $appStoreLink', subject: 'shared shortcut');
  }

  /// Widget that displays a shortcut.
  Widget shortcutListItem(Shortcut shortcut, int key) {
    return Container(
      key: Key("$key"),
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
              child: const ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
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
                        text: shortcut.name,
                        context: context,
                      ),
                      const SmallVSpace(),
                      BoldSmall(
                        text: shortcut.getShortInfo(),
                        overflow: TextOverflow.ellipsis,
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
                    !editMode
                        ? SmallIconButton(
                            icon: Icons.share_rounded,
                            onPressed: () => onShareShortcut(key),
                            fill: Theme.of(context).colorScheme.background,
                          )
                        : Container(),
                    const SmallHSpace(),
                    editMode
                        ? SmallIconButton(
                            icon: Icons.edit,
                            onPressed: () => onEditShortcut(key),
                            fill: Theme.of(context).colorScheme.surface,
                          )
                        : SmallIconButton(
                            icon: Icons.qr_code_2_rounded,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) => QRCodeView(shortcut: shortcut),
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
                              onPressed: () => onDeleteShortcut(key),
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
            onPressed: () async {
              HapticFeedback.mediumImpact();

              final shortcutIsValid = shortcut.isValid();

              if (!shortcutIsValid) {
                showInvalidShortcutSheet(context);
                return;
              }

              routing.selectShortcut(shortcut);

              // Pushes the routing view.
              // Also handles the reset of services if the user navigates back to the home view after the routing view instead of starting a ride.
              // If the routing view is popped after the user navigates to the ride view do not reset the services, because they are being used in the ride view.
              if (context.mounted) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutingView())).then(
                  (comingNotFromRoutingView) {
                    if (comingNotFromRoutingView == null) {
                      routing.reset();
                      discomforts.reset();
                      predictionSGStatus.reset();
                    }
                  },
                );
              }
            },
          ),
        ],
      ),
    );
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
                    SubHeader(text: "Strecken & Orte", context: context),
                    Expanded(child: Container()),
                    SmallIconButton(
                      onPressed: () => showAppSheet(
                        context: context,
                        builder: (context) => const ImportShortcutDialog(),
                      ),
                      icon: Icons.add_rounded,
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
                  children: shortcuts.shortcuts!
                      .asMap()
                      .entries
                      .map<Widget>((entry) => shortcutListItem(entry.value, entry.key))
                      .toList(),
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
