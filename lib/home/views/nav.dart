import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';

class NavBarView extends StatelessWidget {
  /// A callback that is fired when the settings button was pressed.
  final void Function()? onTapSettingsButton;

  /// A callback that is fired when the notification button was pressed.
  final void Function()? onTapNotificationButton;

  const NavBarView({
    this.onTapSettingsButton, 
    this.onTapNotificationButton, 
    Key? key
  }) : super(key: key);

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
        SmallIconButton(icon: Icons.notifications, color: Colors.grey, onPressed: () { onTapNotificationButton?.call(); }),
        const SmallHSpace(),
        SmallIconButton(icon: Icons.settings, onPressed: () { onTapSettingsButton?.call(); }),
      ]),
      const SmallVSpace(),
    ]));
  }
}