import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/services/challenges_service.dart';
import 'package:priobike/gamification/challenges/views/new_challenge_dialog.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/level_ring.dart';
import 'package:priobike/main.dart';

/// A Widget which displays the progress of a given challenge and relevant info about the challenge.
/// It also provides the option to get the rewards, if the challenge was completed.
class ChallengeProgressBar extends StatefulWidget {
  /// Determine whether to build the progress bar for weekly or for daily challenges.
  final bool isWeekly;

  const ChallengeProgressBar({
    Key? key,
    required this.isWeekly,
  }) : super(key: key);
  @override
  State<ChallengeProgressBar> createState() => _ChallengeProgressBarState();
}

class _ChallengeProgressBarState extends State<ChallengeProgressBar> with SingleTickerProviderStateMixin {
  /// A timer that is used to update the displayed time left, or to create the pulsing animation when completed.
  Timer? timer;

  /// This bool determines whether the progress bar should be animated currently.
  bool isAnimating = false;

  /// This bool determines wether the displayed level ring should be animated currently.
  bool isAnimatingRing = false;

  /// Animation Controller to controll the ring animation.
  late final AnimationController _ringController;

  /// This value determines the shadow spread of the challenge icon.
  /// It is used to create the pulsing animation for completed challenges.
  double iconShadowSpred = 12;

  /// Get the weekly or daily challenge service, according to the isWeekly variable.
  ChallengeService get service => widget.isWeekly ? getIt<WeeklyChallengeService>() : getIt<DailyChallengeService>();

  /// Get the challenge currently connected to the progress bar, or null if there is none.
  Challenge? get challenge => service.currentChallenge;

  /// The progress of completion of the challenge as a percentage value between 0 and 100.
  double get progressPercentage => challenge == null ? 0 : challenge!.progress / challenge!.target;

  /// Returns true, if the user completed the challenge.
  bool get isCompleted => progressPercentage >= 1;

  /// Time where the challenge ends.
  DateTime get endTime {
    var now = DateTime.now();
    if (widget.isWeekly) {
      return now.add(Duration(days: 8 - now.weekday)).copyWith(hour: 0, minute: 0, second: 0);
    } else {
      return now.add(const Duration(days: 1)).copyWith(hour: 0, minute: 0, second: 0);
    }
  }

  /// Called when a listener callback of a ChangeNotifier is fired. It restards the update timer and rebuilds the widget.
  void update() {
    if (isCompleted) startUpdateTimer();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    _ringController = AnimationController(vsync: this, duration: ShortAnimationDuration(), value: 1);
    startUpdateTimer();
    service.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    endTimer();
    service.removeListener(update);
    super.dispose();
  }

  /// Either start a timer which updates the time left every minute, or, if the challenge has been completed,
  /// start a timer that creates the pulsing animation by changing the icon shadow spread value periodically.
  void startUpdateTimer() {
    endTimer();
    if (isCompleted) {
      timer = Timer.periodic(
          ShortAnimationDuration(),
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

  /// Handle a tap on the progress bar.
  void handleTap() async {
    // If the challenge is null and the service doesn't allow to generate a new one, do nothing on tap.
    if (challenge == null && !service.allowNew) return;

    /// Start and stop the ring and glowing animation of the progress bar and wait till the animation has finished.
    _ringController.reverse();
    setState(() {
      isAnimating = true;
      isAnimatingRing = true;
    });
    await Future.delayed(ShortAnimationDuration()).then((_) => setState(() => isAnimating = false));
    await Future.delayed(ShortAnimationDuration()).then((_) {
      _ringController.forward();
      setState(() => isAnimatingRing = false);
    });

    /// If the challenge has been completed, update it in the db and give haptic feedback again, as the user receives their rewards.
    if (isCompleted) {
      service.completeChallenge();
      HapticFeedback.heavyImpact();
    }

    /// If there is no challenge, but the service allows a new one, generate a new one.
    else if (challenge == null && service.allowNew) {
      var result = await service.generateChallenge();
      if (result != null) {
        await _showMyDialog(result);
        service.startChallenge();
      }
    }

    /// If there is a challenge, but it hasn't been completed yet, finish it TODO just for tests.
    else if (challenge != null && !isCompleted) {
      service.finishChallenge();
    }
  }

  Future<void> _showMyDialog(Challenge challenge) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return NewChallengeDialog(
          challenges: [challenge],
          isWeekly: widget.isWeekly,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          getTimeLeftWidget(),
          getProgressBar(),
          getDescriptionWidget(),
        ],
      ),
    );
  }

