import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/models.dart';
import 'package:priobike/game/view.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';

class NewChallengeDialog extends StatelessWidget {
  final List<Challenge> challenges;
  final bool isWeekly;

  const NewChallengeDialog({
    Key? key,
    required this.challenges,
    required this.isWeekly,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var lightmode = Theme.of(context).brightness == Brightness.light;
    var titlePrefix = challenges.length > 1 ? 'Wähle eine ' : 'Neue ';
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(lightmode ? 1 : 0.25),
              spreadRadius: 0,
              blurRadius: 50,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SmallHSpace(),
                  Expanded(
                    child: BoldContent(
                      text: titlePrefix + (isWeekly ? 'Wochenchallenge' : 'Tageschallenge'),
                      context: context,
                      textAlign: TextAlign.center,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                    ),
                  ),
                  const SmallHSpace(),
                ],
              ),
              ...challenges.map((challenge) => ChallengeWidget(challenge: challenge)),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BoldSmall(
                    text: 'Verbleibende Zeit: ${StringFormatter.getTimeLeftStr(challenges.first.closingTime)}',
                    context: context,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ChallengeWidget extends StatefulWidget {
  final Challenge challenge;
  const ChallengeWidget({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  State<ChallengeWidget> createState() => _ChallengeWidgetState();
}

class _ChallengeWidgetState extends State<ChallengeWidget> {
  void onTap() {}

  bool tapDown = false;

  @override
  Widget build(BuildContext context) {
    var color = CI.blue.withOpacity(1);
    var level = Level(value: 0, title: '', color: color);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        setState(() => tapDown = true);
      },
      onTapUp: (_) {
        setState(() => tapDown = false);
        Navigator.of(context).pop();
      },
      onTapCancel: () => setState(() => tapDown = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              color: tapDown ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
              blurRadius: tapDown ? 8 : 4,
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LevelRing(
                  levels: [level, level, level, level, level, level, level],
                  value: 0,
                  color: color,
                  icon: widget.challenge.isWeekly ? Icons.emoji_events : Icons.military_tech,
                  ringSize: 64,
                ),
                const SmallHSpace(),
                Expanded(
                  child: Small(
                    text: widget.challenge.description,
                    context: context,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BoldSmall(text: '+${widget.challenge.xp}XP', context: context),
                const SmallHSpace(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
