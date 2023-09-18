import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/views/tutorial_page.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
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
                color: CI.blue,
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
          text: 'Erhalte einen detaillierten Überblick über die von dir zurückgelegten Strecken.',
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
        /*
        IconItem(
          icon: Icons.shield,
          text: 'Nimm an wöchentlichen Events Teil und sammel .',
          context: context,
        ),
        const SmallVSpace(),*/
        SubHeader(
          text: '',
          context: context,
        ),
        const SizedBox(height: 82),
      ],
    );
  }
}
