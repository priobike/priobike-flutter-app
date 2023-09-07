import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/views/challenges_card.dart';
import 'package:priobike/gamification/goals/views/goals_view.dart';
import 'package:priobike/gamification/intro/intro_card.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/gamification/statistics/views/overall_stats.dart';
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
  /// The associated profile service.
  late GameProfileService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  final Map<String, Widget> _featureCards = {
    GameProfileService.gameFeatureChallengesKey: const GameChallengesCard(),
    GameProfileService.gameFeatureStatisticsKey: const RideStatisticsCard(),
  };

  List<Widget> get _enabledFeatureCards =>
      _profileService.enabledFeatures.map((key) => _featureCards[key] as Widget).toList();

  List<Widget> get _disabledFeatureCards =>
      _profileService.disabledFeatures.map((key) => _featureCards[key] as Widget).toList();

  @override
  void initState() {
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    super.dispose();
  }

  Widget get noProfileHeader => Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 24),
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
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: (!_profileService.hasProfile)
          ? [
              noProfileHeader,
              const GameIntroCard(),
            ]
          : [
              OverallStatistics(),
              if (_profileService.showGoals) const GoalsView(),
              const SmallVSpace(),
              ..._enabledFeatureCards,
              ..._disabledFeatureCards,
            ],
    );
  }
}
