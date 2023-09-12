import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';

/// Dialog which displays a single challenge to the user.
class SingleChallengeDialog extends StatelessWidget {
  /// The challenge in question.
  final Challenge challenge;

  /// An accent color for the challenge.
  final Color color;

  const SingleChallengeDialog({
    Key? key,
    required this.challenge,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            BoldSubHeader(
              text: challenge.isWeekly ? 'Wochenchallenge' : 'Tageschallenge',
              context: context,
              textAlign: TextAlign.center,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(1),
            ),
            const SmallVSpace(),
            Row(
              children: [
                Expanded(
                  child: Content(
                    text: challenge.description,
                    context: context,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SmallVSpace(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  ChallengeGenerator.getChallengeIcon(challenge),
                  size: 60,
                  color: color.withOpacity(0.75),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Header(
                    text: '${challenge.xp} XP',
                    context: context,
                    height: 1,
                    color: color.withOpacity(0.75),
                  ),
                ),
              ],
            ),
            const SmallVSpace(),
          ],
        ),
      ),
    );
  }
}
