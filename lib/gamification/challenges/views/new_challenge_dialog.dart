import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/level_ring.dart';

/// Dialog widget to pop up after one or multiple challenges were generated.
class NewChallengeDialog extends StatefulWidget {
  final List<Challenge> challenges;
  final bool isWeekly;

  const NewChallengeDialog({
    Key? key,
    required this.challenges,
    required this.isWeekly,
  }) : super(key: key);
  @override
  State<NewChallengeDialog> createState() => _NewChallengeDialogState();
}

class _NewChallengeDialogState extends State<NewChallengeDialog> with SingleTickerProviderStateMixin {
  /// Animation controller to animate the dialog appearing.
  late final AnimationController _animationController;

  /// Animation to
  Animation<double> get animation => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastLinearToSlowEaseIn,
      ));

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: ShortAnimationDuration());
    _animationController.forward();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var lightmode = Theme.of(context).brightness == Brightness.light;
    var titlePrefix = widget.challenges.length > 1 ? 'Wähle eine ' : 'Neue ';
    return ScaleTransition(
      scale: animation,
      child: Center(
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
                        text: titlePrefix + (widget.isWeekly ? 'Wochenchallenge' : 'Tageschallenge'),
                        context: context,
                        textAlign: TextAlign.center,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                    const SmallHSpace(),
                  ],
                ),
                ...widget.challenges.mapIndexed((i, challenge) => ChallengeWidget(
                      challenge: challenge,
                      onTap: () {
                        Navigator.of(context).pop(i);
                      },
                    )),
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
        ),
      ),
    );
  }
}

class ChallengeWidget extends StatefulWidget {
  final Function onTap;
  final Challenge challenge;
  const ChallengeWidget({
    Key? key,
    required this.challenge,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ChallengeWidget> createState() => _ChallengeWidgetState();
}

class _ChallengeWidgetState extends State<ChallengeWidget> {
  bool tapDown = false;

  @override
  Widget build(BuildContext context) {
    var color = CI.blue.withOpacity(1);
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        setState(() => tapDown = true);
      },
      onTapUp: (_) {
        setState(() => tapDown = false);
        widget.onTap();
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
                  ringColor: color,
                  iconColor: color,
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
