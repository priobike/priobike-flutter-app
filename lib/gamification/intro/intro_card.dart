import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            //color: CI.blue, // Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                blurRadius: 2,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: const [0, 0.5, 1],
              colors: [
                Color.alphaBlend(CI.blue.withOpacity(0.5), Colors.white),
                CI.blue.withOpacity(0.8),
                Color.alphaBlend(CI.blue.withOpacity(0.5), Colors.white),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                  child: Text(
                    "Beta-Features Aktivieren",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'HamburgSans',
                      fontSize: 24,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: 84,
                  width: 96,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 1, top: 4),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Transform.rotate(
                            angle: 0,
                            child: const Icon(
                              CustomGameIcons.blank_trophy,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Transform.rotate(
                            angle: 0,
                            child: const Icon(
                              CustomGameIcons.blank_medal,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Transform.rotate(
                          angle: 0,
                          child: const Icon(
                            Icons.bar_chart,
                            size: 52,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
