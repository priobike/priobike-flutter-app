import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
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

  /// Simple fade animation for the header of the hub view.
  Animation<double> get _fadeAnimation => CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      );

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SmallVSpace(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  AppBackButton(
                    onPressed: () {
                      _animationController.duration = const Duration(milliseconds: 500);
                      _animationController.reverse().then((value) => Navigator.pop(context));
                    },
                  ),
                  const HSpace(),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SubHeader(
                        text: "Einstellungen",
                        context: context,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 64, height: 0)
                ],
              ),
              const SmallVSpace(),
              SettingsElement(
                title: 'Aktivierte Spiel-Elemente',
                icon: Icons.list,
                callback: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
