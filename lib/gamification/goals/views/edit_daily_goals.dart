import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';
import 'package:priobike/gamification/common/views/dialog_button.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:priobike/gamification/goals/models/daily_goals.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/goals/views/weekday_button.dart';
import 'package:priobike/main.dart';

/// This dialog enables the user to edit their daily goals.
class EditDailyGoalsDialog extends StatefulWidget {
  const EditDailyGoalsDialog({Key? key}) : super(key: key);

  @override
  State<EditDailyGoalsDialog> createState() => _EditDailyGoalsDialogState();
}

class _EditDailyGoalsDialogState extends State<EditDailyGoalsDialog> {
  /// Default goals to set the values to when no user goals exist.
  DailyGoals get _defaultGoals => DailyGoals.defaultGoals;

  /// The users daily distance goals.
  late double _distance;

  /// The users daily duration goals.
  late double _duration;

  /// The weekdays on which the goals should be implemented.
  late List<bool> _weekdays;

  @override
  void initState() {
    var goals = getIt<GoalsService>().dailyGoals;
    _distance = goals?.distanceMetres ?? _defaultGoals.distanceMetres;
    _duration = goals?.durationMinutes ?? _defaultGoals.durationMinutes;
    _weekdays = List.from(goals?.weekdays ?? _defaultGoals.weekdays);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var noDaysSelected = _weekdays.where((day) => day).isEmpty;
    return CustomDialog(
      horizontalMargin: 16,
      content: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SmallVSpace(),
            BoldSubHeader(
              text: 'Möchtest du dir an bestimmten Tagen eine Distanz oder Zeit vornehmen?',
              context: context,
              textAlign: TextAlign.center,
            ),
            const SmallVSpace(),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _weekdays
                  .mapIndexed(
                    (i, day) => WeekdayButton(
                      day: i,
                      onPressed: () => setState(() => _weekdays[i] = !_weekdays[i]),
                      selected: day,
                    ),
                  )
                  .toList(),
            ),
            const VSpace(),
            EditGoalWidget(
              title: 'Distanz',
              value: _distance / 1000,
              min: 1,
              max: 80,
              stepSize: 1,
              valueLabel: 'km',
              onChanged: noDaysSelected ? null : (value) => setState(() => _distance = value * 1000),
            ),
            const VSpace(),
            EditGoalWidget(
              title: 'Fahrtzeit',
              value: _duration,
              min: 10,
              max: 600,
              stepSize: 10,
              valueLabel: 'min',
              onChanged: noDaysSelected ? null : (value) => setState(() => _duration = value),
            ),
            const VSpace(),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SmallHSpace(),
                CustomDialogButton(
                  label: 'Abbrechen',
                  onPressed: () => Navigator.of(context).pop(),
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                ),
                const SmallHSpace(),
                CustomDialogButton(
                  label: 'Speichern',
                  onPressed: () {
                    DailyGoals? goals;
                    if (!noDaysSelected) {
                      goals = DailyGoals(_distance, _duration, _weekdays);
                    }
                    getIt<GoalsService>().updateDailyGoals(goals);
                    Navigator.of(context).pop();
                  },
                  color: CI.radkulturRed,
                ),
                const SmallHSpace(),
              ],
            ),
            const SmallVSpace(),
          ],
        ),
      ),
    );
  }
}

/// Widget to edit a given goal value.
class EditGoalWidget extends StatelessWidget {
  /// Title to describe the goal.
  final String title;

  /// Current value of the goal.
  final double value;

  /// Min allowed value.
  final double min;

  /// Max allowed value.
  final double max;

  /// Step size to edit the goal value with.
  final double stepSize;

  /// Label of the goal value.
  final String valueLabel;

  /// Callback for when the goal value is changed.
  final Function(double)? onChanged;

  const EditGoalWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.stepSize,
    required this.valueLabel,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.025),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          EditButton(
            icon: Icons.remove,
            onPressed: (onChanged == null || value <= min) ? null : () => onChanged!(value - stepSize),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BoldSubHeader(
                      text: value.toInt().toString(),
                      context: context,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(onChanged == null ? 0.5 : 1),
                    ),
                    const SizedBox(width: 4),
                    BoldContent(
                      text: valueLabel,
                      context: context,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(onChanged == null ? 0.5 : 1),
                    ),
                  ],
                ),
                BoldSmall(
                  text: title,
                  context: context,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(onChanged == null ? 0.3 : 0.5),
                )
              ],
            ),
          ),
          EditButton(
            icon: Icons.add,
            onPressed: (onChanged == null || value >= max) ? null : () => onChanged!(value + stepSize),
          ),
        ],
      ),
    );
  }
}

/// Edit button to either increase or decrease a value.
class EditButton extends StatelessWidget {
  /// Icon the button should hold. (Normally either a plus or a minus)
  final IconData icon;

  /// Callback for when the button is pressed.
  final Function()? onPressed;

  const EditButton({Key? key, required this.icon, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool disable = onPressed == null;
    return OnTapAnimation(
      scaleFactor: 0.85,
      blockFastClicking: false,
      onPressed: onPressed,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(disable ? 0.05 : 0.1),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(disable ? 0.25 : 1),
          ),
        ),
      ),
    );
  }
}
