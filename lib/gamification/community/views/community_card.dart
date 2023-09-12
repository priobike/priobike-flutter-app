import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/feature_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/community/views/community_tutorial.dart';

/// This card is displayed on the home view and holds all information about the users
/// game state regarding the challenges feature.
class CommunityCard extends StatelessWidget {
  const CommunityCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GamificationFeatureCard(
      featureKey: GamificationUserService.communityFeatureKey,
      // If the feature is enabled, show progress bars of the users challenges and the profile view.
      featureEnabledContent: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BoldSubHeader(text: 'PrioBike Community', context: context),
            ],
          )
        ],
      ),
      // If the feature is disabled, show an info widget which directs the user to an intro page.
      tutorialPage: const CommunityTutorial(),
      featureDisabledContent: Column(
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
                        text: 'PrioBike Community',
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
                            alignment: Alignment.center,
                            child: Transform.rotate(
                              angle: 0,
                              child: const Icon(
                                Icons.groups,
                                size: 80,
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
}
