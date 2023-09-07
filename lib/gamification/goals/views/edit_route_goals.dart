import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/challenge_goals.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/gamification/goals/views/goal_slider.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/main.dart';
import 'package:priobike/home/services/shortcuts.dart';

class EditRouteGoalsView extends StatefulWidget {
  const EditRouteGoalsView({Key? key}) : super(key: key);

  @override
  State<EditRouteGoalsView> createState() => _EditRouteGoalsViewState();
}

class _EditRouteGoalsViewState extends State<EditRouteGoalsView> {
  /// The associated profile service.
  late GameProfileService _profileService;

  /// The associated shortcuts service
  late Shortcuts _shortcutsService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// List of saved routes of the user from the shortcut service.
  List<Shortcut> get routes => _shortcutsService.shortcuts?.toList() ?? [];

  Shortcut? selectedShortcut;

  @override
  void initState() {
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(update);
    _shortcutsService = getIt<Shortcuts>();
    _shortcutsService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    _shortcutsService.removeListener(update);

    super.dispose();
  }

  RouteGoals? get routeGoal => _profileService.challengeGoals.routeGoal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const VSpace(),
        GoalSettingSlider(
          title: 'Fahrten pro Woche',
          value: routeGoal?.perWeek.toDouble() ?? 3.0,
          min: 1,
          max: 7,
          stepSize: 1,
          valueLabel: 'mal',
        ),
        const VSpace(),
      ],
    );
  }
}
