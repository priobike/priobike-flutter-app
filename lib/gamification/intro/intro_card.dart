import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:priobike/gamification/intro/intro_page.dart';

/// Intro card to be displayed on the home view of the app, if the gamification feauture is disabled.
class GameIntroCard extends StatelessWidget {
  const GameIntroCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: OnTapAnimation(
        scaleFactor: 0.95,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const IntroPage())),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.07),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoldSubHeader(text: "Dein PrioBike", context: context),
              const SizedBox(height: 4),
              Small(text: "Entdecke eine Vielzahl an neuen Funktionen!", context: context),
            ],
          ),
        ),
      ),
    );
  }
}
