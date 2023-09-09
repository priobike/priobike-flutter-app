import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/challenges/views/challenges_profile/confetti_wrapper.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';

class MultipleUpgradesLvlUpDialog extends StatefulWidget {
  final Level newLevel;

  final List<ProfileUpgrade> upgrades;

  const MultipleUpgradesLvlUpDialog({
    Key? key,
    required this.newLevel,
    required this.upgrades,
  }) : super(key: key);
  @override
  State<MultipleUpgradesLvlUpDialog> createState() => _MultipleUpgradesLvlUpDialogState();
}

class _MultipleUpgradesLvlUpDialogState extends State<MultipleUpgradesLvlUpDialog> with SingleTickerProviderStateMixin {
  int? selectedUpgrade;

  void selectUpgrade(int index) async {
    setState(() => selectedUpgrade = index);
    await Future.delayed(ShortDuration());
    if (mounted) Navigator.of(context).pop(widget.upgrades.elementAt(selectedUpgrade!));
  }

  @override
  Widget build(BuildContext context) {
    return LevelUpDialog(
      content: Container(
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
            ...widget.upgrades
                .mapIndexed(
                  (i, upgrade) => UpgradeChoice(
                    visible: selectedUpgrade == null || selectedUpgrade == i,
                    onTap: () => selectUpgrade(i),
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(upgrade.icon, size: 32),
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
    );
  }
}

class UpgradeChoice extends StatelessWidget {
  final Function() onTap;
  final Widget content;
  final bool visible;
  const UpgradeChoice({
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
