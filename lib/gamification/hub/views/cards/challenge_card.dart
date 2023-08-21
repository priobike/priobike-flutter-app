import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
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
            challenge: Challenge(
              id: 0,
              xp: 150,
              start: DateTime.now(),
              end: DateTime.now().add(const Duration(days: 5)),
              target: 5,
              progress: math.Random().nextInt(7),
              type: ChallengeType.rides.index,
              description: 'Fahre 5 mal mit dem Rad zur Arbeit.',
              isWeekly: true,
              valueLabel: 'Fahrten',
            ),
          ),
          ChallengeProgressBar(
            challenge: Challenge(
              id: 0,
              xp: 150,
              start: DateTime.now(),
              end: DateTime.now().add(const Duration(hours: 24)),
              target: 2500,
              progress: math.Random().nextInt(4000),
              type: ChallengeType.distance.index,
              description: 'Fahre 2,5 Kilometer mit dem Fahrrad.',
              isWeekly: false,
              valueLabel: 'm',
            ),
          ),
          const SmallVSpace(),
        ],
      ),
    );
  }
}

/// A Widget which displays the progress of a given challenge and relevant info about the challenge.
/// It also provides the option to provide the rewards, if the challenge was completed.
class ChallengeProgressBar extends StatefulWidget {
  final Challenge challenge;

  const ChallengeProgressBar({
    Key? key,
    required this.challenge,
  }) : super(key: key);
  @override
  State<ChallengeProgressBar> createState() => _ChallengeProgressBarState();
}

class _ChallengeProgressBarState extends State<ChallengeProgressBar> {
  /// A timer that is used to update the displayed time left, or to create the pulsing animation when completed.
  Timer? timer;

  /// This bool determines wether the displayed level ring should be animated currently.
  bool animateLevelRing = false;

  /// This value determines the shadow spread of the challenge icon.
  /// It is used to create the pulsing animation for completed challenges.
  double iconShadowSpred = 12;

  /// The challenge connected to this widget.
  Challenge get challenge => widget.challenge;

  /// Time left till the challenge ends.
  Duration get timeLeft => challenge.end.difference(DateTime.now());

  /// The progress of completion of the challenge as a percentage value between 0 and 100.
  double get progressPercentage => challenge.progress / challenge.target;

  /// Returns true, if the user completed the challenge.
  bool get isCompleted => progressPercentage >= 1;

  /// Returns a string describing how much time the user has left for a challenge.
  String get timeLeftStr {
    var result = '';
    if (timeLeft.inDays > 0) result += '${timeLeft.inDays} Tage ';
    result += '${timeLeft.inHours % 24}:${timeLeft.inMinutes % 60}';
    return result;
  }

  /// Either start a timer which updates the time left every minute, or, if the challenge has been completed,
  /// start a timer that creates the pulsing animation by changing the icon shadow spread value periodically.
  void startUpdateTimer() {
    endTimer();
    if (progressPercentage >= 1) {
      timer = Timer.periodic(
          ShortTransitionDuration(),
          (timer) => setState(() {
                iconShadowSpred = (iconShadowSpred == 0) ? 20 : 0;
              }));
    } else {
      timer = Timer.periodic(
        const Duration(seconds: 10),
        (timer) => setState(() {}),
      );
    }
  }

  /// End any running timer.
  void endTimer() {
    timer?.cancel();
    timer = null;
  }

  @override
  void initState() {
    startUpdateTimer();
    super.initState();
  }

  @override
  void dispose() {
    endTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
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
                          text: '${challenge.progress} / ${challenge.target} ${challenge.valueLabel}',
                          context: context,
                          textAlign: TextAlign.center,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Small(
                  text: challenge.description,
                  context: context,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
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
                      flex: (progressPercentage * 100).toInt(),
                      child: Container(
                        color: CI.blue,
                      ),
                    ),
                    Expanded(
                      flex: isCompleted ? 0 : ((1 - progressPercentage) * 100).toInt(),
                      child: Container(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ),
              FractionallySizedBox(
                widthFactor: isCompleted ? 1 : progressPercentage,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: CI.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget get iconRing => AnimatedContainer(
        duration: ShortTransitionDuration(),
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CI.blue.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: isCompleted ? iconShadowSpred : iconShadowSpred * progressPercentage,
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
            color: CI.blue.withOpacity(isCompleted ? 1 : math.max(progressPercentage, 0.25)),
            icon: challenge.isWeekly ? Icons.emoji_events : Icons.military_tech,
            buildWithAnimation: animateLevelRing,
          ),
        ),
      );

  List<Level> get levels => [level, level, level, level, level, level, level];

  Level get level =>
      Level(value: 0, title: '', color: CI.blue.withOpacity(isCompleted ? 1 : 0.5 + 0.5 * progressPercentage));
}
