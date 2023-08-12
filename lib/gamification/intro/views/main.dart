import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/views/main.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/info_page.dart';
import 'package:priobike/main.dart';

class GameIntro extends StatefulWidget {
  const GameIntro({Key? key}) : super(key: key);

  @override
  State<GameIntro> createState() => _GameIntroState();
}

class _GameIntroState extends State<GameIntro> {
  /// The associated intro service, which is injected by the provider.
  late GameIntroService introService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    introService = getIt<GameIntroService>();
    introService.addListener(update);
  }

  @override
  void dispose() {
    introService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!introService.loadedValues) return const SizedBox.shrink();
    if (introService.startedIntro) return const GamificationHubView();
    return const GameInfoPage();
  }
}
