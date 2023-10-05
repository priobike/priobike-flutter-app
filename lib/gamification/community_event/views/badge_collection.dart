import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/community_event/views/badge.dart';

/// This view displays the badges the user has collected, which represent the achieved locations of the user.
class BadgeCollection extends StatelessWidget {
  final List<EventBadge> badges;

  const BadgeCollection({Key? key, required this.badges}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.light.copyWith(
              systemNavigationBarColor: Theme.of(context).colorScheme.background,
              systemNavigationBarIconBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: Theme.of(context).colorScheme.background,
              systemNavigationBarIconBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
            ),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SmallVSpace(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 0.5,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: AppBackButton(onPressed: () => Navigator.pop(context)),
                    ),
                    const HSpace(),
                    SubHeader(text: 'Deine Abzeichen', context: context)
                  ],
                ),
                const SmallVSpace(),
                ...badges
                    .map(
                      (badge) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(24),
                            color: Theme.of(context).colorScheme.surface),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            RewardBadge(color: CI.blue, size: 64, iconIndex: badge.icon, achieved: true),
                            Expanded(
                              child: Column(
                                children: [
                                  BoldSubHeader(text: badge.title, context: context),
                                  Content(text: StringFormatter.getDateStr(badge.achievedTimestamp), context: context),
                                ],
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
    );
  }
}
