import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/challenges/models/challenge_goals.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/gamification/goals/views/goal_slider.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/views/shortcuts/selection.dart';
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

  int get goalValue => routeGoal?.perWeek ?? 3;

  /// List of saved routes of the user from the shortcut service.
  List<Shortcut> get routes => _shortcutsService.shortcuts?.toList() ?? [];

  UserGoals get goals => _profileService.challengeGoals;

  RouteGoals? get routeGoal => goals.routeGoal;

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

  @override
  Widget build(BuildContext context) {
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;
    final shortcutHeight = max(shortcutWidth - (shortcutRightPad * 3), 128.0);
    return Column(
      children: [
        const VSpace(),
        GoalSettingWidget(
          title: 'Fahrten pro Woche',
          value: goalValue.toDouble(),
          min: 1,
          max: 7,
          stepSize: 1,
          valueLabel: 'mal',
          onChanged: routeGoal == null
              ? null
              : (value) {
                  setState(() => routeGoal?.perWeek = value.toInt());
                  var newGoals = goals;
                  newGoals.routeGoal = routeGoal;
                  _profileService.setChallengeGoals(newGoals);
                },
        ),
        SingleChildScrollView(
          controller: ScrollController(),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: routes
                .map(
                  (shortcut) => ShortcutView(
                    onPressed: () {
                      if (routeGoal?.routeID == shortcut.id) {
                        goals.routeGoal = null;
                        _profileService.setChallengeGoals(goals);
                      } else {
                        RouteGoals newRouteGoals = RouteGoals(shortcut.id, shortcut.name, goalValue);
                        var newGoals = goals;
                        newGoals.routeGoal = newRouteGoals;
                        _profileService.setChallengeGoals(newGoals);
                      }
                    },
                    shortcut: shortcut,
                    width: shortcutWidth,
                    height: shortcutHeight,
                    rightPad: shortcutRightPad,
                    selected: routeGoal?.routeID == shortcut.id,
                    showSplash: false,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
