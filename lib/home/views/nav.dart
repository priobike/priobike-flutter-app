import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/news/views/button.dart';

class NavBarView extends StatelessWidget {
  /// A callback that is fired when the settings button was pressed.
  final void Function()? onTapSettingsButton;

  /// A callback that is fired when the notification button was pressed.
  final void Function()? onTapNotificationButton;

  const NavBarView({this.onTapSettingsButton, this.onTapNotificationButton, Key? key}) : super(key: key);

  /// Get a greeting for the current time of day.
  get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Guten Morgen";
    if (hour < 18) return "Guten Tag";
    return "Guten Abend";
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      foregroundColor: CI.lightBlue,
      backgroundColor: CI.blue,
      pinned: true,
      snap: false,
      floating: false,
      shadowColor: const Color.fromARGB(26, 0, 37, 100),
      expandedHeight: 128,
      collapsedHeight: 73,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground],
        collapseMode: CollapseMode.parallax,
        expandedTitleScale: 1,
        titlePadding: const EdgeInsets.only(top: 24, bottom: 12),
        background: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 32,
            top: MediaQuery.of(context).padding.top + 14,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              stops: [
                0.1,
                0.9,
              ],
              colors: [CI.lightBlue, CI.blue],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                      child: BoldContent(
                        text: "PrioBike",
                        color: Colors.white,
                        context: context,
                      ),
                      fit: FlexFit.tight),
                  BoldContent(text: greeting, color: Colors.white, context: context),
                ],
              ),
              const SmallVSpace(),
              const Divider(color: Color.fromARGB(50, 255, 255, 255), thickness: 2),
            ],
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(Icons.cloudy_snowing, size: 32, color: Colors.white),
              const SmallHSpace(),
              Flexible(
                  child: Small(
                      text: "Wetterinformationen sind aktuell noch nicht verfügbar.",
                      color: Colors.white,
                      context: context)),
              const SmallHSpace(),
              NewsButton(
                onPressed: () {
                  onTapNotificationButton?.call();
                },
              ),
              const SmallHSpace(),
              SmallIconButton(
                icon: Icons.settings,
                color: Colors.white,
                splash: Colors.white,
                fill: const Color.fromARGB(50, 255, 255, 255),
                onPressed: () {
                  onTapSettingsButton?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
