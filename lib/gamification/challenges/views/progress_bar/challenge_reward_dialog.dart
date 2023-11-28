import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/common/database/database.dart';

/// Dialog widget for when the user collects their reward for a challenge.
class ChallengeRewardDialog extends StatefulWidget {
  /// The challenge which has been completed by the user.
  final Challenge challenge;

  /// The color in which the reward should be shown.
  final Color color;

  const ChallengeRewardDialog({super.key, required this.color, required this.challenge});

  @override
  State<ChallengeRewardDialog> createState() => ChallengeRewardDialogState();
}

class ChallengeRewardDialogState extends State<ChallengeRewardDialog> with SingleTickerProviderStateMixin {
  /// Controller to display confetti behind the dialog.
  late final ConfettiController _confettiController;

  /// Animation controller to animate the dialog appearing.
  late final AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 5));
    _animationController.forward();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _confettiController.play();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            maximumSize: const Size(10, 10),
            minimumSize: const Size(10, 5),
            minBlastForce: 20,
            maxBlastForce: 40,
            numberOfParticles: 50,
            emissionFrequency: 0.1,
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: [widget.color.withOpacity(0.5)],
          ),
          ScaleTransition(
            scale: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.fastLinearToSlowEaseIn,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    getChallengeIcon(widget.challenge),
                    size: 212,
                    color: widget.color,
                  ),
                  Header(
                    text: '+${widget.challenge.xp} XP',
                    context: context,
                    color: Colors.white,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
