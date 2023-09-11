import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/goals/views/edit_goal_widget.dart';
import 'package:priobike/gamification/goals/views/weekday_button.dart';
import 'package:priobike/main.dart';

class EditDailyGoalsView extends StatefulWidget {
  const EditDailyGoalsView({Key? key}) : super(key: key);

  @override
  State<EditDailyGoalsView> createState() => _EditDailyGoalsViewState();
}

class _EditDailyGoalsViewState extends State<EditDailyGoalsView> {
  /// The associated goals service.
  late GoalsService _goalsService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

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

  @override
  Widget build(BuildContext context) {
    var goals = _goalsService.dailyGoals;
    var distanceGoal = goals.distanceMetres / 1000;
    var durationGoal = goals.durationMinutes;
    var noDaysSelected = goals.weekdays.where((day) => day).isEmpty;
    return Column(
      children: [
        const VSpace(),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: goals.weekdays
              .mapIndexed(
                (i, day) => WeekdayButton(
                  label: StringFormatter.getWeekStr(i),
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
          valueAsInt: false,
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
