import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/services/challenge_service.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/challenges/views/challenge_selection_dialog.dart';
import 'package:priobike/gamification/challenges/views/single_challenge_dialog.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/progress_ring.dart';
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
  Timer? _timer;

  /// This bool is true, if the progress bar has been tapped and needs to be animated.
  bool _onTapAnimation = false;

  /// This bool is true, if the progress bar has been tapped to collect a reward and the reward animation is shown.
  bool _completedAnimation = false;

  /// Animation Controller to controll the ring animation.
  late final AnimationController _ringController;

  /// This value determines the shadow spread of the challenge icon.
  /// It is used to create the pulsing animation for completed challenges.
  double _iconShadowSpred = 12;

  /// Get the weekly or daily challenge service, according to the isWeekly variable.
  ChallengeService get _service => widget.isWeekly ? getIt<WeeklyChallengeService>() : getIt<DailyChallengeService>();

  /// Get the challenge currently connected to the progress bar, or null if there is none.
  Challenge? get _challenge => _service.currentChallenge;

  /// The progress of completion of the challenge as a percentage value between 0 and 100.
  double get _progressPercentage => _challenge == null ? 0 : _challenge!.progress / _challenge!.target;

  /// Returns true, if the user completed the challenge.
  bool get _isCompleted => _progressPercentage >= 1;

  /// If there is no active challenge, and there are no available challenge choices, and the service does not allow
  /// the generation of a new challenge, this bar ist true and indicates, that a tap on the bar should do nothing.
  bool get _deactivateTap => _challenge == null && !_service.allowNew && _service.challengeChoices.isEmpty;

  /// Time where the challenge ends.
  DateTime get _endTime {
    var now = DateTime.now();
    if (widget.isWeekly) {
      return now.add(Duration(days: 8 - now.weekday)).copyWith(hour: 0, minute: 0, second: 0);
    } else {
      return now.add(const Duration(days: 1)).copyWith(hour: 0, minute: 0, second: 0);
    }
  }

  @override
  void initState() {
    _ringController = AnimationController(vsync: this, duration: MediumDuration(), value: 1);
    _startUpdateTimer();
    _service.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _endTimer();
    _service.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired. It restards the update timer and rebuilds the widget.
  void update() {
    if (_isCompleted) _startUpdateTimer();
    if (mounted) setState(() {});
  }

  /// Either start a timer which updates the time left every minute, or, if the challenge has been completed,
  /// start a timer that creates the pulsing animation by changing the icon shadow spread value periodically.
  void _startUpdateTimer() {
    _endTimer();
    if (_isCompleted) {
      _timer = Timer.periodic(
          MediumDuration(),
          (timer) => setState(() {
                _iconShadowSpred = (_iconShadowSpred == 0) ? 20 : 0;
              }));
    } else {
      _timer = Timer.periodic(
        const Duration(seconds: 10),
        (timer) => setState(() {}),
      );
    }
  }

  /// End any running timer.
  void _endTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Handle a tap on the progress bar.
  void _handleTap() async {
    // If there is a non-completed challenge, open dialog field containing information about the challenge.
    if (_challenge != null && !_isCompleted) {
      return showDialog(
        context: context,
        builder: (context) => SingleChallengeDialog(challenge: _challenge!, isWeekly: _challenge!.isWeekly),
      );
    }
    // Start and stop the ring and glowing animation of the progress bar and wait till the animation has finished.
    _ringController.reverse();
    setState(() => _onTapAnimation = true);
    if (_isCompleted) setState(() => _completedAnimation = true);
    await Future.delayed(MediumDuration()).then((_) => setState(() => _onTapAnimation = false));
    // If there are a number of challenges, of which the user can chose from, open the challenge selection dialog.
    if (_service.challengeChoices.isNotEmpty) {
      await _showChallengeSelection(_service.challengeChoices);
    }
    // If the challenge has been completed, update it in the db and give haptic feedback again, as the user receives their rewards.
    else if (_isCompleted) {
      await Future.delayed(MediumDuration()).then((_) {
        setState(() => _completedAnimation = false);
      });
      _service.completeChallenge();
      HapticFeedback.heavyImpact();
    }
    // If there is no challenge, but the service allows a new one, generate a new one.
    else if (_challenge == null && _service.allowNew) {
      var result = await _service.generateChallengeChoices();
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
          return ChallengeSelectionDialog(
            challenges: challenges,
            isWeekly: widget.isWeekly,
          );
        }
      },
    );
    // If there is only one challenge to chose from, select that challenge.
    if (challenges.length == 1) {
      _service.selectAndStartChallenge(0);
    }
    // If there are multiple challenges to chose from, select a challenge according to the users choice.
    else if (result != null) {
      _service.selectAndStartChallenge(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _getTimeLeftWidget(),
          _getProgressBar(),
        ],
      ),
    );
  }

  /// Returns a widget which displays the time the user has left for the challenge. It also displays a title, which
  /// depends on whether if the challenge is a daily or a weekly challenge. Additionally, the time left is only shown,
  /// if there is a displayed challenge, or if the user is allowed to create a new one.
  Widget _getTimeLeftWidget() {
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
        ...(_challenge != null && _isCompleted)
            ? []
            : [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.333),
                ),
                BoldSmall(
                  text: StringFormatter.getTimeLeftStr(_endTime),
                  context: context,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.333),
                ),
                const SizedBox(width: 16),
              ],
      ],
    );
  }

  /// This widget returns the progress bar corresponding to the challenge state.
  Widget _getProgressBar() {
    /*return AnimatedButton(
      scaleFactor: 0.95,
      onPressed: (deactivateTap) ? null : handleTap,*/
    return GestureDetector(
      onTap: (_deactivateTap) ? null : _handleTap,
      onLongPress: () => _service.deleteCurrentChallenge(),
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
                      children: (_challenge != null)
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
                                    widthFactor: _isCompleted ? 1 : _progressPercentage,
                                    child: Container(color: CI.blue),
                                  ),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: _isCompleted ? 1 : _progressPercentage,
                                heightFactor: 1,
                                child: AnimatedContainer(
                                  duration: LongDuration(),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CI.blue.withOpacity((_isCompleted && _completedAnimation) ? 1 : 0.3),
                                        blurRadius: 20,
                                        spreadRadius: (_isCompleted && _completedAnimation) ? 5 : 0,
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
                                    BoxShadow(color: CI.blue.withOpacity(_onTapAnimation ? 0.2 : 0), blurRadius: 20),
                                  ],
                                  gradient: LinearGradient(
                                    colors: [
                                      CI.blue.withOpacity(_deactivateTap ? 0.2 : (_onTapAnimation ? 0.8 : 0.5)),
                                      CI.blue.withOpacity(_deactivateTap ? 0.01 : (_onTapAnimation ? 0.2 : 0.05)),
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
              children: [_getIconRing()],
            ),
            Center(
              child: BoldSmall(
                text: (_challenge == null)
                    ? (_deactivateTap ? 'Challenge abgeschlossen' : 'Neue Challenge starten!')
                    : (_isCompleted)
                        ? 'Belohnung einsammeln'
                        : '${_challenge!.progress} / ${_challenge!.target}',
                context: context,
                color: _isCompleted ? Colors.white : Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget returns a small icon ring to be displayed inside of the progress bar.
  Widget _getIconRing() {
    var color = CI.blue.withOpacity(_isCompleted ? 1 : math.max(_progressPercentage, 0.25));
    return AnimatedContainer(
      duration: MediumDuration(),
      margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: ((_isCompleted && _completedAnimation) || _deactivateTap)
            ? []
            : [
                BoxShadow(
                  color: CI.blue.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: _isCompleted ? _iconShadowSpred : _iconShadowSpred * _progressPercentage,
                ),
              ],
      ),
      child: ProgressRing(
        ringSize: 32,
        content: Icon(
          (_challenge == null)
              ? (widget.isWeekly ? CustomGameIcons.blank_trophy : CustomGameIcons.blank_medal)
              : ChallengeGenerator.getChallengeIcon(_challenge!),
          size: 20,
          color: color,
        ),
        animationController: _ringController,
        ringColor: color,
        background: Theme.of(context).colorScheme.background,
      ),
    );
  }
}
