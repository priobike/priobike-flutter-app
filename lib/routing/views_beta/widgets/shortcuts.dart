import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';

/// Displays the shortcut row.
class ShortCutsRow extends StatefulWidget {
  final Function onPressed;
  final bool close;

  const ShortCutsRow({Key? key, required this.onPressed, required this.close}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShortCutsRowState();
}

class ShortCutsRowState extends State<ShortCutsRow> {
  /// The associated shortcut service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated places service, which is injected by the provider.
  late Places places;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    shortcuts = getIt<Shortcuts>();
    shortcuts.addListener(update);
    places = getIt<Places>();
    places.addListener(update);
    routing = getIt<Routing>();
    routing.addListener(update);
  }

  @override
  void dispose() {
    shortcuts.removeListener(update);
    places.removeListener(update);
    routing.removeListener(update);
    super.dispose();
  }

  /// Widget that displays a shortcut row.
  Widget _shortcutItem(BuildContext context, String name, Function onPressed, bool isShortCut) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, bottom: 10, top: 10),
      child: Material(
        elevation: 5,
        borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        color: Theme.of(context).colorScheme.background,
        child: GestureDetector(
          onTap: () => onPressed(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              children: [
                Icon(isShortCut ? Icons.alt_route : Icons.home),
                const SizedBox(width: 5),
                Content(text: name, context: context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> shortCutItems = shortcuts.shortcuts != null
        ? shortcuts.shortcuts!.map((entry) {
            return _shortcutItem(context, entry.name, () async {
              widget.onPressed(entry.waypoints);
              if (widget.close) Navigator.of(context).pop();
            }, true);
          }).toList()
        : [];
    final List<Widget> placesItems = places.places != null
        ? places.places!.map((entry) {
            return _shortcutItem(context, entry.name, () async {
              widget.onPressed([entry.waypoint]);
              if (widget.close) Navigator.of(context).pop();
            }, false);
          }).toList()
        : [];
    return SizedBox(
      /// 32 + 2*10 padding
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [...placesItems, ...shortCutItems],
      ),
    );
  }
}
