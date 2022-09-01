import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/news/views/button.dart';

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

  /// Get a greeting for the current time of day.
  get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Guten Morgen";
    if (hour < 18) return "Guten Tag";
    return "Guten Abend";
  }

  @override 
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24), 
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [
            0.1,
            0.9,
          ],
          colors: [
            Color.fromARGB(255, 0, 198, 255),
            Color.fromARGB(255, 0, 115, 255)
          ],
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 64),
          Row(children: [
            Flexible(child: Content(text: "PrioBike", color: Colors.white), fit: FlexFit.tight),
            BoldContent(text: greeting, color: Colors.white),
          ]),
          const SmallVSpace(),
          const Divider(color: Color.fromARGB(50, 255, 255, 255), thickness: 2),
          const SmallVSpace(),
          Row(children: [
            const Icon(
              Icons.cloudy_snowing,
              size: 32,
              color: Colors.white
            ),
            const SmallHSpace(),
            Flexible(child: Small(text: "Wetterinformationen sind aktuell noch nicht verfügbar.", color: Colors.white)),
            const SmallHSpace(),
            NewsButton(onPressed: () { onTapNotificationButton?.call(); }),
            const SmallHSpace(),
            SmallIconButton(
              icon: Icons.settings, 
              color: Theme.of(context).colorScheme.background, 
              splash: Colors.white,
              fill: const Color.fromARGB(50, 255, 255, 255),
              onPressed: () { onTapSettingsButton?.call(); }
            ),
          ]),
          const VSpace(),
        ],
      ),
    );
  }
}