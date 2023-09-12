import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/tutorial_page.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/main.dart';

/// Page to give the user an intro to the gamification feature and let them enable it.
class IntroPage extends StatelessWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TutorialPage(
      confirmButtonLabel: 'Aktivieren',
      onConfirmButtonTab: () {
        getIt<GamificationUserService>().createProfile();
        Navigator.of(context).pop();
      },
      contentList: [
        const SizedBox(height: 64 + 16),
        Header(text: "PrioBike Challenge", context: context),
        const SmallVSpace(),
        SubHeader(text: "Möchtest Du an der PrioBike Challenge teilnehmen?", context: context),
        const SizedBox(height: 82),
      ],
    );
  }
}
