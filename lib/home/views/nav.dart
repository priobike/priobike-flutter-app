import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/news/views/button.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/weather/view.dart';

class NavBarView extends StatelessWidget {
  /// A callback that is fired when the settings button was pressed.
  final void Function()? onTapSettingsButton;

  /// A callback that is fired when the notification button was pressed.
  final void Function()? onTapNotificationButton;

  const NavBarView({this.onTapSettingsButton, this.onTapNotificationButton, super.key});

  @override
  Widget build(BuildContext context) {
    final settings = getIt<Settings>();
    return SliverAppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
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
                  Content(
                    text: settings.backend == Backend.staging ? " DD" : " HH",
                    color: Colors.white,
                    context: context,
                  ),
                  Flexible(
                    fit: FlexFit.tight,
                    child: Small(
                      text: settings.backend == Backend.production ? "  beta" : "",
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
                splash: Theme.of(context).colorScheme.surfaceTint,
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
