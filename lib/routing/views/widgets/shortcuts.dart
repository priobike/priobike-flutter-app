import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routingOLD context.
class ShortCutsRow extends StatefulWidget {
  const ShortCutsRow({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShortCutsRowState();
}

class ShortCutsRowState extends State<ShortCutsRow> {
  /// The associated shortcut service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    shortcuts = Provider.of<Shortcuts>(context);
    routing = Provider.of<Routing>(context);
  }

  Widget _shortcutItem(
      BuildContext context, String name, Function onPressed, bool isShortCut) {
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
                Icon(isShortCut ? Icons.alt_route : null),
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
    final List<Widget> shortCutItems = shortcuts.shortcuts!.map((entry) {
      return _shortcutItem(context, entry.name, () {
        routing.selectWaypoints(entry.waypoints);
        routing.loadRoutes(context);
      }, true);
    }).toList();
    return SizedBox(
      /// 32 + 2*10 padding
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: shortCutItems,
      ),
    );
  }
}
