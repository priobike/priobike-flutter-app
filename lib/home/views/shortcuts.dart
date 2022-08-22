import 'package:flutter/material.dart';
import 'package:priobike/common/colors.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

class ShortcutView extends StatelessWidget {
  final bool isHighlighted;
  final bool isLoading;
  final void Function() onPressed;
  final IconData icon;
  final String title;
  final double width;
  final double rightPad;

  const ShortcutView({
    Key? key, 
    this.isHighlighted = false,
    this.isLoading = false,
    required this.onPressed,
    required this.icon, 
    required this.title, 
    required this.width, 
    required this.rightPad
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      constraints: BoxConstraints(minWidth: width, maxWidth: width),
      padding: EdgeInsets.only(right: rightPad),
      child: Tile(
        onPressed: onPressed,
        content: SizedBox(
          height: 128,
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isLoading ? [ 
                const Expanded(child: Center(child: CircularProgressIndicator())) 
              ] : [
                Icon(icon, size: 64, color: isHighlighted ? Colors.white : Colors.black),
                Expanded(child: Container()),
                Content(
                  text: title, 
                  color: isHighlighted ? Colors.white : Colors.black, 
                  maxLines: 3, 
                  overflow: TextOverflow.ellipsis
                ),
              ],
            )),
          ])
        ),
        fill: isHighlighted ? Colors.blue : AppColors.lightGrey,
        splash: isHighlighted ? Colors.white : Colors.black,
      ),
    );
  }
}

class ShortcutsView extends StatefulWidget {
  /// A callback that will be executed when the shortcut was selected.
  final void Function(Shortcut shortcut) onSelectShortcut;

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
  late ShortcutsService ss;

  /// The associated routing service, which is injected by the provider.
  late RoutingService rs;

  @override
  void didChangeDependencies() {
    ss = Provider.of<ShortcutsService>(context);
    rs = Provider.of<RoutingService>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (ss.shortcuts == null) return renderLoadingIndicator();
    return renderShortcuts(context, ss.shortcuts!);
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return HPad(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Tile(
        content: Center(child: SizedBox(
          height: 86, 
          width: 86, 
          child: Column(children: const [
            CircularProgressIndicator(),
          ])
        ))
      )
    ]));
  }

  Widget renderShortcuts(BuildContext context, List<Shortcut> shortcuts) {
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;

    var shortcutViews = shortcuts.map((shortcut) => ShortcutView(
      onPressed: () {
        // Allow only one shortcut to be fetched at a time.
        if (!rs.isFetchingRoute) widget.onSelectShortcut(shortcut);
      },
      isLoading: (rs.selectedWaypoints == shortcut.waypoints) && rs.isFetchingRoute,
      icon: Icons.route, 
      title: shortcut.name, 
      width: shortcutWidth, 
      rightPad: shortcutRightPad,
    )).toList(); 

    shortcutViews = [ShortcutView(
      onPressed: () {
        if (!rs.isFetchingRoute) widget.onStartFreeRouting();
      },
      isHighlighted: true,
      icon: Icons.play_circle,
      title: "Freies Routing starten", 
      width: shortcutWidth, 
      rightPad: shortcutRightPad,
    )] + shortcutViews;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24),
      scrollDirection: Axis.horizontal, 
      child: Row(children: shortcutViews),
    );
  }
}