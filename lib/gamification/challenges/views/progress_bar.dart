import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/services/challenge_service.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/challenges/views/challenge_choice_dialog.dart';
import 'package:priobike/gamification/challenges/views/single_challenge_dialog.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/challenges/views/level_ring.dart';
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

  /// This bool is true, if the progress bar has been tapped and needs to be animated.
  bool onTapAnimation = false;

  /// This bool is true, if the progress bar has been tapped to collect a reward and the reward animation is shown.
  bool completedAnimation = false;

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

  /// If there is no active challenge, and there are no available challenge choices, and the service does not allow
  /// the generation of a new challenge, this bar ist true and indicates, that a tap on the bar should do nothing.
  bool get deactivateTap => challenge == null && !service.allowNew && service.challengeChoices.isEmpty;

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
    _ringController = AnimationController(vsync: this, duration: MediumDuration(), value: 1);
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
          MediumDuration(),
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
    /// If there is a challenge, but it hasn't been completed yet, finish it TODO just for tests.
    if (challenge != null && !isCompleted) {
      //service.finishChallenge();
      return showDialog(
        context: context,
        builder: (context) => SingleChallengeDialog(challenge: challenge!, isWeekly: challenge!.isWeekly),
      );
    }

    // Start and stop the ring and glowing animation of the progress bar and wait till the animation has finished.
    _ringController.reverse();
    setState(() => onTapAnimation = true);
    if (isCompleted) setState(() => completedAnimation = true);
    await Future.delayed(MediumDuration()).then((_) => setState(() => onTapAnimation = false));
    // If there are a number of challenges, of which the user can chose from, open the challenge selection dialog.
    if (service.challengeChoices.isNotEmpty) {
      await _showChallengeSelection(service.challengeChoices);
    }
    // If the challenge has been completed, update it in the db and give haptic feedback again, as the user receives their rewards.
    else if (isCompleted) {
      await Future.delayed(MediumDuration()).then((_) {
        setState(() => completedAnimation = false);
      });
      service.completeChallenge();
      HapticFeedback.heavyImpact();
    }
    // If there is no challenge, but the service allows a new one, generate a new one.
    else if (challenge == null && service.allowNew) {
      var result = await service.generateChallengeChoices();
      if (result != null) {
        await _showChallengeSelection(result);
      }
    }
    _ringController.forward();
  }

  /// This function opens a dialog, where the user is shown their generated challenge, or is given a choice between
  /// a number of challenges, if multiple were generated.
  Future<void> _showChallengeSelection(List<Challenge> challenges) async {
    // The dialog returns an index of the selected challenge or null, if no selection was made.
    var result = await showDialog<int?>(
      context: context,
      barrierDismissible: challenges.length == 1,
      builder: (BuildContext context) {
        if (challenges.length == 1) {
          return SingleChallengeDialog(
            challenge: challenges.first,
            isWeekly: widget.isWeekly,
          );
        } else {
          return ChallengeChoiceDialog(
            challenges: challenges,
            isWeekly: widget.isWeekly,
          );
        }
      },
    );
    // If there is only one challenge to chose from, select that challenge.
    if (challenges.length == 1) {
      service.selectAndStartChallenge(0);
    }
    // If there are multiple challenges to chose from, select a challenge according to the users choice.
    else if (result != null) {
      service.selectAndStartChallenge(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          getTimeLeftWidget(),
          getProgressBar(),
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
                Icon(
                  Icons.timer,
                  size: 16,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.333),
                ),
                BoldSmall(
                  text: StringFormatter.getTimeLeftStr(endTime),
                  context: context,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.333),
                ),
                const SizedBox(width: 16),
              ],
      ],
    );
  }

  /// This widget returns the progress bar corresponding to the challenge state.
  Widget getProgressBar() {
    /*return AnimatedButton(
      scaleFactor: 0.95,
      onPressed: (deactivateTap) ? null : handleTap,*/
    return GestureDetector(
      onTap: (deactivateTap) ? null : handleTap,
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
                                  duration: LongDuration(),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CI.blue.withOpacity((isCompleted && completedAnimation) ? 1 : 0.3),
                                        blurRadius: 20,
                                        spreadRadius: (isCompleted && completedAnimation) ? 5 : 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]
                          : [
                              AnimatedContainer(
                                duration: MediumDuration(),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(32)),
                                  boxShadow: [
                                    BoxShadow(color: CI.blue.withOpacity(onTapAnimation ? 0.2 : 0), blurRadius: 20),
                                  ],
                                  gradient: LinearGradient(
                                    colors: [
                                      CI.blue.withOpacity(deactivateTap ? 0.2 : (onTapAnimation ? 0.8 : 0.5)),
                                      CI.blue.withOpacity(deactivateTap ? 0.01 : (onTapAnimation ? 0.2 : 0.05)),
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
                    ? (deactivateTap ? 'Challenge abgeschlossen' : 'Neue Challenge starten!')
                    : (isCompleted)
                        ? 'Belohnung einsammeln'
                        : '${challenge!.progress} / ${challenge!.target}',
                context: context,
                color: isCompleted ? Colors.white : Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
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
      duration: MediumDuration(),
      margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: ((isCompleted && completedAnimation) || deactivateTap)
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
            ? (widget.isWeekly ? CustomGameIcons.blank_trophy : CustomGameIcons.blank_medal)
            : ChallengeGenerator.getChallengeIcon(challenge!),
        animationController: _ringController,
        ringColor: color,
        background: Theme.of(context).colorScheme.background,
      ),
    );
  }
}
