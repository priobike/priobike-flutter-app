import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/intro_page.dart';
import 'package:priobike/main.dart';

class GameInfoPage extends GameIntroPage {
  const GameInfoPage({Key? key, required AnimationController controller}) : super(key: key, controller: controller);

  @override
  IconData get confirmButtonIcon => Icons.check;

  @override
  String get confirmButtonLabel => "Weiter";

  @override
  Widget get mainContent => const Content();

  @override
  void onBackButtonTab(BuildContext context) => Navigator.pop(context);

  @override
  void onConfirmButtonTab(BuildContext context) => getIt<GameIntroService>().setStartedIntro(true);
}

class Content extends StatelessWidget {
  const Content({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: HPad(
        child: Fade(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64 + 16),
                Header(text: "PrioBike Challenge", context: context),
                const SmallVSpace(),
                SubHeader(text: "Möchtest Du an der PrioBike Challenge teilnehmen?", context: context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
