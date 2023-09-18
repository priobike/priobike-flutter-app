import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:priobike/gamification/goals/views/edit_daily_goals.dart';
import 'package:priobike/gamification/goals/views/edit_route_goals.dart';

/// This view gives the user to open dialogs to edit their daily and route goals by pressing on corresponding buttons.
class GoalsView extends StatelessWidget {
  const GoalsView({Key? key}) : super(key: key);

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
                onPressed: () => showDialog(context: context, builder: (context) => const EditDailyGoalsDialog()),
              ),
              const SmallHSpace(),
              CustomIconButton(
                icon: Icons.map,
                label: 'Routenziele',
                onPressed: () => showDialog(context: context, builder: (context) => const EditRouteGoalsDialog()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom button design to either open or close a goals edit dialog.
class CustomIconButton extends StatelessWidget {
  /// Icon on the left side of the button.
  final IconData icon;

  /// Label on the button.
  final String label;

  /// Callback function for when the button is pressed.
  final Function() onPressed;

  const CustomIconButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OnTapAnimation(
        onPressed: onPressed,
        child: Tile(
          fill: Colors.transparent,
          padding: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(24),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              const SmallHSpace(),
              BoldContent(
                text: label,
                context: context,
                color: Theme.of(context).colorScheme.onBackground,
                height: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
