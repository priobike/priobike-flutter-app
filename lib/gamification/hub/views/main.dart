import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/views/hub_view.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/info_page.dart';
import 'package:priobike/gamification/intro/views/prefs_page.dart';
import 'package:priobike/gamification/intro/views/username_page.dart';
import 'package:priobike/main.dart';

class GameView extends StatefulWidget {
  const GameView({Key? key}) : super(key: key);

  @override
  State<GameView> createState() => _GameViewState();
}

/// The game view is displayed when the user presses the game card on the home view. It either starts the game intro,
/// or opens the gamification hub, where the user can access all game elements.
class _GameViewState extends State<GameView> with SingleTickerProviderStateMixin {
  /// The associated intro service, which is injected by the provider.
  late GameIntroService introService;

  /// Controlls the animated transitions between the intro pages.
  late final AnimationController _animationController;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    // If the current page to be displayed changed, animate the old page away.
    if (introService.pageChanged) {
      introService.pageChanged = false;
      _animationController.reverse().then((value) => setState(() {}));
      return;
    }
    setState(() {});
  }

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    // Add listener to game intro service, which manages the whole intro process.
    introService = getIt<GameIntroService>();
    introService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    introService.removeListener(update);
    super.dispose();
  }

  /// Handles when the android back button is pressed.
  Future<bool> _onWillPop() async {
    // Close view, if the relevant intro values haven't been loaded yet, or if the intro was already finished.
    if (!introService.loadedValues || introService.tutoralFinished) return true;

    // If the user is still in the process of the tutorial, navigate to the previous page.
    if (introService.prefsSet) {
      introService.setPrefsSet(false);
      return false;
    }
    if (introService.startedIntro) {
      introService.setStartedIntro(false);
      return false;
    }

    return true;
  }

  /// Returns the content which should be displayed.
  Widget _getContent() {
    // Show empty page, until the shared preferences have been loaded in the intro service.
    if (!introService.loadedValues) return const SizedBox.shrink();

    // Open the gamification hub, if the intro has been finished by the user.
    if (introService.tutoralFinished) return const GamificationHubView();

    // Open the username page, if the user already did everything else of the intro.
    if (introService.prefsSet) return GameUsernamePage(controller: _animationController);

    // Open the preference page, if the user already did everything else of the intro.
    if (introService.startedIntro) return GamePrefsPage(controller: _animationController);

    // If the user hasn't done any part of the intro, open the info page.
    return GameInfoPage(controller: _animationController);
  }

  @override
  Widget build(BuildContext context) {
    _animationController.forward();
    return WillPopScope(
      onWillPop: _onWillPop,
      child: _getContent(),
    );
  }
}
