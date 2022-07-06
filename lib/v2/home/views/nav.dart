
import 'package:flutter/material.dart';
import 'package:priobike/v2/common/views/buttons.dart';
import 'package:priobike/v2/common/views/spacing.dart';
import 'package:priobike/v2/common/views/text.dart';

class NavBarView extends StatelessWidget {
  const NavBarView({Key? key}) : super(key: key);

  @override 
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
      Row(children: [
        const Icon(
          Icons.cloudy_snowing,
          size: 32,
          color: Colors.grey
        ),
        const SmallHSpace(),
        Flexible(child: Small(text: "Wetterinformationen sind aktuell noch nicht verfügbar.", color: Colors.grey)),
        const SmallHSpace(),
        SmallIconButton(icon: Icons.notifications, onPressed: () {}),
        const SmallHSpace(),
        SmallIconButton(icon: Icons.settings, onPressed: () {}),
      ]),
      const SmallVSpace(),
    ]));
  }
}