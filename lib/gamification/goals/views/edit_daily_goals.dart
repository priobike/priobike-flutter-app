import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
import 'package:priobike/gamification/goals/views/edit_goal_widget.dart';
import 'package:priobike/main.dart';

class EditDailyGoalsView extends StatefulWidget {
  const EditDailyGoalsView({Key? key}) : super(key: key);

  @override
  State<EditDailyGoalsView> createState() => _EditDailyGoalsViewState();
}

class _EditDailyGoalsViewState extends State<EditDailyGoalsView> {
  /// The associated goals service.
  late UserGoalsService _goalsService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    _goalsService = getIt<UserGoalsService>();
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
    return Column(
      children: [
        const VSpace(),
        EditGoalWidget(
          title: 'Distanz',
          value: distanceGoal,
          min: 0.5,
          max: 40,
          stepSize: 0.5,
          valueLabel: 'km',
          onChanged: (value) {
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
          onChanged: (value) {
            goals.durationMinutes = value;
            _goalsService.updateDailyGoals(goals);
          },
        ),
        const VSpace(),
      ],
    );
  }
}
