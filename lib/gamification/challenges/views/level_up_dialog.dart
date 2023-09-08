import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:confetti/confetti.dart';

/// Dialog widget to pop up after one or multiple challenges were generated.
class LevelUpDialog extends StatefulWidget {
  final Level newLevel;

  const LevelUpDialog({
    Key? key,
    required this.newLevel,
  }) : super(key: key);
  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> with SingleTickerProviderStateMixin {
  /// Animation controller to animate the dialog appearing.
  late final AnimationController _animationController;

  late final ConfettiController _confettiController;

  /// Animation to
  Animation<double> get animation => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastLinearToSlowEaseIn,
      ));

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: ShortDuration());
    _animationController.forward();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _confettiController.play();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var lightmode = Theme.of(context).brightness == Brightness.light;
    return Stack(
      alignment: Alignment.center,
      children: [
        ConfettiWidget(
          maximumSize: const Size(15, 10),
          minimumSize: const Size(10, 5),
          minBlastForce: 20,
          maxBlastForce: 40,
          numberOfParticles: 40,
          emissionFrequency: 0.1,
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          colors: const [CI.blue],
        ),
        ScaleTransition(
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SmallVSpace(),
                    BoldContent(
                      text: 'Level 1',
                      context: context,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                    ),
                    Header(
                      text: widget.newLevel.title,
                      context: context,
                      color: CI.blue,
                    ),
                    const SmallVSpace(),
                    UpgradeWidget(
                      description: 'Wir müssen das halt alle irgendwann lernen, ganz erhlich, würd ich mal sagen',
                      onTap: () {},
                    ),
                    UpgradeWidget(
                      description: 'Upgrades sind nicht alles in diesem Lebel',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UpgradeWidget extends StatefulWidget {
  final Function onTap;
  final String description;
  const UpgradeWidget({
    Key? key,
    required this.description,
    required this.onTap,
  }) : super(key: key);

  @override
  State<UpgradeWidget> createState() => _UpgradeWidgetState();
}

class _UpgradeWidgetState extends State<UpgradeWidget> {
  bool tapDown = false;

  @override
  Widget build(BuildContext context) {
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
              color: tapDown ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
              blurRadius: tapDown ? 8 : 4,
            )
          ],
        ),
        child: Row(
          children: [Expanded(child: Content(text: widget.description, context: context))],
        ),
      ),
    );
  }
}