  /// Returns a widget which displays the time the user has left for the challenge. It also displays a title, which
  /// depends on whether if the challenge is a daily or a weekly challenge. Additionally, the time left is only shown,
  /// if there is a displayed challenge, or if the user is allowed to create a new one.
  Widget getTimeLeftWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16),
            child: BoldSmall(
              text: widget.isWeekly ? 'Wochenchallenge:' : 'Tageschallenge:',
              context: context,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
            ),
          ),
        ),
        ...(challenge != null && isCompleted)
            ? []
            : [
                BlendIn(
                  child: Icon(
                    Icons.timer,
                    size: 16,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.333),
                  ),
                ),
                BlendIn(
                  child: BoldSmall(
                    text: StringFormatter.getTimeLeftStr(endTime),
                    context: context,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.333),
                  ),
                ),
                const SizedBox(width: 16),
              ],
      ],
    );
  }

  /// This widget displays the description of the displayed challenge.
  Widget getDescriptionWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(height: 30),
          if (challenge != null)
            Expanded(
              child: BlendIn(
                child: Small(
                  text: challenge!.description,
                  context: context,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// This widget returns the progress bar corresponding to the challenge state.
  Widget getProgressBar() {
    return GestureDetector(
      onTap: handleTap,
      onLongPress: () => service.deleteCurrentChallenge(),
      child: SizedBox.fromSize(
        size: const Size.fromHeight(44),
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(32)),
                      border:
                          Border.all(width: 2, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.075)),
                    ),
                    child: Stack(
                      children: (challenge != null)
                          ? [
                              FractionallySizedBox(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: isCompleted ? 1 : progressPercentage,
                                    child: Container(color: CI.blue),
                                  ),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: isCompleted ? 1 : progressPercentage,
                                heightFactor: 1,
                                child: AnimatedContainer(
                                  duration: LongAnimationDuration(),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CI.blue.withOpacity((isCompleted && isAnimatingRing) ? 1 : 0.3),
                                        blurRadius: 20,
                                        spreadRadius: (isCompleted && isAnimatingRing) ? 5 : 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]
                          : [
                              AnimatedContainer(
                                duration: ShortAnimationDuration(),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(32)),
                                  boxShadow: [
                                    BoxShadow(color: CI.blue.withOpacity(isAnimating ? 0.2 : 0), blurRadius: 20),
                                  ],
                                  gradient: LinearGradient(
                                    colors: [
                                      CI.blue.withOpacity(
                                          (challenge == null && !service.allowNew) ? 0.2 : (isAnimating ? 0.8 : 0.5)),
                                      CI.blue.withOpacity(
                                          (challenge == null && !service.allowNew) ? 0.01 : (isAnimating ? 0.2 : 0.05)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [getIconRing()],
            ),
            Center(
              child: BoldSmall(
                text: (challenge == null)
                    ? (service.allowNew ? 'Neue Challenge starten!' : 'Challenge abgeschlossen')
                    : (isCompleted)
                        ? 'Belohnung einsammeln'
                        : '${challenge!.progress} / ${challenge!.target}',
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget returns a small icon ring to be displayed inside of the progress bar.
  Widget getIconRing() {
    var color = CI.blue.withOpacity(isCompleted ? 1 : math.max(progressPercentage, 0.25));
    return AnimatedContainer(
      duration: ShortAnimationDuration(),
      margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: ((isCompleted && isAnimatingRing) || (challenge == null && !service.allowNew))
            ? []
            : [
                BoxShadow(
                  color: CI.blue.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: isCompleted ? iconShadowSpred : iconShadowSpred * progressPercentage,
                ),
              ],
      ),
      child: LevelRing(
        ringSize: 32,
        iconColor: color,
        icon: (challenge == null)
            ? Icons.question_mark
            : (challenge!.isWeekly ? Icons.emoji_events : Icons.military_tech),
        animationController: _ringController,
        ringColor: color,
      ),
    );
  }
}
