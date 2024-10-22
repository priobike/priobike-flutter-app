import 'dart:io';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/shortcuts/edit.dart';
import 'package:priobike/home/views/shortcuts/pictogram.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';

class ShortcutView extends StatelessWidget {
  final Shortcut? shortcut;

  /// What text to show when no shortcut is available.
  final String? alternativeText;

  /// What icon to show when no shortcut is available.
  final IconData? alternativeIcon;

  final void Function() onPressed;
  final void Function()? onLongPressed;
  final double width;
  final double height;
  final double rightPad;
  final bool selected;
  final bool showSplash;
  final Color selectionColor;

  const ShortcutView({
    super.key,
    this.shortcut,
    this.alternativeText,
    this.alternativeIcon,
    required this.onPressed,
    required this.width,
    required this.height,
    required this.rightPad,
    this.onLongPressed,
    this.selected = false,
    this.showSplash = true,
    this.selectionColor = CI.radkulturRed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(right: rightPad, bottom: 24),
      child: Tile(
        onLongPressed: onLongPressed,
        onPressed: onPressed,
        shadow: shortcut == null ? CI.radkulturRed : const Color.fromARGB(255, 45, 45, 45),
        shadowIntensity: shortcut == null ? 0.3 : 0.1,
        padding: const EdgeInsets.all(0),
        content: Stack(
          children: [
            if (shortcut == null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(alternativeIcon ?? Icons.error, size: 64, color: Colors.white),
              )
            else if (shortcut is ShortcutRoute)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                margin: const EdgeInsets.all(4),
                child: ShortcutPictogram(
                  key: ValueKey(shortcut!.hashCode),
                  shortcut: shortcut as ShortcutRoute,
                  height: height - 4,
                  color: CI.radkulturRed,
                ),
              )
            else if (shortcut is ShortcutLocation)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                margin: const EdgeInsets.all(4),
                child: ShortcutPictogram(
                  key: ValueKey(shortcut!.hashCode),
                  shortcut: shortcut as ShortcutLocation,
                  height: height - 4,
                  color: CI.radkulturRed,
                ),
              ),
            SizedBox(
              height: height,
              width: width,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8, right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Container()),
                    FittedBox(
                      // Scale the text to fit the width.
                      fit: BoxFit.fitWidth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color:
                              shortcut == null ? null : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.75),
                        ),
                        child: shortcut == null
                            ? Text(
                                alternativeText ?? 'Missing alternative text',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Padding(
                                padding: EdgeInsets.only(top: Platform.isAndroid ? 2 : 0),
                                child: Text(
                                  shortcut!.name,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).brightness == Brightness.light
                                          ? Colors.black
                                          : Colors.white),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        fill: shortcut == null || selected ? selectionColor : Theme.of(context).colorScheme.surfaceVariant,
        splash: showSplash ? Theme.of(context).colorScheme.surfaceTint : Colors.transparent,
      ),
    );
  }
}

class ShortcutsView extends StatefulWidget {
  /// A callback that will be executed when the shortcut was selected.
  final Future<void> Function(Shortcut shortcut) onSelectShortcut;

  /// A callback that will be executed when free routing is started.
  final void Function() onStartFreeRouting;

  const ShortcutsView({
    required this.onSelectShortcut,
    required this.onStartFreeRouting,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => ShortcutsViewState();
}

class ShortcutsViewState extends State<ShortcutsView> {
  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The left padding.
  double leftPad = 25;

  /// If the user has scrolled.
  bool hasScrolled = false;

  /// The scroll controller.
  late ScrollController scrollController;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(
      () {
        if (scrollController.offset > 0) {
          hasScrolled = true;
        }
      },
    );
    shortcuts = getIt<Shortcuts>();
    routing = getIt<Routing>();
    shortcuts.addListener(update);
    routing.addListener(update);
  }

  @override
  void dispose() {
    shortcuts.removeListener(update);
    routing.removeListener(update);
    super.dispose();
  }

  /// Trigger the animation of the status view.
  Future<void> triggerAnimations() async {
    // Add some delay before we start the animation.
    await Future.delayed(const Duration(milliseconds: 5000));
    if (!hasScrolled) setState(() => leftPad = 24);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!hasScrolled) setState(() => leftPad = 22);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!hasScrolled) setState(() => leftPad = 24);
  }

  @override
  Widget build(BuildContext context) {
    const double shortcutRightPad = 15;
    final shortcutWidth = ((MediaQuery.of(context).size.width - 40) / 2) - shortcutRightPad;
    final shortcutHeight = shortcutWidth; // Must be square for the pictograms to work.

    List<Widget> views = [
      AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.only(left: leftPad),
      ),
      ShortcutView(
        alternativeText: 'Route planen',
        alternativeIcon: Icons.map_rounded,
        onPressed: widget.onStartFreeRouting,
        width: shortcutWidth,
        height: shortcutHeight,
        rightPad: shortcutRightPad,
      ),
    ];

    for (int i = 0; i < (shortcuts.shortcuts?.length ?? 0); i++) {
      final shortcut = shortcuts.shortcuts![i];
      views.add(
        ShortcutView(
          onPressed: () async {
            // Allow only one shortcut to be fetched at a time.
            if (!routing.isFetchingRoute) {
              await widget.onSelectShortcut(shortcut);
            }
          },
          onLongPressed: () async {
            showAppSheet(
              context: context,
              builder: (BuildContext context) => EditOptionsView(
                idx: i,
                shortcut: shortcut,
              ),
            );
          },
          shortcut: shortcut,
          width: shortcutWidth,
          height: shortcutHeight,
          rightPad: shortcutRightPad,
        ),
      );
    }

    List<Widget> animatedViews = views
        .asMap()
        .entries
        .map(
          (e) => BlendIn(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            delay: Duration(milliseconds: 250 /* Time until shortcuts are shown */ + 250 * e.key),
            child: e.value,
          ),
        )
        .toList();

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(children: animatedViews),
    );
  }
}
