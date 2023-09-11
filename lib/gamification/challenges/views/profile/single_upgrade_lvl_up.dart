import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/challenges/views/profile/lvl_up_dialog.dart';
import 'package:priobike/gamification/common/models/level.dart';

/// Dialog widget for when the user reached a new level in their challenge profile and gained a single profile upgrade.
class SingleUpgradeLvlUpDialog extends StatelessWidget {
  /// The new level of the user.
  final Level newLevel;

  /// The upgrade gained by the level up.
  final ProfileUpgrade upgrade;

  const SingleUpgradeLvlUpDialog({Key? key, required this.newLevel, required this.upgrade}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LevelUpDialog(
      newLevel: newLevel,
      content: Container(
        padding: const EdgeInsets.all(12),
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
    );
  }
}
