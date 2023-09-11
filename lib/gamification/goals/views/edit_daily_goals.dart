import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/goals/views/weekday_button.dart';
import 'package:priobike/main.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';

/// This widget enables the user to edit their daily goals.
class EditDailyGoalsView extends StatefulWidget {
  const EditDailyGoalsView({Key? key}) : super(key: key);

  @override
  State<EditDailyGoalsView> createState() => _EditDailyGoalsViewState();
}

class _EditDailyGoalsViewState extends State<EditDailyGoalsView> {
  /// The associated goals service.
  late GoalsService _goalsService;

  @override
  void initState() {
    _goalsService = getIt<GoalsService>();
    _goalsService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _goalsService.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  Widget build(BuildContext context) {
    var goals = _goalsService.dailyGoals;
    var distanceGoal = goals.distanceMetres / 1000;
    var durationGoal = goals.durationMinutes;
    var noDaysSelected = goals.numOfDays == 0;
    return Column(
      children: [
        const VSpace(),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: goals.weekdays
              .mapIndexed(
                (i, day) => WeekdayButton(
                  day: i,
                  onPressed: () {
                    goals.weekdays[i] = !goals.weekdays[i];
                    goals.weekdays = goals.weekdays;
                    _goalsService.updateDailyGoals(goals);
                  },
                  selected: day,
                ),
              )
              .toList(),
        ),
        const VSpace(),
        EditGoalWidget(
          title: 'Distanz',
          value: distanceGoal,
          min: 1,
          max: 80,
          stepSize: 1,
          valueLabel: 'km',
          onChanged: noDaysSelected
              ? null
              : (value) {
                  goals.distanceMetres = value * 1000;
                  _goalsService.updateDailyGoals(goals);
                },
        ),
        const VSpace(),
        EditGoalWidget(
          title: 'Fahrtzeit',
          value: durationGoal,
          min: 10,
          max: 600,
          stepSize: 10,
          valueLabel: 'min',
          onChanged: noDaysSelected
              ? null
              : (value) {
                  goals.durationMinutes = value;
                  _goalsService.updateDailyGoals(goals);
                },
        ),
        const VSpace(),
      ],
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
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(onChanged == null ? 0.1 : 0.2),
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
    return OnTabAnimation(
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
