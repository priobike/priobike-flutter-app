import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/gamification/goals/models/user_goals.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/gamification/goals/views/edit_goal_widget.dart';
import 'package:priobike/main.dart';

class EditDailyGoalsView extends StatefulWidget {
  const EditDailyGoalsView({Key? key}) : super(key: key);

  @override
  State<EditDailyGoalsView> createState() => _EditDailyGoalsViewState();
}

class _EditDailyGoalsViewState extends State<EditDailyGoalsView> {
  /// The associated profile service.
  late GameProfileService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// The ride distance per day user goal.
  double get distanceGoal => goals.dailyDistanceGoalMetres / 1000;

  /// The ride duration per day user goal.
  double get durationGoal => goals.dailyDurationGoalMinutes;

  UserGoals get goals => _profileService.challengeGoals;

  @override
  void initState() {
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            goals.dailyDistanceGoalMetres = value * 1000;
            _profileService.updateUserGoals(goals);
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
            goals.dailyDurationGoalMinutes = value;
            _profileService.updateUserGoals(goals);
          },
        ),
        const VSpace(),
      ],
    );
  }
}