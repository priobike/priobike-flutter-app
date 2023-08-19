import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/hub/services/profile_service.dart';
import 'package:priobike/gamification/hub/views/custom_hub_page.dart';
import 'package:priobike/gamification/settings/views/feature_settings.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/views/main.dart';

class GameSettingsView extends StatefulWidget {
  const GameSettingsView({Key? key}) : super(key: key);

  @override
  State<GameSettingsView> createState() => _GameSettingsViewState();
}

class _GameSettingsViewState extends State<GameSettingsView> with SingleTickerProviderStateMixin {
  /// Controller which controls the animation when opening this view.
  late AnimationController _animationController;

  late UserProfileService _profileService;

  void update() => setState(() {});

  int? selectedSetting;

  /// Animation for the confirmation button. The button slides in from the bottom.
  Animation<Offset> getSettingsElementAnimation(double start, double end) => Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(min(start, 1.0), min(end, 1.0), curve: Curves.easeIn),
      ));

  /// Simple fade animation for the header of the hub view.
  Animation<double> get _fadeAnimation => CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      );

  @override
  void initState() {
    _profileService = getIt<UserProfileService>();
    _profileService.addListener(update);
    _animationController = AnimationController(vsync: this, duration: LongDuration());
    _animationController.forward();
    super.initState();
  }

  void _openView(Widget view, int index) {
    setState(() {
      selectedSetting = 0;
    });
    _animationController.reverse().then(
          (_) => Navigator.of(context)
              .push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, animation, secondaryAnimation) => view,
            ),
          )
              .then(
            (_) {
              selectedSetting = null;
              _animationController.forward();
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return GameHubPage(
      animationController: _animationController,
      title: 'Einstellungen',
      content: Column(
        children: [
          for (int i = 0; i < 5; i++)
            (selectedSetting == i)
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SettingsElement(
                        title: 'Aktivierte Spiel-Elemente',
                        icon: Icons.list,
                        callback: () {},
                      ),
                    ),
                  )
                : SlideTransition(
                    position: getSettingsElementAnimation(0.2, 0.6),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SettingsElement(
                          title: 'Aktivierte Spiel-Elemente',
                          icon: Icons.list,
                          callback: () => _openView(const GameComponentsSettings(), 0)),
                    ),
                  ),
        ],
      ),
    );
  }
}
