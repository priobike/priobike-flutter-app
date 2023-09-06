import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/challenge_goals.dart';
import 'package:priobike/gamification/challenges/views/challenges_card.dart';
import 'package:priobike/gamification/challenges/views/goal_setting.dart';
import 'package:priobike/gamification/common/views/game_card.dart';
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
              UserGoalsCard(goals: _profileService.challengeGoals),
              const GameChallengesCard(),
              const RideStatisticsCard(),
            ],
    );
  }
}

class UserGoalsCard extends StatelessWidget {
  final UserGoals goals;

  const UserGoalsCard({Key? key, required this.goals}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GamificationCard(
      content: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.sports_score, size: 48),
              Column(
                children: [
                  BoldSubHeader(
                      text: '${(goals.dailyDistanceGoalMetres / 1000).toStringAsFixed(1)} km', context: context),
                  Small(text: 'Tägliche Distanz', context: context),
                ],
              ),
              Column(
                children: [
                  BoldSubHeader(text: '${goals.dailyDurationGoalMinutes.toStringAsFixed(0)} min', context: context),
                  Small(text: 'Tägliche Fahrzeit', context: context),
                ],
              ),
            ],
          ),
          const SmallVSpace(),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BoldSmall(text: 'Ändern', context: context),
              const SizedBox(width: 4),
              const Icon(Icons.redo, size: 16),
            ],
          ),
        ],
      ),
      directionView: const ChallengeGoalSetting(),
    );
  }
}
