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
    _controller.reverse().then((value) => setState(() {}));
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
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
    _controller.forward();

    return GamePrefsPage(() => Navigator.pop(context), controller: _controller);

    // Show empty page, until the shared preferences have been loaded.
    if (!introService.loadedValues) return const SizedBox.shrink();

    /// If the intro has been started, show the gamification hub.
    if (introService.startedIntro) return const GamificationHubView();

    /// Otherwise, show the first page of the intro.
    return GameInfoPage(controller: _controller);
  }
}
