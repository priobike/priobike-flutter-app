import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/views/custom_hub_page.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
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

  late GameSettingsService statService;

  void update() => setState(() {});

  @override
  void initState() {
    statService = getIt<GameSettingsService>();
    statService.addListener(update);
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _animationController.forward();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GameHubPage(
      animationController: _animationController,
      title: 'Einstellungen',
      backButtonCallback: () {
        _animationController.duration = const Duration(milliseconds: 500);
        _animationController.reverse().then((value) => Navigator.pop(context));
      },
      content: Column(
        children: [
          SettingsElement(
            title: 'Aktivierte Spiel-Elemente',
            icon: Icons.list,
            callback: () {},
          ),
        ],
      ),
    );
  }
}
