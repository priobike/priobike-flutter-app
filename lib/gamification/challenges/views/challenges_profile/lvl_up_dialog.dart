import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';

class LevelUpDialog extends StatefulWidget {
  final Level newLevel;

  final Widget? content;

  const LevelUpDialog({Key? key, required this.newLevel, this.content}) : super(key: key);

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _confettiController.play();
    super.initState();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
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
      CustomDialog(
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SmallVSpace(),
              BoldContent(
                text: 'Du bist ein Level aufgestiegen!',
                context: context,
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.onBackground,
                height: 1,
              ),
              const SmallVSpace(),
              Header(
                text: widget.newLevel.title,
                context: context,
                color: widget.newLevel.color,
                textAlign: TextAlign.center,
              ),
              BoldSubHeader(
                text: 'Level ${levels.indexOf(widget.newLevel)}',
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                height: 1,
              ),
              if (widget.content != null) widget.content!,
              const SmallVSpace(),
            ],
          ),
        ),
      ),
    ]);
  }
}
