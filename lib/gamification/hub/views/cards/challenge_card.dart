import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/colors.dart';
import 'package:priobike/game/models.dart';
import 'package:priobike/game/view.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/hub/views/cards/hub_card.dart';

class GameChallengesCard extends StatefulWidget {
  const GameChallengesCard({Key? key}) : super(key: key);

  @override
  State<GameChallengesCard> createState() => _GameChallengesCardState();
}

class _GameChallengesCardState extends State<GameChallengesCard> {
  @override
  Widget build(BuildContext context) {
    return GameHubCard(
      content: Column(
        children: [
          ChallengeProgressBar(
            unit: 'km',
            icon: Icons.emoji_events,
            challenge: Challenge(
              id: 0,
              xp: 150,
              intervalStart: DateTime.now(),
              intervalEnd: DateTime.now().add(const Duration(hours: 24)),
              target: 2500,
              progress: Random().nextInt(2500),
              type: ChallengeType.distance.index,
            ),
          ),
          ChallengeProgressBar(
            unit: 'm',
            icon: Icons.military_tech,
            challenge: Challenge(
              id: 0,
              xp: 150,
              intervalStart: DateTime.now(),
              intervalEnd: DateTime.now().add(const Duration(hours: 24)),
              target: 250,
              progress: Random().nextInt(250),
              type: ChallengeType.duration.index,
            ),
          ),
          ChallengeProgressBar(
            unit: 'Fahrten',
            icon: Icons.military_tech,
            challenge: Challenge(
              id: 0,
              xp: 150,
              intervalStart: DateTime.now(),
              intervalEnd: DateTime.now().add(const Duration(days: 5)),
              target: 5,
              progress: Random().nextInt(5),
              type: ChallengeType.track.index,
            ),
          ),
        ],
      ),
    );
  }
}

class ChallengeProgressBar extends StatefulWidget {
  final String unit;

  final IconData icon;

  final Challenge challenge;

  const ChallengeProgressBar({
    Key? key,
    required this.unit,
    required this.icon,
    required this.challenge,
  }) : super(key: key);
  @override
  State<ChallengeProgressBar> createState() => _ChallengeProgressBarState();
}

class _ChallengeProgressBarState extends State<ChallengeProgressBar> {
  /// This bool determines wether the displayed level ring should be animated currently.
  bool animateLevelRing = false;

  Challenge get challenge => widget.challenge;

  Duration get timeLeft => challenge.intervalEnd.difference(DateTime.now());

  String get timeLeftStr {
    var result = '';
    if (timeLeft.inDays > 0) result += '${timeLeft.inDays} Tage ';
    result += '${timeLeft.inHours % 24}:${timeLeft.inMinutes % 60}';
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.333),
              ),
              BoldSmall(
                text: timeLeftStr,
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.333),
              ),
              const SizedBox(width: 16)
            ],
          ),
          SizedBox.fromSize(
            size: const Size.fromHeight(48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      progressBar,
                      Row(
                        children: [
                          Column(
                            children: [
                              Expanded(child: Container()),
                              iconRing,
                              Expanded(child: Container()),
                            ],
                          ),
                        ],
                      ),
                      Center(
                        child: BoldSmall(
                          text: '${challenge.progress} / ${challenge.target} ${widget.unit}',
                          context: context,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get progressBar => Center(
        child: SizedBox.fromSize(
          size: const Size.fromHeight(48),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
                clipBehavior: Clip.hardEdge,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      flex: (challenge.progress / challenge.target * 100).toInt(),
                      child: Container(
                        color: CI.blue,
                      ),
                    ),
                    Expanded(
                      flex: 100 - (challenge.progress / challenge.target * 100).toInt(),
                      child: Container(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ),
              FractionallySizedBox(
                widthFactor: challenge.progress / challenge.target,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: CI.blue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget get iconRing => Container(
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CI.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            if (animateLevelRing) return;
            setState(() => animateLevelRing = true);
            Future.delayed(LongTransitionDuration()).then((_) => setState(() => animateLevelRing = false));
          },
          child: AnimatedLevelRing(
            levels: levels,
            value: 0,
            color: Medals.silver.withOpacity(0.5),
            icon: widget.icon,
            buildWithAnimation: animateLevelRing,
          ),
        ),
      );

  List<Level> get levels => [
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
      ];
}
