import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/shortcuts/import.dart';
import 'package:priobike/home/views/shortcuts/pictogram.dart';

import 'package:priobike/home/views/shortcuts/qr_code.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/shortcut_location.dart';

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
        actions: [
          TextField(
            autofocus: false,
            controller: nameController,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: "Heimweg, Zur Arbeit, ...",
              fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
              filled: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide.none,
              ),
              suffixIcon: SmallIconButtonTertiary(
                icon: Icons.close,
                onPressed: () {
                  nameController.text = "";
                },
                color: Theme.of(context).colorScheme.onBackground,
                fill: Colors.transparent,
                // splash: Colors.transparent,
                withBorder: false,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              counterStyle: TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
              ),
            ),
          ),
          BigButtonPrimary(
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
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          )
        ],
      );
    },
  );
}

/// The view that will be displayed in an app sheet.
class EditOptionsView extends StatelessWidget {
  /// The shortcut of the view.
  final Shortcut shortcut;

  /// The index of the shortcut.
  final int idx;

  /// The callback that will be executed when the delete button is pressed.
  final Function onDeleteShortcut;

  /// The callback that will be executed when the edit button is pressed.
  final Function onEditShortcut;

  /// The callback that will be executed when the share button is pressed.
  final Function onShareShortcut;

  const EditOptionsView({
    super.key,
    required this.shortcut,
    required this.idx,
    required this.onDeleteShortcut,
    required this.onEditShortcut,
    required this.onShareShortcut,
  });

  /// The callback that will be executed when the delete button is pressed.
  void onDelete(BuildContext context) {
    onDeleteShortcut(idx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Show a grid view with all available layers.
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SmallVSpace(),
              BoldSubHeader(text: shortcut.name, context: context),
              const VSpace(),
              BigButtonPrimary(
                label: "Teilen",
                boxConstraints: BoxConstraints(minHeight: 36, minWidth: MediaQuery.of(context).size.width - 40),
                onPressed: () => onShareShortcut(idx),
              ),
              const SmallVSpace(),
              BigButtonTertiary(
                label: "QR-Code",
                boxConstraints: BoxConstraints(minHeight: 36, minWidth: MediaQuery.of(context).size.width - 40),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => QRCodeView(shortcut: shortcut),
                  ),
                ),
              ),
              const SmallVSpace(),
              BigButtonTertiary(
                label: "Bearbeiten",
                boxConstraints: BoxConstraints(minHeight: 36, minWidth: MediaQuery.of(context).size.width - 40),
                onPressed: () => onEditShortcut(idx),
              ),
              const SmallVSpace(),
              BigButtonPrimary(
                fillColor: CI.radkulturYellow,
                textColor: Colors.black,
                label: "Löschen",
                boxConstraints: BoxConstraints(minHeight: 36, minWidth: MediaQuery.of(context).size.width - 40),
                onPressed: () => onDelete(context),
              ),
              const SmallVSpace(),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ShortcutsEditView extends StatefulWidget {
  const ShortcutsEditView({super.key});

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
    final Shortcut shortcut = shortcuts.shortcuts![idx];
    final Map<String, dynamic> shortcutJson = shortcut.toJson();
    final str = json.encode(shortcutJson);
    final bytes = utf8.encode(str);
    final base64Str = base64.encode(bytes);
    const scheme = 'https';
    const host = 'priobike.vkw.tu-dresden.de';
    const route = 'import';
    String shortcutTypeText = '';
    shortcut.type == "ShortcutLocation" ? shortcutTypeText = 'meinen Ort' : shortcutTypeText = 'meine Route';
    final text = 'Probiere $shortcutTypeText in der PrioBike-App aus:';
    final shareLink = '$scheme://$host/$route/$base64Str';
    const getAppText = 'Falls Du die PrioBike App noch nicht hast, kannst Du sie dir hier holen:';
    const playStoreLink = 'https://play.google.com/apps/testing/de.tudresden.priobike';
    const appStoreLink = 'https://testflight.apple.com/join/GXdqWpdn';
    String subject = '';
    shortcut.type == "ShortcutLocation" ? subject = 'Ort teilen' : subject = 'Route teilen';
    await Share.share('$text \n $shareLink \n $getAppText \n $playStoreLink \n $appStoreLink', subject: subject);
  }

  /// A callback that is executed when the more button is pressed.
  onMorePressed(Shortcut shortcut, int idx) {
    showAppSheet(
      context: context,
      builder: (BuildContext context) => EditOptionsView(
        idx: idx,
        shortcut: shortcut,
        onDeleteShortcut: onDeleteShortcut,
        onEditShortcut: onEditShortcut,
        onShareShortcut: onShareShortcut,
      ),
    );
  }

