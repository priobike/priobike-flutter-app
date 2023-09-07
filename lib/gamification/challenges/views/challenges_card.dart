import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/views/challenges_tutorial.dart';
import 'package:priobike/gamification/challenges/views/profile_view.dart';
import 'package:priobike/gamification/challenges/views/progress_bar.dart';
import 'package:priobike/gamification/common/colors.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/views/feature_card.dart';
import 'package:priobike/gamification/common/views/game_card.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';

/// This card displays the current challenge state of the user or encourages them to set their challenge goals.
/// If no goals are set, the goal setting view can be opened by tapping the card. otherwise it can be opened by
/// tapping a button at the bottom.
class GameChallengesCard extends StatefulWidget {
  const GameChallengesCard({Key? key}) : super(key: key);

  @override
  State<GameChallengesCard> createState() => _GameChallengesCardState();
}

class _GameChallengesCardState extends State<GameChallengesCard> {
  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      featureKey: GameProfileService.gameFeatureChallengesKey,
      featureEnabledWidget: challengesEnabledWidget,
      featureDisabledWidget: challengesDisabledWidget,
    );
  }

  Widget get challengesEnabledWidget => GamificationCard(
        content: Column(
          children: const [
            GameProfileView(),
            SmallVSpace(),
            ChallengeProgressBar(isWeekly: true),
            ChallengeProgressBar(isWeekly: false),
            SmallVSpace(),
          ],
        ),
      );

  /// Info widget which encourages the user to participate in the challenges.
  Widget get challengesDisabledWidget => GamificationCard(
        directionView: const ChallengesTutorial(),
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: BoldSubHeader(
                          text: 'PrioBike Challenges',
                          context: context,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SmallHSpace(),
                      SizedBox(
                        width: 96,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: Container(
                                width: 0,
                                height: 0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: CI.blue.withOpacity(0.05),
                                      blurRadius: 24,
                                      spreadRadius: 24,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.01),
                                      blurRadius: 24,
                                      spreadRadius: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Transform.rotate(
                                angle: pi / 8,
                                child: const Icon(
                                  CustomGameIcons.elevation_trophy,
                                  size: 64,
                                  color: Medals.gold,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Transform.rotate(
                                angle: -pi / 8,
                                child: const Icon(
                                  CustomGameIcons.distance_medal,
                                  size: 64,
                                  color: CI.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
