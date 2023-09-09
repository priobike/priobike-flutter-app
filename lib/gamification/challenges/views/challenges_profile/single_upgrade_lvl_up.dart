import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/profile_upgrade.dart';
import 'package:priobike/gamification/challenges/views/challenges_profile/confetti_wrapper.dart';
import 'package:priobike/gamification/common/models/level.dart';

class SingleUpgradeLvlUpDialog extends StatelessWidget {
  final Level newLevel;
  final ProfileUpgrade? upgrade;

  const SingleUpgradeLvlUpDialog({Key? key, required this.newLevel, required this.upgrade}) : super(key: key);

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
              text: 'Level ${levels.indexOf(newLevel)}',
              context: context,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            Header(
              text: newLevel.title,
              context: context,
              color: CI.blue,
              textAlign: TextAlign.center,
            ),
            const SmallVSpace(),
            if (upgrade != null) ...[
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
                        text: upgrade!.description,
                        context: context,
                        textAlign: TextAlign.center,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
