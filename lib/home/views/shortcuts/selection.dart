import 'dart:math';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';

class ShortcutView extends StatelessWidget {
  final Shortcut? shortcut;
  final void Function() onPressed;
  final double width;
  final double height;
  final double rightPad;

  const ShortcutView({
    Key? key,
    this.shortcut,
    required this.onPressed,
    required this.width,
    required this.height,
    required this.rightPad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      constraints: BoxConstraints(minWidth: width, maxWidth: width),
      padding: EdgeInsets.only(right: rightPad, bottom: 24),
      child: Tile(
        onPressed: onPressed,
        shadow: shortcut == null ? CI.blue : const Color.fromARGB(255, 0, 0, 0),
        shadowIntensity: shortcut == null ? 0.3 : 0.08,
        padding: const EdgeInsets.all(4),
        content: Stack(children: [
          if (shortcut != null)
            Positioned.fill(
              child: Container(
                foregroundDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
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
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Image(
                    image: Theme.of(context).colorScheme.brightness == Brightness.dark
                        ? const AssetImage('assets/images/map-dark.png')
                        : const AssetImage('assets/images/map-light.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  shortcut == null
                      ? const Icon(Icons.map_rounded, size: 64, color: Colors.white)
                      : shortcut!.getRepresentation(),
                  Expanded(child: Container()),
                  FittedBox(
                    // Scale the text to fit the width.
                    fit: BoxFit.fitWidth,
                    child: Content(
                      text: shortcut == null ? 'Neue Route' : shortcut!.linebreakedName,
                      color: shortcut == null
                          ? Colors.white
                          : Theme.of(context).colorScheme.brightness == Brightness.dark
                              ? Colors.grey
                              : Colors.black,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      context: context,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
        fill: shortcut == null ? CI.blue : Theme.of(context).colorScheme.background,
        splash: shortcut == null ? Colors.white : Theme.of(context).colorScheme.primary,
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
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShortcutsViewState();
}

class ShortcutsViewState extends State<ShortcutsView> {
  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The left padding.
  double leftPad = 24;

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
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;
    final shortcutHeight = max(shortcutWidth - (shortcutRightPad * 3), 128.0);

    List<Widget> views = [
      AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.only(left: leftPad),
      ),
      ShortcutView(
        onPressed: () {
          if (!routing.isFetchingRoute) widget.onStartFreeRouting();
        },
        width: shortcutWidth,
        height: shortcutHeight,
        rightPad: shortcutRightPad,
      ),
    ];

    views += shortcuts.shortcuts
            ?.map(
              (shortcut) => ShortcutView(
                onPressed: () async {
                  // Allow only one shortcut to be fetched at a time.
                  if (!routing.isFetchingRoute) {
                    await widget.onSelectShortcut(shortcut);
                  }
                },
                shortcut: shortcut,
                width: shortcutWidth,
                height: shortcutHeight,
                rightPad: shortcutRightPad,
              ),
            )
            .toList() ??
        [];

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
