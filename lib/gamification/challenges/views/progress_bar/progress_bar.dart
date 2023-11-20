import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/services/challenge_service.dart';
import 'package:priobike/gamification/challenges/services/challenges_profile_service.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/challenges/views/progress_bar/challenge_reward_dialog.dart';
import 'package:priobike/gamification/challenges/views/progress_bar/challenge_selection_dialog.dart';
import 'package:priobike/gamification/challenges/views/progress_bar/single_challenge_dialog.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/blink_animation.dart';
import 'package:priobike/gamification/common/views/countdown_timer.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:priobike/main.dart';

/// A Widget which displays the progress of a given challenge and relevant info about the challenge.
/// It also provides the option to get the rewards, if the challenge was completed.
class ChallengeProgressBar extends StatefulWidget {
  /// Determine whether to build the progress bar for weekly or for daily challenges.
  final bool isWeekly;

  const ChallengeProgressBar({
    super.key,
    required this.isWeekly,
  });
  @override
  State<ChallengeProgressBar> createState() => _ChallengeProgressBarState();
}

class _ChallengeProgressBarState extends State<ChallengeProgressBar> with SingleTickerProviderStateMixin {
  /// The service which manages and provides the user profile.
  late ChallengesProfileService _profileService;

  /// Get the weekly or daily challenge service, according to the isWeekly variable.
  ChallengeService get _service => widget.isWeekly ? getIt<WeeklyChallengeService>() : getIt<DailyChallengeService>();

  /// Get the challenge currently connected to the progress bar, or null if there is none.
  Challenge? get _challenge => _service.currentChallenge;

  /// The progress of completion of the challenge as a percentage value between 0 and 100.
  double get _progressPercentage => _challenge == null ? 1 : _challenge!.progress / _challenge!.target;

  /// Returns true, if the user completed the challenge.
  bool get _isCompleted => _challenge == null ? false : _progressPercentage >= 1;

  /// If there is no active challenge, and there are no available challenge choices, and the service does not allow
  /// the generation of a new challenge, this bar ist true and indicates, that a tap on the bar should do nothing.
  bool get _deactivateTap => _challenge == null && !_service.allowNew && _service.challengeChoices.isEmpty;

  /// The color representing the current level of the user.
  Color get _barColor => CI.radkulturRed; //levels.elementAt(_profileService.profile?.level ?? 0).color;

  /// Time where the challenge ends.
  DateTime get _endTime {
    var now = DateTime.now();
    if (widget.isWeekly) {
      return now.add(Duration(days: 8 - now.weekday)).copyWith(hour: 0, minute: 0, second: 0);
    } else {
      return now.add(const Duration(days: 1)).copyWith(hour: 0, minute: 0, second: 0);
    }
  }

  /// Return the type of the current challenge.
  get challengeType => _challenge!.isWeekly
      ? WeeklyChallengeType.values.elementAt(_challenge!.type)
      : DailyChallengeType.values.elementAt(_challenge!.type);

  @override
  void initState() {
    _profileService = getIt<ChallengesProfileService>();
    _profileService.addListener(update);
    _service.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    _service.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired
  void update() => {if (mounted) setState(() {})};

  /// Handle a tap on the progress bar.
  void _handleTap() async {
    // If there is a non-completed challenge, open dialog field containing information about the challenge.
    if (_challenge != null && !_isCompleted) {
      return showDialog(
        barrierColor: Colors.black.withOpacity(0.8),
        context: context,
        builder: (context) => SingleChallengeDialog(
          challenge: _challenge!,
          color: _barColor,
        ),
      );
    }
    // If there are a number of challenges, of which the user can chose from, open the challenge selection dialog.
    if (_service.challengeChoices.isNotEmpty) {
      await _showChallengeSelection(_service.challengeChoices);
    }
    // If the challenge has been completed, update it in the db and give haptic feedback again, as the user receives their rewards.
    else if (_isCompleted) {
      await showDialog(
        barrierColor: Colors.black.withOpacity(0.8),
        context: context,
        builder: (context) => ChallengeRewardDialog(color: _barColor, challenge: _challenge!),
      );
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
  }

  /// This function opens a dialog, where the user is shown their generated challenge, or is given a choice between
  /// a number of challenges, if multiple were generated.
  Future<void> _showChallengeSelection(List<Challenge> challenges) async {
    // The dialog returns an index of the selected challenge or null, if no selection was made.
    var result = await showDialog<int?>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: challenges.length == 1,
      builder: (BuildContext context) {
        if (challenges.length == 1) {
          return SingleChallengeDialog(
            challenge: challenges.first,
            color: _barColor,
          );
        } else {
          return ChallengeSelectionDialog(
            challenges: challenges,
            isWeekly: widget.isWeekly,
            color: _barColor,
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

  /// Returns a widget which displays the time the user has left for the challenge.
  Widget _getTimeLeftWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          Icons.timer,
          size: 16,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
        ),
        CountdownTimer(timestamp: _endTime),
        const SizedBox(width: 16),
      ],
    );
  }

  /// This widget returns the progress bar corresponding to the challenge state.
  Widget _getProgressBar() {
    return SizedBox.fromSize(
      size: const Size.fromHeight(48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: OnTapAnimation(
              scaleFactor: 0.95,
              onPressed: (_deactivateTap) ? null : _handleTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(32)),
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(32))),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _isCompleted ? 1 : _progressPercentage,
                          child: Container(
                            color: _challenge == null ? _barColor.withOpacity(_deactivateTap ? 0.2 : 0.5) : _barColor,
                          ),
                        ),
                      ),
                    ),
                    if (!_deactivateTap)
                      BlinkAnimation(
                        animate: _isCompleted,
                        scaleFactor: 1.025,
                        child: FractionallySizedBox(
                          widthFactor: _isCompleted ? 1 : _progressPercentage,
                          heightFactor: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(32)),
                              boxShadow: [
                                BoxShadow(
                                  color: _barColor.withOpacity(_isCompleted ? 0.8 : 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: BlinkAnimation(
                        animate: _isCompleted,
                        scaleFactor: 1.1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (_challenge == null)
                                  ? (widget.isWeekly ? CustomGameIcons.blank_trophy : CustomGameIcons.blank_medal)
                                  : getChallengeIcon(_challenge!),
                              size: 32,
                              color: _isCompleted ? Colors.white : Theme.of(context).colorScheme.onBackground,
                            ),
                            BoldContent(
                              text: _challenge == null
                                  ? _deactivateTap
                                      ? 'Challenge Abgeschlossen'
                                      : (widget.isWeekly ? 'Neue Wochenchallenge' : 'Neue Tageschallenge')
                                  : _isCompleted
                                      ? 'Belohnung Abholen'
                                      : '${StringFormatter.getRoundStrByChallengeType(
                                          _challenge!.progress,
                                          challengeType,
                                        )}/${StringFormatter.getRoundStrByChallengeType(
                                          _challenge!.target,
                                          challengeType,
                                        )} ${StringFormatter.getLabelForChallengeType(challengeType)}',
                              context: context,
                              color: _isCompleted ? Colors.white : Theme.of(context).colorScheme.onBackground,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_profileService.profile == null) return const SizedBox.shrink();
    if (widget.isWeekly && _profileService.profile!.level < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _getProgressBar(),
          const SizedBox(height: 4),
          _getTimeLeftWidget(),
        ],
      ),
    );
  }
}
