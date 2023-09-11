import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/views/challenges_card.dart';
import 'package:priobike/gamification/goals/views/goals_view.dart';
import 'package:priobike/gamification/intro/intro_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/statistics/views/overall_stats.dart';
import 'package:priobike/gamification/statistics/views/stats_card.dart';
import 'package:priobike/main.dart';

/// This view contains the gamification functionality.
class GameView extends StatefulWidget {
  const GameView({Key? key}) : super(key: key);

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  /// This service provides user information.
  late GamificationUserService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// The gamification features mapped to their corresponding cards.
  final Map<String, Widget> _featureCards = {
    GamificationUserService.challengesFeatureKey: const GameChallengesCard(),
    GamificationUserService.statisticsFeatureKey: const RideStatisticsCard(),
  };

  /// List of feature cards for enabled features.
  List<Widget> get _enabledFeatureCards =>
      _profileService.enabledFeatures.map((key) => _featureCards[key] as Widget).toList();

  /// List of feature cards for disabled features.
  List<Widget> get _disabledFeatureCards =>
      _profileService.disabledFeatures.map((key) => _featureCards[key] as Widget).toList();

  /// Whether to give the user the option to set goals, which is only meaningful
  /// if the goals are used by some activated features.
  bool get showGoals =>
      _profileService.isFeatureEnabled(GamificationUserService.challengesFeatureKey) ||
      _profileService.isFeatureEnabled(GamificationUserService.statisticsFeatureKey);

  @override
  void initState() {
    _profileService = getIt<GamificationUserService>();
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
      children: (!_profileService.hasProfile)
          ? [
              Container(
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
              ),
              const GameIntroCard(),
            ]
          : [
              const OverallStatistics(),
              if (showGoals) const GoalsView(),
              const SmallVSpace(),
              ..._enabledFeatureCards,
              ..._disabledFeatureCards,
            ],
    );
  }
}
