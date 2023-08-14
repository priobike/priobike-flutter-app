import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/views/main.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/info_page.dart';
import 'package:priobike/gamification/intro/views/prefs_page.dart';
import 'package:priobike/main.dart';

class GameIntro extends StatefulWidget {
  const GameIntro({Key? key}) : super(key: key);

  @override
  State<GameIntro> createState() => _GameIntroState();
}

/// This view is displayed when the user first presses the game card from the home view. It provides the user with
/// information about the gamification features and gives them the option to participate.
class _GameIntroState extends State<GameIntro> with SingleTickerProviderStateMixin {
  /// The associated intro service, which is injected by the provider.
  late GameIntroService introService;

  late final AnimationController _controller;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    if (introService.pageChanged) {
      introService.pageChanged = false;
      _controller.reverse().then((value) => setState(() {}));
      return;
    }
    setState(() {});
  }

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    introService = getIt<GameIntroService>();
    introService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    introService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();

    // Show empty page, until the shared preferences have been loaded.
    //if (!introService.loadedValues) return const SizedBox.shrink();

    if (!introService.startedIntro) return GameInfoPage(controller: _controller);

    if (!introService.prefsSet) return GamePrefsPage(controller: _controller);

    /// If the intro has been started, show the gamification hub.
    return const GamificationHubView();
  }
}
