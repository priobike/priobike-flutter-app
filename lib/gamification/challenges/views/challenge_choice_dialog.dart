import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';

/// Dialog widget to pop up after one or multiple challenges were generated.
class ChallengeChoiceDialog extends StatefulWidget {
  final List<Challenge> challenges;
  final bool isWeekly;

  const ChallengeChoiceDialog({
    Key? key,
    required this.challenges,
    required this.isWeekly,
  }) : super(key: key);
  @override
  State<ChallengeChoiceDialog> createState() => _ChallengeChoiceDialogState();
}

class _ChallengeChoiceDialogState extends State<ChallengeChoiceDialog> with SingleTickerProviderStateMixin {
  int? selectedChallenge;

  void selectChallenge(int index) async {
    setState(() => selectedChallenge = index);
    await Future.delayed(ShortDuration());
    if (mounted) Navigator.of(context).pop(selectedChallenge);
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            BoldContent(
              text: 'Wähle eine ${widget.isWeekly ? 'Wochenchallenge' : 'Tageschallenge'}',
              context: context,
              textAlign: TextAlign.center,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
            ...widget.challenges.mapIndexed(
              (i, challenge) => ChallengeWidget(
                challenge: challenge,
                onTap: () => selectChallenge(i),
                visible: selectedChallenge == null || selectedChallenge == i,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BoldSmall(
                  text: 'Verbleibende Zeit: ${StringFormatter.getTimeLeftStr(widget.challenges.first.closingTime)}',
                  context: context,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ChallengeWidget extends StatelessWidget {
  final bool visible;
  final Function() onTap;
  final Challenge challenge;
  const ChallengeWidget({
    Key? key,
    required this.challenge,
    required this.onTap,
    this.visible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: TinyDuration(),
      child: AnimatedButton(
        onPressed: visible ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
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
              Icon(
                ChallengeGenerator.getChallengeIcon(challenge),
                size: 64,
                color: CI.blue,
              ),
              const SmallHSpace(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Small(
                      text: challenge.description,
                      context: context,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        BoldSmall(text: '+${challenge.xp}XP', context: context),
                      ],
                    ),
                  ],
                ),
              ),
              const SmallHSpace(),
            ],
          ),
        ),
      ),
    );
  }
}
