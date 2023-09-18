import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/services/challenges_profile_service.dart';
import 'package:priobike/gamification/challenges/views/profile/profile_view.dart';
import 'package:priobike/gamification/challenges/views/progress_bar/progress_bar.dart';
import 'package:priobike/gamification/common/colors.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/views/feature_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/main.dart';

/// This card is displayed on the home view and holds all information about the users
/// game state regarding the challenges feature.
class ChallengesCard extends StatelessWidget {
  const ChallengesCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GamificationFeatureCard(
      featureKey: GamificationUserService.challengesFeatureKey,
      // If the feature is enabled, show progress bars of the users challenges and the profile view.
      onEnabled: () async {
        await getIt<ChallengesProfileService>().createProfile();
        await getIt<GamificationUserService>().enableFeature(GamificationUserService.challengesFeatureKey);
      },
      featureEnabledContent: Column(
        children: const [
          GameProfileView(),
          SmallVSpace(),
          SmallVSpace(),
          ChallengeProgressBar(isWeekly: true),
          ChallengeProgressBar(isWeekly: false),
        ],
      ),
      featureDisabledContent: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
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
                      child: Icon(
                        CustomGameIcons.elevation_trophy,
                        size: 64,
                        color: Theme.of(context).brightness == Brightness.light
                            ? LevelColors.brighten(LevelColors.gold)
                            : LevelColors.gold,
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
      ),
    );
  }
}
