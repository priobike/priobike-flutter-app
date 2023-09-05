import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/profile/services/profile_service.dart';
import 'package:priobike/gamification/hub/views/hub_page.dart';
import 'package:priobike/gamification/settings/views/feature_settings.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/views/main.dart';

/// In this view the user can modify the gamification settings available.
class GameSettingsView extends StatefulWidget {
  const GameSettingsView({Key? key}) : super(key: key);

  @override
  State<GameSettingsView> createState() => _GameSettingsViewState();
}

class _GameSettingsViewState extends State<GameSettingsView> with SingleTickerProviderStateMixin {
  /// Controller which controls the animation when opening this view.
  late AnimationController _animationController;

  /// Service which provides the view with the necessary user profile data.
  late GameProfileService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// Index of the setting selected by the user.
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
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(update);
    _animationController = AnimationController(vsync: this, duration: LongDuration());
    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    _animationController.dispose();
    super.dispose();
  }

  /// Open the view corresponding to a specific selected setting.
  void _openSettingsPage(Widget view, int index) {
    setState(() => selectedSetting = 0);
    _animationController.duration = ShortDuration();
    _animationController.reverse().then(
          (_) => Navigator.of(context)
              .push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 0),
              reverseTransitionDuration: const Duration(milliseconds: 0),
              pageBuilder: (context, animation, secondaryAnimation) => view,
            ),
          )
              .then(
            (_) {
              setState(() => selectedSetting = null);
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
          // Settings element to open a seperate view to enable or disable features.
          getAnimatedSettingsElement(
            index: 0,
            onTap: () => _openSettingsPage(const GameFeaturesSettingsView(), 0),
            title: 'Aktivierte Spiel-Elemente',
            icon: Icons.list,
          ),
          // Settings element to delete all challenge data.
          getAnimatedSettingsElement(
            index: 1,
            onTap: () => AppDatabase.instance.challengeDao.clearObjects(),
            title: 'Challenges zurücksetzen',
            icon: Icons.recycling,
          ),
        ],
      ),
    );
  }

  /// Returns a settings element that is wrapped in an animation for when the elements appear and disappear.
  Widget getAnimatedSettingsElement(
      {required int index, required Function() onTap, required String title, required IconData icon}) {
    if (selectedSetting == index) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SettingsElement(
            title: 'Aktivierte Spiel-Elemente',
            icon: Icons.list,
            callback: () {},
          ),
        ),
      );
    } else {
      return SlideTransition(
        position: getSettingsElementAnimation(0.2, 0.6),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SettingsElement(title: title, icon: icon, callback: onTap),
        ),
      );
    }
  }
}
