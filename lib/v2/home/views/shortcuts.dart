

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/colors.dart';
import 'package:priobike/v2/common/views/text.dart';
import 'package:priobike/v2/common/views/tiles.dart';

class ShortcutView extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool primary;
  final double width;
  final double rightPad;

  const ShortcutView({
    Key? key, 
    required this.icon, 
    required this.title, 
    this.primary = false, 
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
        content: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 64, color: primary ? Colors.white : Colors.black),
              Content(text: title, color: primary ? Colors.white : Colors.black, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
        fill: primary ? Colors.blueAccent : AppColors.lightGrey,
        splash: primary ? Colors.lightBlue : Colors.white,
      ),
    );
  }
}

class ShortcutsView extends StatelessWidget {
  const ShortcutsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24),
      scrollDirection: Axis.horizontal, 
      child: Row(children: [
        ShortcutView(
          icon: Icons.route, 
          title: "Routing starten", 
          width: shortcutWidth, 
          rightPad: shortcutRightPad,
          primary: true,
        ),
        ShortcutView(
          icon: Icons.home, 
          title: "Shortcut 1", 
          width: shortcutWidth, 
          rightPad: shortcutRightPad,
        ),
        ShortcutView(
          icon: Icons.home, 
          title: "Shortcut 2", 
          width: shortcutWidth, 
          rightPad: shortcutRightPad,
        ),
      ]),
    );
  }
}