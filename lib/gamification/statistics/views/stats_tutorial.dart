import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/tutorial_page.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/main.dart';

class StatisticsTutorial extends StatelessWidget {
  const StatisticsTutorial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GameTutorialPage(
      confirmButtonLabel: 'Aktivieren',
      onConfirmButtonTab: () {
        getIt<GameProfileService>().enableOrDisableFeature(GameProfileService.gameFeatureStatisticsKey);
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
