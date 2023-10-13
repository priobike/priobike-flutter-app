import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/common/views/tutorial_page.dart';
import 'package:priobike/main.dart';

/// A list item with icon.
class IconItem extends Row {
  IconItem({Key? key, required IconData icon, required String text, required BuildContext context})
      : super(
          key: key,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                icon,
                color: CI.radkulturRed,
                size: 56,
                semanticLabel: text,
              ),
            ),
            const SmallHSpace(),
            Expanded(
              child: Content(text: text, context: context),
            ),
          ],
        );
}

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
        Header(text: "Beta-Features Aktivieren", context: context),
        const SmallVSpace(),
        IconItem(
          icon: Icons.query_stats,
          text: 'Erhalte einen detaillierten Überblick über die von dir aufgezeichneten Daten.',
          context: context,
        ),
        const SmallVSpace(),
        IconItem(
          icon: CustomGameIcons.goals,
          text: 'Setze dir individuelle tägliche Ziele und verfolge deinen Fortschritt.',
          context: context,
        ),
        const SmallVSpace(),
        IconItem(
          icon: CustomGameIcons.blank_trophy,
          text:
              'Verbinde deine Fahrten mit täglichen und wöchentlichen Challenges, steige Level auf und sammel virtuelle Belohnungen.',
          context: context,
        ),
        const SmallVSpace(),
        IconItem(
          icon: Icons.shield,
          text:
              'Nimm an den wöchentlichen Stadtteil-Hopping teil und sammel individuelle Abzeichen, indem du Orte in Hamburg besuchst.',
          context: context,
        ),
        const VSpace(),
        Content(
          text:
              'Ab jetzt kannst du die neuen Beta-Features der PrioBike-App ausprobieren! Hierbei handelt es sich um eine Reihe von Funktionen, die es dir ermöglichen, noch mehr über deine Fahrradfahrten zu erfahren, dir Ziele zu setzen und deine Fahrten mit virtuellen Spielmechaniken zu verbinden.',
          context: context,
        ),
        const SmallVSpace(),
        Content(
          text:
              ' Die Beta-Features wurden im Rahmen eines studentischen Projektes entwickelt. Da zu diesem Projekt auch eine Evaluation gehört, werden deine Interaktionen mit den Features aufgezeichnet und anonymisiert an einen Server geschickt und dort ausgewertet.',
          context: context,
        ),
        const SizedBox(height: 82),
      ],
    );
  }
}
