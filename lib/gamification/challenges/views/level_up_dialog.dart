import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/challenges/services/challenge_profile_service.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:confetti/confetti.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/main.dart';

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
  Animation<double> get animation => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.fastLinearToSlowEaseIn,
        ),
      );

  List<ProfileUpgrade> get allowedUpgrades => getIt<ChallengeProfileService>().allowedUpgrades;

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
    await Future.delayed(ShortDuration());
    if (mounted) Navigator.of(context).pop(allowedUpgrades.elementAt(selectedUpgrade!));
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
                      text: 'Level ${levels.indexOf(widget.newLevel)}',
                      context: context,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    Header(
                      text: widget.newLevel.title,
                      context: context,
                      color: CI.blue,
                      textAlign: TextAlign.center,
                    ),
                    if (allowedUpgrades.length == 1) FixedUpgradeWidget(description: allowedUpgrades.first.description),
                    if (allowedUpgrades.length > 1)
                      ...allowedUpgrades
                          .mapIndexed(
                            (i, upgrade) => UpgradeSelectionWidget(
                              visible: selectedUpgrade == null || selectedUpgrade == i,
                              onTap: () => selectUpgrade(i),
                              content: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(CustomGameIcons.blank_trophy, size: 32),
                                  const SmallHSpace(),
                                  Expanded(
                                    child: BoldSmall(
                                      text: upgrade.description,
                                      context: context,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
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

class FixedUpgradeWidget extends StatelessWidget {
  final String description;

  const FixedUpgradeWidget({
    Key? key,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SmallVSpace(),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: BoldContent(
                text: 'Du bist ein Level aufgestiegen!',
                context: context,
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
            )
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: CI.blue,
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
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: BoldContent(
                  text: description,
                  context: context,
                  textAlign: TextAlign.center,
                  color: Colors.white,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class UpgradeSelectionWidget extends StatelessWidget {
  final Function() onTap;
  final Widget content;
  final bool visible;
  const UpgradeSelectionWidget({
    Key? key,
    required this.onTap,
    required this.content,
    required this.visible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: TinyDuration(),
      child: AnimatedButton(
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
          child: content,
        ),
      ),
    );
  }
}
