import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/challenges/views/challenges_profile/lvl_up_dialog.dart';
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
      newLevel: widget.newLevel,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...widget.upgrades
              .mapIndexed((i, upgrade) => UpgradeChoice(
                    visible: selectedUpgrade == null || selectedUpgrade == i,
                    onTap: selectedUpgrade == i ? null : () => selectUpgrade(i),
                    upgrade: upgrade,
                  ))
              .toList(),
        ],
      ),
    );
  }
}

class UpgradeChoice extends StatelessWidget {
  final Function()? onTap;
  final ProfileUpgrade upgrade;
  final bool visible;
  const UpgradeChoice({
    Key? key,
    required this.onTap,
    required this.upgrade,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(upgrade.icon, size: 40, color: Colors.white),
              Expanded(
                child: BoldContent(
                  text: upgrade.description,
                  context: context,
                  textAlign: TextAlign.center,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
