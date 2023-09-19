import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/tutorial_page.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/main.dart';

/// This tutorial page gives the user a brief introduction to the statistics feature
/// and gives them the option to activate it.
class StatisticsTutorial extends StatelessWidget {
  const StatisticsTutorial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TutorialPage(
      confirmButtonLabel: 'Aktivieren',
      onConfirmButtonTab: () {
        getIt<GamificationUserService>().enableFeature(GamificationUserService.statisticsFeatureKey);
        Navigator.of(context).pop();
      },
      contentList: [
        const SizedBox(height: 64 + 16),
        Header(text: "Fahrtstatistiken", context: context),
        const SmallVSpace(),
        SubHeader(text: "Verschaffe dir einen Überblick über deine aufgezeichneten Fahrtdaten.", context: context),
        const SizedBox(height: 82),
      ],
    );
  }
}
