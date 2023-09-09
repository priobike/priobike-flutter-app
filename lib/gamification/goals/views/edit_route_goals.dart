import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
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
  /// The associated goals service.
  late UserGoalsService _goalsService;

  /// The associated shortcuts service
  late Shortcuts _shortcutsService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// List of saved routes of the user from the shortcut service.
  List<Shortcut> get routes => _shortcutsService.shortcuts?.toList() ?? [];

  @override
  void initState() {
    _goalsService = getIt<UserGoalsService>();
    _goalsService.addListener(update);
    _shortcutsService = getIt<Shortcuts>();
    _shortcutsService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _goalsService.removeListener(update);
    _shortcutsService.removeListener(update);
    super.dispose();
  }

  Widget get noRoutesWidget => Column(
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
                      text:
                          'Du kannst dir eigene Routenziele setzen, sobald du deine erste eigene Route erstellt hast.',
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

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) return noRoutesWidget;
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;
    final shortcutHeight = max(shortcutWidth - (shortcutRightPad * 3), 128.0);
    var goals = _goalsService.routeGoals;
    var selectedDays = goals?.weekdays ?? List.filled(7, false);
    return Column(
      children: [
        const VSpace(),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: selectedDays
              .mapIndexed(
                (i, day) => WeekdayButton(
                  label: StringFormatter.getWeekStr(i),
                  onPressed: goals == null
                      ? null
                      : () {
                          selectedDays[i] = !selectedDays[i];
                          goals?.weekdays = selectedDays;
                          _goalsService.updateRouteGoals(goals);
                        },
                  selected: day,
                ),
              )
              .toList(),
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
                      if (goals?.routeID == shortcut.id) {
                        _goalsService.updateRouteGoals(null);
                      } else {
                        goals = RouteGoals(shortcut.id, shortcut.name, List.filled(7, false));
                        _goalsService.updateRouteGoals(goals);
                      }
                    },
                    shortcut: shortcut,
                    width: shortcutWidth,
                    height: shortcutHeight,
                    rightPad: shortcutRightPad,
                    selected: goals?.routeID == shortcut.id,
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

class WeekdayButton extends StatefulWidget {
  final String label;

  final Function()? onPressed;

  final bool selected;

  const WeekdayButton({Key? key, required this.label, required this.onPressed, required this.selected})
      : super(key: key);

  @override
  State<WeekdayButton> createState() => _WeekdayButtonState();
}

class _WeekdayButtonState extends State<WeekdayButton> with SingleTickerProviderStateMixin {
  bool get disable => widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      scaleFactor: 0.85,
      blockFastClicking: false,
      onPressed: widget.onPressed,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              widget.selected ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(disable ? 0.05 : 0.1),
        ),
        child: Center(
          child: BoldSmall(
            text: widget.label,
            context: context,
            color: widget.selected
                ? Colors.white
                : Theme.of(context).colorScheme.onBackground.withOpacity(disable ? 0.25 : 1),
          ),
        ),
      ),
    );
  }
}
