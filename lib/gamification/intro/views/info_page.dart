import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/main.dart';

class GameInfoPage extends StatelessWidget {
  const GameInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: HPad(
                child: Fade(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 164),
                        Header(text: "PrioBike Challenge", context: context),
                        const SmallVSpace(),
                        SubHeader(text: "Möchtest Du an der PrioBike Challenge teilnehmen?", context: context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppBackButton(onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Pad(
                child: BigButton(
                  icon: Icons.check,
                  iconColor: Colors.white,
                  label: "Teilnehmen",
                  onPressed: getIt<GameIntroService>().startIntro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
