import 'dart:ui';

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
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/link_shortener.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/shortcuts/import.dart';
import 'package:priobike/home/views/shortcuts/pictogram.dart';
import 'package:priobike/home/views/shortcuts/qr_code.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/poi.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:share_plus/share_plus.dart';

/// Show a sheet to edit the current shortcuts name.
void showEditShortcutSheet(context, int idx) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.4),
    transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
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
              fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                color: Theme.of(context).colorScheme.onSurface,
                fill: Colors.transparent,
                // splash: Colors.transparent,
                withBorder: false,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              counterStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          BigButtonPrimary(
            label: "Speichern",
            onPressed: () async {
              final name = nameController.text;
              if (name.trim().isEmpty) {
                getIt<Toast>().showError("Name darf nicht leer sein.");
                return;
              }
              await getIt<Shortcuts>().updateShortcutName(name, idx);
              getIt<Toast>().showSuccess("Name gespeichert!");
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
class EditOptionsView extends StatefulWidget {
  /// The shortcut of the view.
  final Shortcut shortcut;

  /// The index of the shortcut.
  final int idx;

  const EditOptionsView({
    super.key,
    required this.shortcut,
    required this.idx,
  });

  @override
  EditOptionsViewState createState() => EditOptionsViewState();
}

class EditOptionsViewState extends State<EditOptionsView> {
  /// The shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  @override
  void initState() {
    super.initState();
    shortcuts = getIt<Shortcuts>();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        // Complete share tutorial if this site was visited by the user.
        getIt<Tutorial>().complete("priobike.tutorial.share-shortcut");
      },
    );
  }

  /// The callback that will be executed when the delete button is pressed.
  void onDelete(BuildContext context) {
    onDeleteShortcut(widget.idx);
    Navigator.pop(context);
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
    String shortcutTypeText = '';
    shortcut.type == "ShortcutLocation" ? shortcutTypeText = 'meinen Ort' : shortcutTypeText = 'meine Route';
    final text = 'Probiere $shortcutTypeText in der PrioBike-App aus:';
    String longLink = shortcut.getLongLink();
    String? shortLink = await LinkShortener.createShortLink(longLink);
    if (shortLink == null) return;
    const getAppText = 'Falls Du die PrioBike App noch nicht hast, kannst Du sie Dir hier holen:';
    const playStoreLink = 'https://play.google.com/store/apps/details?id=de.tudresden.priobike&hl=de';
    const appStoreLink = 'https://apps.apple.com/de/app/priobike/id1634224594';
    String subject = '';
    shortcut.type == "ShortcutLocation" ? subject = 'Ort teilen' : subject = 'Route teilen';
    await Share.share('$text \n$shortLink \n$getAppText \n$playStoreLink \n$appStoreLink', subject: subject);
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
              BoldSubHeader(text: widget.shortcut.name, context: context),
              const VSpace(),
              BigButtonPrimary(
                label: "Teilen",
                boxConstraints: BoxConstraints(minHeight: 36, minWidth: MediaQuery.of(context).size.width - 40),
                onPressed: () => onShareShortcut(widget.idx),
              ),
              const SmallVSpace(),
              BigButtonTertiary(
                label: "QR-Code",
                boxConstraints: BoxConstraints(minHeight: 36, minWidth: MediaQuery.of(context).size.width - 40),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => QRCodeView(shortcut: widget.shortcut),
                  ),
                ),
              ),
              const SmallVSpace(),
              BigButtonTertiary(
                label: "Bearbeiten",
                boxConstraints: BoxConstraints(minHeight: 36, minWidth: MediaQuery.of(context).size.width - 40),
                onPressed: () => onEditShortcut(widget.idx),
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

  /// The associated pois service, which is injected by the provider.
  late Pois pois;

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
    pois = getIt<Pois>();
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

  /// A callback that is executed when the more button is pressed.
  onMorePressed(Shortcut shortcut, int idx) {
    showAppSheet(
      context: context,
      builder: (BuildContext context) => EditOptionsView(
        idx: idx,
        shortcut: shortcut,
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
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          Theme.of(context).colorScheme.surface.withOpacity(0.8),
                          Theme.of(context).colorScheme.surface.withOpacity(0.7),
                        ]
                      : [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.6),
                          Theme.of(context).colorScheme.surface.withOpacity(0.5),
                          Theme.of(context).colorScheme.surface.withOpacity(0.3),
                        ],
                ),
              ),
            ),
          ),
          Tile(
            padding: const EdgeInsets.only(left: 8),
            showShadow: false,
            borderWidth: 0,
            borderColor: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(0),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BoldContent(
                            text: shortcut.name,
                            color: Theme.of(context).colorScheme.onSurface,
                            context: context,
                          ),
                          const SizedBox(height: 4),
                          Small(
                            text: shortcut is ShortcutLocation
                                ? "Ort"
                                : "Route von ${shortcut.getWaypoints().first.address?.split(",").firstOrNull} nach ${shortcut.getWaypoints().last.address?.split(",").firstOrNull}",
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            context: context,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SmallIconButtonTertiary(
                        icon: Icons.more_horiz_rounded,
                        onPressed: () => onMorePressed(shortcut, key),
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        withBorder: false,
                      ),
                    ),
                  ],
                ),
                const SmallVSpace(),
                Row(
                  children: [
                    if (shortcut is ShortcutRoute)
                      ClipRRect(
                        child: ShortcutPictogram(
                          key: ValueKey(shortcut.hashCode),
                          shortcut: shortcut,
                          height: MediaQuery.of(context).size.width * 0.5,
                          color: CI.radkulturRed,
                          strokeWidth: 4,
                          borderRadius: 8,
                        ),
                      )
                    else if (shortcut is ShortcutLocation)
                      ShortcutPictogram(
                        key: ValueKey(shortcut.hashCode),
                        shortcut: shortcut,
                        height: MediaQuery.of(context).size.width * 0.5,
                        color: CI.radkulturRed,
                        iconSize: 42,
                        borderRadius: 8,
                      ),
                    const SizedBox(width: 14),
                    if (shortcut is ShortcutRoute)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BoldContent(text: shortcut.routeTimeText ?? "-", context: context),
                          const SizedBox(height: 4),
                          Content(
                            text: "Fahrtdauer",
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            context: context,
                          ),
                          const SmallVSpace(),
                          BoldContent(text: shortcut.routeLengthText ?? "-", context: context),
                          const SizedBox(height: 4),
                          Content(
                            text: "Distanz",
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            context: context,
                          ),
                          const SmallVSpace(),
                          BoldContent(text: "${shortcut.waypoints.length}", context: context),
                          const SizedBox(height: 4),
                          Content(
                            text: "Wegpunkte",
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            context: context,
                          ),
                        ],
                      ),
                    if (shortcut is ShortcutLocation)
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BoldContent(
                              text: shortcut.waypoint.address ?? "-",
                              context: context,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Content(
                              text: "Adresse",
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              context: context,
                            ),
                          ],
                        ),
                      ),
                    const HSpace(),
                  ],
                ),
                const SmallVSpace(),
                Divider(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  thickness: 0.5,
                ),
                const SmallVSpace(),
              ],
            ),
            onPressed: () async {
              HapticFeedback.mediumImpact();

              final shortcutIsValid = shortcut.isValid();

              if (!shortcutIsValid) {
                showInvalidShortcutSheet(context);
                return;
              }

              routing.selectWaypoints(shortcut.getWaypoints());

              // Pushes the routing view.
              // Also handles the reset of services if the user navigates back to the home view after the routing view instead of starting a ride.
              // If the routing view is popped after the user navigates to the ride view do not reset the services, because they are being used in the ride view.
              if (context.mounted) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutingView())).then(
                  (comingNotFromRoutingView) {
                    if (comingNotFromRoutingView == null) {
                      routing.reset();
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
      bottomBackgroundColor: Theme.of(context).colorScheme.surface,
      colorMode: Theme.of(context).brightness,
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
