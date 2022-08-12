

import 'package:flutter/material.dart';
import 'package:priobike/common/colors.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:provider/provider.dart';

class ShortcutView extends StatelessWidget {
  final void Function() onPressed;
  final IconData icon;
  final String title;
  final double width;
  final double rightPad;

  const ShortcutView({
    Key? key, 
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
              children: [
                Icon(icon, size: 64, color: Colors.black),
                Expanded(child: Container()),
                Content(text: title, color: Colors.black, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            )),
          ])
        ),
        fill: AppColors.lightGrey,
        splash: Colors.white,
      ),
    );
  }
}

class ShortcutsView extends StatefulWidget {
  /// A callback that will be executed when the shortcut was selected.
  final void Function(Shortcut shortcut) onSelectShortcut;

  const ShortcutsView({required this.onSelectShortcut, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShortcutsViewState();
}


class ShortcutsViewState extends State<ShortcutsView> {
  /// The associated shortcuts service, which is injected by the provider.
  late ShortcutsService s;

  @override
  void didChangeDependencies() {
    s = Provider.of<ShortcutsService>(context);

    // Load once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      s.loadShortcuts();
    });

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (s.shortcuts == null) return renderLoadingIndicator();
    return renderShortcuts(context, s.shortcuts!);
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24),
      scrollDirection: Axis.horizontal, 
      child: Row(children: shortcuts.map((shortcut) => ShortcutView(
        onPressed: () => widget.onSelectShortcut(shortcut),
        icon: shortcut.icon, 
        title: shortcut.name, 
        width: shortcutWidth, 
        rightPad: shortcutRightPad,
      )).toList()),
    );
  }
}