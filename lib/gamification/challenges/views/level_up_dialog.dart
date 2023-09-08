import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:confetti/confetti.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';

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

  int? selectedUpgrade;

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

  void selectUpgrade(int index) async {
    setState(() => selectedUpgrade = index);
    await Future.delayed(TinyDuration());
    if (mounted) Navigator.of(context).pop(selectedUpgrade);
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
                      visible: selectedUpgrade == null || selectedUpgrade == 0,
                      onTap: () => selectUpgrade(0),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          BoldSmall(text: 'Eine Wochenchallenge mehr', context: context),
                          const SmallVSpace(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(CustomGameIcons.blank_trophy, size: 32),
                              SmallVSpace(),
                              Icon(Icons.arrow_forward, size: 32),
                              SmallVSpace(),
                              Icon(CustomGameIcons.blank_trophy, size: 32),
                              Icon(CustomGameIcons.blank_trophy, size: 32),
                            ],
                          ),
                        ],
                      ),
                    ),
                    UpgradeWidget(
                      visible: selectedUpgrade == null || selectedUpgrade == 1,
                      onTap: () => selectUpgrade(1),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          BoldSmall(text: 'Eine Tageschallenge mehr', context: context),
                          const SmallVSpace(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(CustomGameIcons.blank_medal, size: 32),
                              SmallVSpace(),
                              Icon(Icons.arrow_forward, size: 32),
                              SmallVSpace(),
                              Icon(CustomGameIcons.blank_medal, size: 32),
                              Icon(CustomGameIcons.blank_medal, size: 32),
                            ],
                          ),
                        ],
                      ),
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
  final Function() onTap;
  final Widget content;
  final bool visible;
  const UpgradeWidget({
    Key? key,
    required this.onTap,
    required this.content,
    required this.visible,
  }) : super(key: key);

  @override
  State<UpgradeWidget> createState() => _UpgradeWidgetState();
}

class _UpgradeWidgetState extends State<UpgradeWidget> {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      visible: widget.visible,
      child: AnimatedButton(
        onPressed: !widget.visible ? null : widget.onTap,
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
          child: widget.content,
        ),
      ),
    );
  }
}
