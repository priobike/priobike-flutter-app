import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';

class ShortcutsRow extends StatefulWidget {
  const ShortcutsRow({Key? key}) : super(key: key);

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
  _loadShortcutsRoute(List<Waypoint> waypoints) async {
    await routing.selectWaypoints(waypoints);
    await routing.loadRoutes();
  }

  Widget shortcutRouteItem(ShortcutRoute shortcut) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Tile(
        onPressed: () => _loadShortcutsRoute(shortcut.waypoints),
        fill: Theme.of(context).colorScheme.background,
        splash: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.white,
        shadowIntensity: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        borderRadius: BorderRadius.circular(12),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.route),
            const SmallHSpace(),
            Content(
              context: context,
              text: shortcut.name,
            ),
          ],
        ),
      ),
    );
  }

  /// Load route from shortcuts.
  _loadShortcutLocation(Waypoint waypoint) async {
    Positioning positioning = getIt<Positioning>();
    if (positioning.lastPosition != null) {
      await routing.selectWaypoints(
          [Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude), waypoint]);
      await routing.loadRoutes();
    }
  }

  Widget shortcutLocationItem(ShortcutLocation shortcut) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Tile(
        onPressed: () => _loadShortcutLocation(shortcut.waypoint),
        fill: Theme.of(context).colorScheme.background,
        splash: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.white,
        shadowIntensity: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        borderRadius: BorderRadius.circular(12),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.location_on),
            const SmallHSpace(),
            Content(
              context: context,
              text: shortcut.name,
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

    List<Widget> shortCutWidgets = shortcuts.shortcuts!
        .map((e) => e.runtimeType == ShortcutRoute
            ? shortcutRouteItem(e as ShortcutRoute)
            : shortcutLocationItem(e as ShortcutLocation))
        .toList();
    // Padding on the right side.
    shortCutWidgets.add(const SizedBox(width: 8));

    return SizedBox(
      width: frame.size.width,
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: shortCutWidgets,
      ),
    );
  }
}
