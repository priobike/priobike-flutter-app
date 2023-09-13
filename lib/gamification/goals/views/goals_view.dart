import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/views/edit_daily_goals.dart';
import 'package:priobike/gamification/goals/views/edit_route_goals.dart';

/// This view gives the user to open widgets to edit their daily and route goals by pressing on corresponding buttons.
class GoalsView extends StatefulWidget {
  const GoalsView({Key? key}) : super(key: key);

  @override
  State<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView> {
  /// Whether to show the daily goals widget.
  bool _showEditDailyGoals = false;

  /// Whether to show the route goals widget.
  bool _showEditRouteGoals = false;

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
                selected: _showEditDailyGoals,
                onPressed: () async {
                  setState(() {
                    _showEditDailyGoals = !_showEditDailyGoals;
                    _showEditRouteGoals = false;
                  });
                },
              ),
              const SmallHSpace(),
              CustomIconButton(
                icon: Icons.map,
                label: 'Routenziele',
                selected: _showEditRouteGoals,
                onPressed: () async {
                  setState(() {
                    _showEditRouteGoals = !_showEditRouteGoals;
                    _showEditDailyGoals = false;
                  });
                },
              ),
            ],
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
            sizeCurve: Curves.easeInOutCubic,
            duration: const MediumDuration(),
            firstChild: Container(),
            secondChild: const EditDailyGoalsView(),
            crossFadeState: _showEditDailyGoals ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
            sizeCurve: Curves.easeInOutCubic,
            duration: const MediumDuration(),
            firstChild: Container(),
            secondChild: const EditRouteGoalsView(),
            crossFadeState: _showEditRouteGoals ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}

/// Custom button design to either open or close a goals edit widget.
class CustomIconButton extends StatelessWidget {
  /// Icon on the left side of the button.
  final IconData icon;

  /// Label on the button.
  final String label;

  /// Whether the button is selected, which means it is displayed in blue.
  final bool selected;

  /// Callback function for when the button is pressed.
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
              height: 1,
            ),
          ],
        ),
      ),
    );
  }
}
