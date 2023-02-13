import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/news/views/button.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/weather/view.dart';
import 'package:provider/provider.dart';

class NavBarView extends StatelessWidget {
  /// A callback that is fired when the settings button was pressed.
  final void Function()? onTapSettingsButton;

  /// A callback that is fired when the notification button was pressed.
  final void Function()? onTapNotificationButton;

  const NavBarView({this.onTapSettingsButton, this.onTapNotificationButton, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context, listen: false);
    return SliverAppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
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
                  BoldContent(
                    text: "PrioBike",
                    color: Colors.white,
                    context: context,
                  ),
                  Flexible(
                    fit: FlexFit.tight,
                    child: Content(
                      text: settings.backend == Backend.production ? " HH" : " DD",
                      color: Colors.white,
                      context: context,
                    ),
                  ),
                  BoldContent(text: "Moin!", color: Colors.white, context: context),
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
              const WeatherView(),
              const SmallHSpace(),
              NewsButton(
                onPressed: () {
                  onTapNotificationButton?.call();
                },
              ),
              const SmallHSpace(),
              SmallIconButton(
                icon: Icons.settings_rounded,
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
