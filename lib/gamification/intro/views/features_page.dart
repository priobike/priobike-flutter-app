import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/intro_page.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/gamification/settings/views/feature_settings.dart';
import 'package:priobike/main.dart';

/// Intro page which gives the user the option to enable or disable game features.
class GameFeaturesPage extends StatelessWidget {
  /// Controller which handles the appear animation.
  final AnimationController animationController;

  const GameFeaturesPage({Key? key, required this.animationController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GameIntroPage(
      animationController: animationController,
      confirmButtonLabel: "Auswahl Bestätigen",
      onBackButtonTab: () => getIt<GameIntroService>().setStartedIntro(false),
      onConfirmButtonTab: () => getIt<GameIntroService>().setConfirmedFeaturePage(true),
      contentList: [
        const SizedBox(height: 64 + 16),
        Header(text: "Wähle deine Preferenzen:", context: context),
        SubHeader(text: "Keine Angst, du kannst deine Auswahl später noch ändern", context: context),
        ...GameSettingsService.gameFeaturesLabelMap.entries
            .map((e) => GameFeatureElement(label: e.value, featureKey: e.key))
            .toList(),
        const SizedBox(height: 82),
      ],
    );
  }
}
