

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/views/spacing.dart';
import 'package:priobike/v2/common/views/text.dart';
import 'package:priobike/v2/common/views/tiles.dart';

class ProfileElementButton extends StatelessWidget {
  final IconData icon;
  final String title;

  const ProfileElementButton({Key? key, required this.icon, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Tile(
      padding: const EdgeInsets.all(6), 
        content: Tile(
        padding: const EdgeInsets.all(6),
        content: Column(children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SmallVSpace(),
          Small(text: title, color: Colors.grey),
        ]),
      ), 
      fill: Colors.white
    ));
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HPad(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Tile(
        padding: const EdgeInsets.all(16),
        content: Row(children: const [
          ProfileElementButton(icon: Icons.electric_bike, title: "Radtyp"),
          SmallHSpace(),
          ProfileElementButton(icon: Icons.thumb_up, title: "Präferenz"),
          SmallHSpace(),
          ProfileElementButton(icon: Icons.sports_gymnastics, title: "Sportlichk."),
        ]),
      ),
    ]));
  }
}
