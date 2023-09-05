import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/views/challenges_card.dart';
import 'package:priobike/gamification/intro/intro_card.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/gamification/statistics/views/stats_card.dart';
import 'package:priobike/main.dart';

/// The game view is displayed when the user presses the game card on the home view. It either starts the game intro,
/// or opens the gamification hub, where the user can access all game elements.
class GameView extends StatefulWidget {
  const GameView({Key? key}) : super(key: key);

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  /// The associated intro service, which is injected by the provider.
  late GameProfileService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    // Add listener to game intro service, which manages the whole intro process.
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BoldContent(
                text: "Da geht doch noch mehr!",
                context: context,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Small(
                text: "Probiere neue Funktionen aus.",
                context: context,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (!_profileService.hasProfile) const GameIntroCard(),
        if (_profileService.hasProfile) ...[
          GameChallengesCard(
            openView: (view) => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => view),
            ),
          ),
          RideStatisticsCard(
            openView: (view) => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => view),
            ),
          ),
        ],
      ],
    );
  }
}
