import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/challenges/models/challenge_goals.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/views/edit_daily_goals.dart';
import 'package:priobike/gamification/goals/views/edit_route_goals.dart';
import 'package:priobike/main.dart';

class GoalsView extends StatefulWidget {
  const GoalsView({Key? key}) : super(key: key);

  @override
  State<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView> {
  bool showEditDailyGoals = false;

  bool showEditRouteGoals = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              CustomIconButton(
                icon: CustomGameIcons.goals,
                label: 'Tagesziele',
                selected: showEditDailyGoals,
                onPressed: () async {
                  setState(() {
                    showEditDailyGoals = !showEditDailyGoals;
                    showEditRouteGoals = false;
                  });
                },
              ),
              const SmallHSpace(),
              CustomIconButton(
                icon: Icons.map,
                label: 'Routenziele',
                selected: showEditRouteGoals,
                onPressed: () async {
                  setState(() {
                    showEditRouteGoals = !showEditRouteGoals;
                    showEditDailyGoals = false;
                  });
                },
              ),
            ],
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
            sizeCurve: Curves.easeInOutCubic,
            duration: ShortDuration(),
            firstChild: Container(),
            secondChild: const EditDailyGoalsView(),
            crossFadeState: showEditDailyGoals ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
            sizeCurve: Curves.easeInOutCubic,
            duration: ShortDuration(),
            firstChild: Container(),
            secondChild: const EditRouteGoalsView(),
            crossFadeState: showEditRouteGoals ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;

  final String label;

  final bool selected;

  final Function() onPressed;

  const CustomIconButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tile(
        splash: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
        fill: selected ? CI.blue : Colors.transparent,
        padding: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(24),
        onPressed: onPressed,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? Colors.white : Theme.of(context).colorScheme.onBackground,
            ),
            const SmallHSpace(),
            BoldContent(
              text: label,
              context: context,
              color: selected ? Colors.white : Theme.of(context).colorScheme.onBackground,
            ),
          ],
        ),
      ),
    );
  }
}
