import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/views/challenges_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/community_event/views/event_card.dart';
import 'package:priobike/gamification/goals/views/goals_view.dart';
import 'package:priobike/gamification/intro/intro_card.dart';
import 'package:priobike/gamification/statistics/views/card/stats_card.dart';
import 'package:priobike/gamification/statistics/views/overall_stats.dart';
import 'package:priobike/gamification/survey_card.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tutorial/view.dart';

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
    GamificationUserService.challengesFeatureKey: Column(
      children: const [
        TutorialView(
          padding: EdgeInsets.fromLTRB(48, 16, 48, 8),
          id: 'priobike.gamification.challenges.tutorial',
          text:
              'Erfülle tägliche Challenges, steige Level auf und lass Dich überraschen, vor was für Herausforderungen Du dabei sonst noch gestellt wirst...',
          color: Colors.white,
        ),
        ChallengesCard(),
      ],
    ),
    GamificationUserService.statisticsFeatureKey: Column(
      children: const [
        TutorialView(
          padding: EdgeInsets.fromLTRB(48, 16, 48, 8),
          id: 'priobike.gamification.statistics.tutorial',
          text:
              'Erhalte einen genaueren Überblick über Deine zurückgelegten Fahrten, durch tägliche, wöchentliche und monatliche Statistik-Überblicke.',
          color: Colors.white,
        ),
        RideStatisticsCard(),
      ],
    ),
    GamificationUserService.communityFeatureKey: Column(
      children: const [
        TutorialView(
          padding: EdgeInsets.fromLTRB(48, 16, 48, 8),
          id: 'priobike.gamification.community.tutorial',
          text:
              'Besuche jedes Wochenende einen anderen Stadtteil von Hamburg und sammel dabei unterschiedliche Abzeichen.',
          color: Colors.white,
        ),
        EventCard(),
      ],
    ),
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
    // Show card which gives the user the option to participate in the evaluation survey.
    return Column(
      children: [
        const SizedBox(height: 24),
        GameSurveyCard(),
        const SizedBox(height: 16),
      ],
    );
    // Disable all gamification features for now, after the evaluation phase has finished.
    // ignore: dead_code
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: 4),
                    Small(
                      text: "Probiere neue Funktionen aus.",
                      context: context,
                      textAlign: TextAlign.center,
                      color: Theme.of(context).colorScheme.onSurface,
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
