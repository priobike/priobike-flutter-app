

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/colors.dart';
import 'package:priobike/v2/common/layout/spacing.dart';
import 'package:priobike/v2/common/layout/text.dart';
import 'package:priobike/v2/common/layout/tiles.dart';
import 'package:priobike/v2/home/models/shortcut.dart';

class ShortcutView extends StatelessWidget {
  final IconData icon;
  final String title;
  final double width;
  final double rightPad;

  const ShortcutView({
    Key? key, 
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
        onPressed: () {},
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

class ShortcutsView extends StatelessWidget {
  const ShortcutsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Shortcut>>(
      future: Shortcut.loadAll(),
      builder: (BuildContext context, AsyncSnapshot<List<Shortcut>> snapshot) {
        if (!snapshot.hasData) {
          // Still loading
          return renderLoadingIndicator();
        }
        var profile = snapshot.data!;
        return renderShortcuts(context, profile);
      },
    );
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
        icon: shortcut.icon, 
        title: shortcut.name, 
        width: shortcutWidth, 
        rightPad: shortcutRightPad,
      )).toList()),
    );
  }
}