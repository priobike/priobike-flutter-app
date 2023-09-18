import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/views/challenges_card.dart';
import 'package:priobike/gamification/community/views/community_card.dart';
import 'package:priobike/gamification/goals/views/goals_view.dart';
import 'package:priobike/gamification/intro/intro_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/statistics/views/overall_stats.dart';
import 'package:priobike/gamification/statistics/views/card/stats_card.dart';
import 'package:priobike/main.dart';

/// This view displays the gamification functionality according to the user settings.
class GameView extends StatefulWidget {
  const GameView({Key? key}) : super(key: key);

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  /// This service provides user information.
  late GamificationUserService _userService;

  /// The gamification features mapped to their corresponding cards.
  final Map<String, Widget> _featureCards = {
    GamificationUserService.challengesFeatureKey: const ChallengesCard(),
    GamificationUserService.statisticsFeatureKey: const RideStatisticsCard(),
    GamificationUserService.communityFeatureKey: Container(), //const CommunityCard(),
  };

  /// List of feature cards for enabled features.
  List<Widget> get _enabledFeatureCards =>
      _userService.enabledFeatures.map((key) => _featureCards[key] as Widget).toList();

  /// List of feature cards for disabled features.
  List<Widget> get _disabledFeatureCards =>
      _userService.disabledFeatures.map((key) => _featureCards[key] as Widget).toList();

  /// Whether to give the user the option to set goals, which is only meaningful
  /// if the goals are used by some activated features.
  bool get _showGoals =>
      _userService.isFeatureEnabled(GamificationUserService.challengesFeatureKey) ||
      _userService.isFeatureEnabled(GamificationUserService.statisticsFeatureKey);

  @override
  void initState() {
    _userService = getIt<GamificationUserService>();
    _userService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _userService.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: (!_userService.hasProfile)
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
              const SizedBox(height: 16),
              const GameIntroCard(),
            ]
          : [
              const OverallStatistics(),
              if (_showGoals) const GoalsView(),
              const SmallVSpace(),
              ..._enabledFeatureCards,
              ..._disabledFeatureCards,
            ],
    );
  }
}
