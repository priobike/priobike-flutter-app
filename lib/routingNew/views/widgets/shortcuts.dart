import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routing context.
class ShortCuts extends StatefulWidget {
  const ShortCuts({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShortCutsState();
}

class ShortCutsState extends State<ShortCuts> {
  /// The associated routing service, which is injected by the provider.
  late Routing routingService;

  @override
  void didChangeDependencies() {
    routingService = Provider.of<Routing>(context);
    super.didChangeDependencies();
  }

  Widget _shortcutItem (BuildContext context, bool isFirst, String name, Function onPressed) {
    return Padding(
      padding: EdgeInsets.only(left: isFirst ? 10 : 5, right: 5, bottom: 10, top: 10),
      child: Material(
        elevation: 5,
        borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        color: Theme.of(context).colorScheme.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Center(
            child: Content(text: name, context: context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      /// 32 + 2*10 padding
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _shortcutItem(context, true, "Shortcut 1", () {}),
          _shortcutItem(context, false, "Shortcut 2", () {}),
          _shortcutItem(context, false, "Shortcut 3", () {}),
          _shortcutItem(context, false, "Shortcut 4", () {}),
          _shortcutItem(context, false, "Shortcut 5", () {}),
          _shortcutItem(context, false, "Shortcut 6", () {}),
        ],
      ),
    );
  }
}
