import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/intro_page.dart';
import 'package:priobike/main.dart';

/// Intro page which shows basic info about the gamification functionality to the user.
class GameInfoPage extends StatelessWidget {
  /// Controller which handles the appear animation.
  final AnimationController animationController;

  const GameInfoPage({Key? key, required this.animationController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GameIntroPage(
      animationController: animationController,
      confirmButtonLabel: "Weiter",
      onBackButtonTab: () => Navigator.pop(context),
      onConfirmButtonTab: () => getIt<GameIntroService>().setStartedIntro(true),
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
