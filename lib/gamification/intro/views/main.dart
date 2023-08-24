import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/hub/views/main.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/info_page.dart';
import 'package:priobike/gamification/intro/views/features_page.dart';
import 'package:priobike/gamification/intro/views/username_page.dart';
import 'package:priobike/main.dart';

/// The game view is displayed when the user presses the game card on the home view. It either starts the game intro,
/// or opens the gamification hub, where the user can access all game elements.
class GameView extends StatefulWidget {
  const GameView({Key? key}) : super(key: key);

  @override
  State<GameView> createState() => _GameViewState();
}

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

    /// Called when a listener callback of a ChangeNotifier is fired.
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    _animationController = AnimationController(
      duration: ShortAnimationDuration(),
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
    // If the service is loading currently, do nothing.
    if (introService.loading) return false;

    // Close view, if the relevant intro values haven't been loaded yet, or if the intro was already finished.
    if (!introService.loadedValues || introService.introFinished) return true;

    // If the user is still in the process of the tutorial, navigate to the previous page.
    if (introService.confirmedFeaturePage) {
      introService.setConfirmedFeaturePage(false);
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
    if (introService.introFinished) return const GameHubView();

    // Open the username page, if the user already did everything else of the intro.
    if (introService.confirmedFeaturePage) return GameUsernamePage(animationController: _animationController);

    // Open the feature selection page, if the user already did everything else of the intro.
    if (introService.startedIntro) return GameFeaturesPage(animationController: _animationController);

    // If the user hasn't done any part of the intro, open the info page.
    return GameInfoPage(animationController: _animationController);
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