  /// Widget that displays a shortcut.
  Widget shortcutListItem(Shortcut shortcut, int key) {
    return Container(
      key: Key("$key"),
      padding: const EdgeInsets.only(left: 8),
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
              ),
            ),
          ),
          Tile(
            padding: const EdgeInsets.all(0),
            showShadow: false,
            borderWidth: 0,
            borderColor: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.all(
              Radius.circular(0),
            ),
            content: Container(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    // button height as width because of square pictogram (2x48 + small vertical space).
                    width: 96,
                    height: 96,
                    child: Stack(
                      children: [
                        if (shortcut is ShortcutRoute)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                              border:
                                  Border.all(width: 2, color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1)),
                              color: Theme.of(context).colorScheme.surfaceVariant,
                            ),
                            child: ShortcutPictogram(
                              key: ValueKey(shortcut.hashCode),
                              shortcut: shortcut,
                              // Fixed height of pictogram.
                              height: 96,
                              color: CI.radkulturRed,
                              strokeWidth: 4,
                            ),
                          )
                        else if (shortcut is ShortcutLocation)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(width: 2, color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1)),
                              color: Theme.of(context).colorScheme.surfaceVariant,
                            ),
                            child: ShortcutPictogram(
                              key: ValueKey(shortcut.hashCode),
                              shortcut: shortcut,
                              // Fixed height of pictogram.
                              height: 96,
                              color: CI.radkulturRed,
                              iconSize: 24,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Space between middle content and map.
                  const SmallHSpace(),
                  Expanded(
                    child: SizedBox(
                      // height of pictogram.
                      height: 112,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                            // Padding to align with location icon.
                            padding: const EdgeInsets.only(left: 4),
                            child: BoldContent(
                              text: shortcut.name,
                              context: context,
                            ),
                          ),
                          if (shortcut is ShortcutLocation)
                            Padding(
                              // Padding to align with location icon.
                              padding: const EdgeInsets.only(left: 4),
                              child: Small(
                                text: shortcut.getShortInfo(),
                                overflow: TextOverflow.ellipsis,
                                context: context,
                                color: Theme.of(context).colorScheme.tertiary,
                                maxLines: 4,
                              ),
                            ),
                          if (shortcut is ShortcutRoute) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  // To align with route name.
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                // The space of the location icon + the padding of the waypoint item to align the texts vertically.
                                const SizedBox(
                                  width: 6,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 2),
                                    child: Small(
                                      text: shortcut.getFirstAddress() ?? "",
                                      overflow: TextOverflow.ellipsis,
                                      context: context,
                                      color: Theme.of(context).colorScheme.tertiary,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).colorScheme.background,
                                      ),
                                    ),
                                  ),
                                ),
                                // The space of the location icon to align the texts vertically.
                                const SizedBox(
                                  width: 4,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 0),
                                    child: Small(
                                      text: shortcut.getLastAddress() ?? "",
                                      overflow: TextOverflow.ellipsis,
                                      context: context,
                                      color: Theme.of(context).colorScheme.tertiary,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          if (shortcut is ShortcutRoute)
                            Row(
                              children: [
                                const SizedBox(
                                  width: 4,
                                ),
                                Icon(
                                  Icons.access_time,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  size: 14,
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 0),
                                  child: Small(text: shortcut.routeTimeText ?? "-", context: context),
                                ),
                                const HSpace(),
                                Icon(
                                  Icons.route,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  size: 14,
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 0),
                                  child: Small(text: shortcut.routeLengthText ?? "-", context: context),
                                ),
                              ],
                            ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SmallHSpace(),
                  SmallIconButtonTertiary(
                    icon: Icons.more_vert,
                    onPressed: () => onMorePressed(shortcut, key),
                  ),
                  const SmallHSpace(),
                ],
              ),
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
    return AnnotatedRegionWrapper(
      backgroundColor: Theme.of(context).colorScheme.background,
      brightness: Theme.of(context).brightness,
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
                    SmallIconButtonPrimary(
                      onPressed: () => showAppSheet(
                        context: context,
                        builder: (context) => const ImportShortcutDialog(),
                      ),
                      icon: Icons.add_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                      fill: Theme.of(context).colorScheme.surface,
                      splash: Theme.of(context).colorScheme.surfaceTint,
                    ),
                    const SmallHSpace(),
                  ],
                ),
                const VSpace(),
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
                const VSpace(),
                const HPad(
                  child: Center(
                    child: Text(
                      'Drücke lange auf ein Element und ziehe es nach oben oder unten, um die Reihenfolge zu ändern.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
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
