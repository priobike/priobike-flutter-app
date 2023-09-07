import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/challenges/views/challenges_card.dart';
import 'package:priobike/gamification/challenges/views/goal_setting.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
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
  /// The associated profile service.
  late GameProfileService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

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

  Widget get hasProfileHeader {
    var goals = _profileService.challengeGoals;
    var showGoals = _profileService.isFeatureEnabled(GameProfileService.gameFeatureChallengesKey) ||
        _profileService.isFeatureEnabled(GameProfileService.gameFeatureStatisticsKey);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showGoals) ...[
            BoldSubHeader(text: 'Tagesziel', context: context),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, right: 4),
                  child: Icon(Icons.directions_bike, size: 20),
                ),
                Content(
                  text: '${(goals.dailyDistanceGoalMetres / 1000).toStringAsFixed(1)} km',
                  context: context,
                ),
                const SmallHSpace(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, right: 4),
                  child: Icon(Icons.timer, size: 20),
                ),
                Content(
                  text: '${goals.dailyDurationGoalMinutes.toStringAsFixed(0)} min',
                  context: context,
                ),
              ],
            ),
            const SmallVSpace(),
          ],
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (showGoals)
                Expanded(
                  child: Tile(
                    padding: const EdgeInsets.all(8),
                    borderRadius: BorderRadius.circular(24),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ChallengeGoalSetting(),
                      ),
                    ),
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CustomGameIcons.goals, size: 24),
                        const SmallHSpace(),
                        BoldContent(text: 'Ziele ändern', context: context),
                      ],
                    ),
                  ),
                ),
              if (!showGoals) Expanded(child: Container()),
              const SmallHSpace(),
              Expanded(
                child: Tile(
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(24),
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.settings, size: 24),
                      const SmallHSpace(),
                      BoldContent(text: 'Einstellungen', context: context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  final Map<String, Widget> _featureCards = {
    GameProfileService.gameFeatureChallengesKey: const GameChallengesCard(),
    GameProfileService.gameFeatureStatisticsKey: const RideStatisticsCard(),
  };

  List<Widget> get _enabledFeatureCards =>
      _profileService.enabledFeatures.map((key) => _featureCards[key] as Widget).toList();

  List<Widget> get _disabledFeatureCards =>
      _profileService.disabledFeatures.map((key) => _featureCards[key] as Widget).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: (!_profileService.hasProfile)
          ? [
              noProfileHeader,
              const GameIntroCard(),
            ]
          : [
              hasProfileHeader,
              ..._enabledFeatureCards,
              ..._disabledFeatureCards,
            ],
    );
  }
}
