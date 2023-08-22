import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/models.dart';
import 'package:priobike/game/view.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/hub/challenges/services/challenges_service.dart';
import 'package:priobike/gamification/hub/challenges/views/challenge_goals.dart';
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
        } else {
          await AppDatabase.instance.challengesDao.clearDatabase();
          _settingsService.setChallengeGoals(null);
        }
      },
      content: Column(
        children: _settingsService.challengeGoalsSet
            ? [
                ChallengeProgressBar(service: getIt<WeeklyChallengeService>(), title: 'Wochenchallenge:'),
                ChallengeProgressBar(service: getIt<DailyChallengeService>(), title: 'Tageschallenge:'),
              ]
            : [getNoGoalsWidget()],
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
  final ChallengeService service;

  final String title;

  const ChallengeProgressBar({
    Key? key,
    required this.service,
    required this.title,
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

  DateTime now = DateTime.now();

  ChallengeService get service => widget.service;

  Challenge? get challenge => service.currentChallenge;

  /// Time left till the challenge ends.
  Duration get timeLeft =>
      challenge?.end.difference(now) ??
      now.copyWith(hour: 0, minute: 0, second: 0).add(const Duration(days: 1)).difference(now);

  /// The progress of completion of the challenge as a percentage value between 0 and 100.
  double get progressPercentage => challenge == null ? 0 : challenge!.progress / challenge!.target;

  /// Returns true, if the user completed the challenge.
  bool get isCompleted => progressPercentage >= 1;

  /// Returns a string describing how much time the user has left for a challenge.
  String get timeLeftStr {
    var result = '';
    if (timeLeft.inDays > 0) result += '${timeLeft.inDays} Tage ';
    var formatter = NumberFormat('00');
    result += '${formatter.format(timeLeft.inHours % 24)}:${formatter.format(timeLeft.inMinutes % 60)}h';
    return result;
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

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
    if (progressPercentage >= 1) {
      timer = Timer.periodic(
          ShortTransitionDuration(),
          (timer) => setState(() {
                iconShadowSpred = (iconShadowSpred == 0) ? 20 : 0;
              }));
    } else {
      timer = Timer.periodic(
        const Duration(seconds: 10),
        (timer) => setState(() => now = DateTime.now()),
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
      onTap: () => service.generateChallenge(),
      onLongPress: () => service.deleteCurrentChallenge(),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            getTimeLeft(),
            getProgressBar(),
            getDescription(),
          ],
        ),
      ),
    );
  }

  Widget getTimeLeft() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16),
            child: BoldSmall(
              text: widget.title,
              context: context,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ),
        ...((challenge == null)
            ? const [SizedBox(height: 16)]
            : [
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
                const SizedBox(width: 16),
              ])
      ],
    );
  }

  Widget getDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Small(
              text: challenge?.description ?? '',
              context: context,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              maxLines: 3,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget getProgressBar() {
    return SizedBox.fromSize(
      size: const Size.fromHeight(48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
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
                                  decoration: BoxDecoration(
                                    gradient: challenge == null
                                        ? LinearGradient(
                                            colors: [CI.blue.withOpacity(0.5), CI.blue.withOpacity(0.05)],
                                          )
                                        : null,
                                    color: challenge == null
                                        ? null
                                        : Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                                  ),
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
                ),
                Row(
                  children: [
                    Column(
                      children: [
                        Expanded(child: Container()),
                        getIconRing(),
                        Expanded(child: Container()),
                      ],
                    ),
                  ],
                ),
                Center(
                  child: BoldSmall(
                    text: (challenge == null)
                        ? 'Neue Challenge starten!'
                        : '${challenge!.progress} / ${challenge!.target} ${challenge!.valueLabel}',
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
    );
  }

  Widget getIconRing() {
    var color = CI.blue.withOpacity(isCompleted ? 1 : math.max(progressPercentage, 0.25));
    var level = Level(value: 0, title: '', color: color);
    return AnimatedContainer(
      duration: ShortTransitionDuration(),
      margin: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CI.blue.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: isCompleted ? iconShadowSpred : iconShadowSpred * progressPercentage,
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
          levels: [level, level, level, level, level, level, level],
          value: 0,
          color: color,
          icon: (challenge == null)
              ? Icons.question_mark
              : challenge!.isWeekly
                  ? Icons.emoji_events
                  : Icons.military_tech,
          buildWithAnimation: animateLevelRing,
        ),
      ),
    );
  }
}
