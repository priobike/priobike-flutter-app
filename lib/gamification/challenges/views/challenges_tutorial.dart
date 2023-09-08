import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/services/challenge_profile_service.dart';
import 'package:priobike/gamification/common/views/tutorial_page.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/main.dart';

class ChallengesTutorial extends StatelessWidget {
  const ChallengesTutorial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GameTutorialPage(
      confirmButtonLabel: 'Aktivieren',
      onConfirmButtonTab: () async {
        await getIt<ChallengeProfileService>().createProfile();
        getIt<GamificationUserService>().enableOrDisableFeature(GamificationUserService.gameFeatureChallengesKey);
        if (context.mounted) Navigator.of(context).pop();
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
