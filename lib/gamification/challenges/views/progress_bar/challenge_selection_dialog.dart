import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';

/// Dialog widget to pop up after multiple challenges were generated, to give the user the option to select one of them.
class ChallengeSelectionDialog extends StatefulWidget {
  /// The list of selectable challenges.
  final List<Challenge> challenges;

  /// Whether the challenges are weekly, or daily challenges.
  final bool isWeekly;

  /// An accent color for the challenges.
  final Color color;

  const ChallengeSelectionDialog({
    Key? key,
    required this.challenges,
    required this.isWeekly,
    required this.color,
  }) : super(key: key);
  @override
  State<ChallengeSelectionDialog> createState() => _ChallengeSelectionDialogState();
}

class _ChallengeSelectionDialogState extends State<ChallengeSelectionDialog> with SingleTickerProviderStateMixin {
  /// The index of the challenge selected by the user.
  int? _selectedChallenge;

  /// Select one out of the challenges, make the other choices disappear and close the dialog after half a second.
  void _selectChallenge(int index) async {
    setState(() => _selectedChallenge = index);
    await Future.delayed(const MediumDuration());
    if (mounted) Navigator.of(context).pop(_selectedChallenge);
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      backgroundColor: Colors.transparent,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...widget.challenges.mapIndexed(
            (i, challenge) => ChallengeWidget(
              challenge: challenge,
              onTap: () => _selectChallenge(i),
              visible: _selectedChallenge == null || _selectedChallenge == i,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// This widget displays a single challenge, to be selected by the user.
class ChallengeWidget extends StatelessWidget {
  /// Whether the widget should be visible.
  final bool visible;

  /// What to do, when the widget is tapped on.
  final Function() onTap;

  /// The challenge represented by the widget.
  final Challenge challenge;

  /// An accent color for the challenges.
  final Color color;

  const ChallengeWidget({
    Key? key,
    required this.challenge,
    required this.onTap,
    this.visible = true,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const ShortDuration(),
      child: OnTapAnimation(
        onPressed: visible ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            border: Border.all(
              width: 0.5,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                blurRadius: 4,
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 4),
                    SubHeader(
                      text: challenge.description,
                      context: context,
                      textAlign: TextAlign.center,
                      height: 1.1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          getChallengeIcon(challenge),
                          size: 48,
                          color: color.withOpacity(0.75),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${challenge.xp} XP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'HamburgSans',
                              fontSize: 28,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              color: color.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
