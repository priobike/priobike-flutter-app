import 'dart:math';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/gamification/goals/models/user_goals.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/gamification/goals/views/edit_goal_widget.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/views/shortcuts/selection.dart';
import 'package:priobike/main.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/status/services/sg.dart';

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

  Widget createRouteWidget() {
    return Column(
      children: [
        const VSpace(),
        AnimatedButton(
          onPressed: () {
            if (getIt<Routing>().isFetchingRoute) return;
            HapticFeedback.mediumImpact();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutingView())).then(
              (comingNotFromRoutingView) {
                if (comingNotFromRoutingView == null) {
                  getIt<Routing>().reset();
                  getIt<Discomforts>().reset();
                  getIt<PredictionSGStatus>().reset();
                }
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.025),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SmallHSpace(),
                Expanded(
                  child: BoldSmall(
                    text: 'Du kannst dir eigene Routenziele setzen, sobald du deine erste eigene Route erstellt hast.',
                    context: context,
                    textAlign: TextAlign.center,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                  ),
                ),
                const SmallHSpace(),
                Icon(
                  Icons.arrow_forward,
                  size: 48,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        const VSpace(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;
    final shortcutHeight = max(shortcutWidth - (shortcutRightPad * 3), 128.0);
    return Column(
      children: routes.isEmpty
          ? [createRouteWidget()]
          : [
              const VSpace(),
              EditGoalWidget(
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
                        _profileService.updateUserGoals(newGoals);
                      },
              ),
              const VSpace(),
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
                              _profileService.updateUserGoals(goals);
                            } else {
                              RouteGoals newRouteGoals = RouteGoals(shortcut.id, shortcut.name, goalValue);
                              var newGoals = goals;
                              newGoals.routeGoal = newRouteGoals;
                              _profileService.updateUserGoals(newGoals);
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
