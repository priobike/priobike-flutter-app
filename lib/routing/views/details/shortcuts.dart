import 'dart:io';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/routing.dart';

class ShortcutsRow extends StatefulWidget {
  /// The associated MapFunctions service, which is injected by the provider.
  final MapFunctions mapFunctions;

  const ShortcutsRow({super.key, required this.mapFunctions});

  @override
  ShortcutsState createState() => ShortcutsState();
}

class ShortcutsState extends State<ShortcutsRow> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    routing = getIt<Routing>();
    routing.addListener(update);
    shortcuts = getIt<Shortcuts>();
    shortcuts.addListener(update);
  }

  @override
  void dispose() {
    routing.removeListener(update);
    shortcuts.removeListener(update);
    super.dispose();
  }

  /// Load route from shortcuts.
  _loadShortcutsRoute(Shortcut shortcut) async {
    routing.selectWaypoints(shortcut.getWaypoints());
    widget.mapFunctions.reset();
    await routing.loadRoutes();
  }

  Widget shortcutItem(Shortcut shortcut) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Tile(
        onPressed: routing.isFetchingRoute ? null : () => _loadShortcutsRoute(shortcut),
        fill: Theme.of(context).colorScheme.surfaceContainer,
        splash: Theme.of(context).colorScheme.surfaceTint,
        shadowIntensity: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        borderRadius: BorderRadius.circular(12),
        borderColor: Theme.of(context).brightness == Brightness.light
            ? null
            : Theme.of(context).colorScheme.onPrimary.withOpacity(0.35),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            shortcut.getIcon(),
            const SmallHSpace(),
            Padding(
              padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 0),
              child: Content(
                context: context,
                text: shortcut.name,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    if (shortcuts.shortcuts == null) return Container();

    return SizedBox(
      width: frame.size.width,
      height: 40,
      child: ListView(
          scrollDirection: Axis.horizontal,
          children: shortcuts.shortcuts!.map((e) => shortcutItem(e)).toList() +
              [
                const SmallHSpace(),
              ]),
    );
  }
}
