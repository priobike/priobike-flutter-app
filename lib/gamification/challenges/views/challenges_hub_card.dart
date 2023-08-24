import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/models.dart';
import 'package:priobike/game/view.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/challenges/services/challenges_service.dart';
import 'package:priobike/gamification/challenges/views/challenge_goals.dart';
import 'package:priobike/gamification/hub/views/cards/hub_card.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/main.dart';

class GameChallengesCard extends StatefulWidget {
  /// Open view function from parent widget is required, to animate the hub cards away when opening the stats view.
  final Future Function(Widget view) openView;
  const GameChallengesCard({Key? key, required this.openView}) : super(key: key);

  @override
  State<GameChallengesCard> createState() => _GameChallengesCardState();
}

class _GameChallengesCardState extends State<GameChallengesCard> {
  late GameSettingsService _settingsService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    _settingsService = getIt<GameSettingsService>();
    _settingsService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _settingsService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameHubCard(
      onTap: () async {
        if (!_settingsService.challengeGoalsSet) {
          widget.openView(const ChallengeGoalsView());
        }
      },
      content: Column(
        children: _settingsService.challengeGoalsSet
            ? [
                const ChallengeProgressBar(isWeekly: true),
                const ChallengeProgressBar(isWeekly: false),
                GestureDetector(
                  onTap: () => widget.openView(const ChallengeGoalsView()),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BoldSmall(text: 'Ziele ändern', context: context),
                      const SizedBox(width: 4),
                      const Icon(Icons.redo, size: 16),
                    ],
                  ),
                ),
              ]
            : [
                getNoGoalsWidget(),
              ],
      ),
    );
  }

  Widget getNoGoalsWidget() {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoldSubHeader(text: 'PrioBike Challenges', context: context),
            Small(
              text: 'Bestreite tägliche und wöchentliche Challenges, steige Level auf uns sammel Abzeichen und Orden.',
              context: context,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BoldSmall(text: 'Challenges Starten', context: context),
                const SizedBox(width: 4),
                const Icon(Icons.redo, size: 16),
              ],
            ),
          ],
        ));
  }
}

/// A Widget which displays the progress of a given challenge and relevant info about the challenge.
/// It also provides the option to provide the rewards, if the challenge was completed.
class ChallengeProgressBar extends StatefulWidget {
  final bool isWeekly;

  const ChallengeProgressBar({
    Key? key,
    required this.isWeekly,
  }) : super(key: key);
  @override
  State<ChallengeProgressBar> createState() => _ChallengeProgressBarState();
}

class _ChallengeProgressBarState extends State<ChallengeProgressBar> {
  /// A timer that is used to update the displayed time left, or to create the pulsing animation when completed.
  Timer? timer;

  /// This bool determines wether the displayed level ring should be animated currently.
  bool isAnimating = false;
  bool isAnimatingRing = false;

  /// This value determines the shadow spread of the challenge icon.
  /// It is used to create the pulsing animation for completed challenges.
  double iconShadowSpred = 12;

  ChallengeService get service => widget.isWeekly ? getIt<WeeklyChallengeService>() : getIt<DailyChallengeService>();

  Challenge? get challenge => service.currentChallenge;

  /// Time left till the challenge ends.
  Duration getTimeLeft() {
    var now = DateTime.now();
    if (widget.isWeekly) {
      var startOfNextWeek = now.add(Duration(days: 8 - now.weekday)).copyWith(hour: 0, minute: 0, second: 0);
      return startOfNextWeek.difference(now);
    } else {
      var tomorrow = now.add(const Duration(days: 1)).copyWith(hour: 0, minute: 0, second: 0);
      return tomorrow.difference(now);
    }
  }

  /// The progress of completion of the challenge as a percentage value between 0 and 100.
  double get progressPercentage => challenge == null ? 0 : challenge!.progress / challenge!.target;

  /// Returns true, if the user completed the challenge.
  bool get isCompleted => progressPercentage >= 1;

  /// Returns a string describing how much time the user has left for a challenge.
  String get timeLeftStr {
    var result = '';
    var timeLeft = getTimeLeft();
    if (timeLeft.inDays > 0) result += '${timeLeft.inDays} Tage ';
    var formatter = NumberFormat('00');
    result += '${formatter.format(timeLeft.inHours % 24)}:${formatter.format(timeLeft.inMinutes % 60)}h';
    return result;
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    if (isCompleted) startUpdateTimer();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (!(challenge == null && !service.allowNew)) {
          if (isCompleted) HapticFeedback.mediumImpact();
          setState(() {
            isAnimating = true;
            isAnimatingRing = true;
          });
          await Future.delayed(ShortTransitionDuration()).then((_) => setState(() => isAnimating = false));
          await Future.delayed(ShortTransitionDuration()).then((_) => setState(() => isAnimatingRing = false));
          if (challenge == null) {
            if (service.allowNew) service.generateChallenge();
          } else if (challenge!.progress < challenge!.target) {
            service.finishChallenge();
          } else {
            HapticFeedback.mediumImpact();
            service.completeChallenge();
          }
        }
      },
      onLongPress: () => service.deleteCurrentChallenge(),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            getTimeLeftWidget(),
            getProgressBar(),
            getDescriptionWidget(),
          ],
        ),
      ),
    );
  }

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
        ...((challenge != null && isCompleted) || (challenge == null && !service.allowNew))
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
                    text: timeLeftStr,
                    context: context,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.333),
                  ),
                ),
                const SizedBox(width: 16),
              ],
      ],
    );
  }

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

  Widget getProgressBar() {
    return SizedBox.fromSize(
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
                    border: Border.all(width: 2, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.075)),
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
                                duration: LongTransitionDuration(),
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
                              duration: ShortTransitionDuration(),
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
                  ? (service.allowNew ? 'Neue Challenge starten!' : timeLeftStr)
                  : '${challenge!.progress} / ${challenge!.target}',
              context: context,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget getIconRing() {
    var color = CI.blue.withOpacity(isCompleted ? 1 : math.max(progressPercentage, 0.25));
    var level = Level(value: 0, title: '', color: color);
    return AnimatedContainer(
      duration: ShortTransitionDuration(),
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
      child: AnimatedLevelRing(
        ringSize: 32,
        levels: [level, level, level, level, level, level, level],
        value: 0,
        color: color,
        icon: (challenge == null)
            ? Icons.question_mark
            : (challenge!.isWeekly ? Icons.emoji_events : Icons.military_tech),
        buildWithAnimation: isAnimatingRing,
      ),
    );
  }
}
