import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:provider/provider.dart';

class RoutesView extends StatefulWidget {
  const RoutesView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutesViewState();
}

class RoutesViewState extends State<RoutesView> {
  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    shortcuts = Provider.of<Shortcuts>(context);

    super.didChangeDependencies();
  }

  /// A callback that is executed when a shortcut should be deleted.
  Future<void> onDeleteShortcut(Shortcut shortcut) async {
    if (shortcuts.shortcuts == null || shortcuts.shortcuts!.isEmpty) return;

    final newShortcuts = shortcuts.shortcuts!.toList();
    newShortcuts.remove(shortcut);

    shortcuts.updateShortcuts(newShortcuts, context);
  }

  /// The widget that displays a waypoint.
  Widget _waypointItem(Waypoint waypoint) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Content(
          context: context,
          text: waypoint.address ?? "Keine Addresse vorhanden",
          color: Colors.grey,
        ),
      ),
    );
  }

  /// The widget between items.
  Widget _itemDivider() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(Icons.more_vert, color: Colors.grey),
      ),
    );
  }

  /// The widget that displays a shortcut row.
  Widget _shortcutRowItem(Shortcut shortcut) {
    List<Widget> waypoints = shortcut.waypoints.map((entry) => _waypointItem(entry)).toList();

    for (int i = 1; i < waypoints.length; i += 2) {
      waypoints.insert(i, _itemDivider());
    }

    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 20, bottom: 20, right: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: BoldSubHeader(
                  text: shortcut.name,
                  context: context,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 5),
              SmallIconButton(
                icon: Icons.delete,
                onPressed: () {
                  onDeleteShortcut(shortcut);
                },
              ),
            ],
          ),
          const SizedBox(height: 5),
          ...waypoints
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    List<Widget> shortcutsList = [];
    if (shortcuts.shortcuts != null) {
      shortcutsList = shortcuts.shortcuts!.map((entry) => _shortcutRowItem(entry)).toList();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Hero(
                    tag: 'appBackButton',
                    child: AppBackButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: Center(
                        child: BoldSubHeader(
                          text: "Meine Routen",
                          context: context,
                        ),
                      ),
                    ),
                  ),

                  /// To center the text
                  const SizedBox(width: 80),
                ]),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: shortcutsList,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
