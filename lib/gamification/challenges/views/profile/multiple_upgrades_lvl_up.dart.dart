import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/challenges/views/profile/lvl_up_dialog.dart';
import 'package:priobike/gamification/challenges/models/level.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';

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
    await Future.delayed(const MediumDuration());
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
                    color: widget.newLevel.color,
                  ))
              .toList(),
        ],
      ),
    );
  }
}

/// This is a clickable widget displaying an upgrade the user can apply to their challenge profile.
class UpgradeChoice extends StatelessWidget {
  /// Callback for when the choice is selected.
  final Function()? onTap;

  /// The choice displayed by this widget.
  final ProfileUpgrade upgrade;

  /// Whether the choice should be visible for the user.
  final bool visible;

  /// Background color of the widget.
  final Color color;

  const UpgradeChoice({
    Key? key,
    required this.onTap,
    required this.upgrade,
    required this.visible,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const ShortDuration(),
      child: OnTapAnimation(
        onPressed: visible ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.75),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
