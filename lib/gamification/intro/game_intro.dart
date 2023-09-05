import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/tutorial_page.dart';
import 'package:priobike/gamification/profile/services/profile_service.dart';
import 'package:priobike/main.dart';

class GameIntro extends StatelessWidget {
  const GameIntro({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GameTutorialPage(
      confirmButtonLabel: 'Aktivieren',
      onConfirmButtonTab: () {
        getIt<GameProfileService>().createProfile('');
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
