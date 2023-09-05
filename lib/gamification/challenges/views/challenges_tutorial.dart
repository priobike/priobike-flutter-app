import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/views/goal_setting.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/tutorial_page.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/main.dart';

class ChallengesTutorial extends StatelessWidget {
  const ChallengesTutorial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GameTutorialPage(
      confirmButtonLabel: 'Aktivieren',
      onConfirmButtonTab: () {
        getIt<GameProfileService>().enableOrDisableFeature(GameProfileService.gameFeatureChallengesKey);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: TinyDuration(),
            reverseTransitionDuration: TinyDuration(),
            pageBuilder: (context, animation, secondaryAnimation) => const ChallengeGoalSetting(),
          ),
        );
      },
      contentList: [
        const SizedBox(height: 64 + 16),
        Header(text: "PrioBike Challenges", context: context),
        const SmallVSpace(),
        SubHeader(text: "Absolviere tägliche und wöchentliche Challenges.", context: context),
        const SizedBox(height: 82),
      ],
    );
  }
}
