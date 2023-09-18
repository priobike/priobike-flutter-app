import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/tutorial_page.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/main.dart';

/// This tutorial page gives the user a brief introduction to the community feature
/// and gives them the option to activate it.
class CommunityTutorial extends StatelessWidget {
  const CommunityTutorial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TutorialPage(
      confirmButtonLabel: 'Aktivieren',
      onConfirmButtonTab: () async {
        getIt<GamificationUserService>().enableFeature(GamificationUserService.communityFeatureKey);
        if (context.mounted) Navigator.of(context).pop();
      },
      contentList: [
        const SizedBox(height: 64 + 16),
        Header(text: "PrioBike Community", context: context),
        const SmallVSpace(),
        SubHeader(text: "Mal schauen gel.", context: context),
        const SizedBox(height: 82),
      ],
    );
  }
}
