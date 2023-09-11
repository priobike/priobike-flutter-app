import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/challenges/views/profile/lvl_up_dialog.dart';
import 'package:priobike/gamification/common/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';

/// Dialog widget for when the user reached a new level in their challenge profile
/// and has the option to apply an upgrade out of multiple options.
class MultipleUpgradesLvlUpDialog extends StatefulWidget {
  /// The new level of the user.
  final Level newLevel;

  /// The upgrade options the user has.
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
  /// Index of the upgrade selected by the user.
  int? _selectedUpgrade;

  /// Update the selected upgrade and close the dialog after a short time.
  void _selectUpgrade(int index) async {
    setState(() => _selectedUpgrade = index);
    await Future.delayed(MediumDuration());
    if (mounted) Navigator.of(context).pop(widget.upgrades.elementAt(_selectedUpgrade!));
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
                    visible: _selectedUpgrade == null || _selectedUpgrade == i,
                    onTap: _selectedUpgrade == i ? null : () => _selectUpgrade(i),
                    upgrade: upgrade,
                  ))
              .toList(),
        ],
      ),
    );
  }
}

/// This is a clickable widget displaying an upgrade the user can apply to their challenge profile.
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
      duration: ShortDuration(),
      child: OnTabAnimation(
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
