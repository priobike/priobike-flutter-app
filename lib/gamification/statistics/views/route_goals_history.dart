import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/services/stats_view_model.dart';
import 'package:priobike/gamification/statistics/views/route_goals_in_week.dart';
import 'package:priobike/main.dart';

/// Display a history of the user reaching their route goal.
class RouteGoalsHistory extends StatefulWidget {
  /// The view model with the weeks, for which the history should be displayed.
  final StatisticsViewModel viewModel;

  const RouteGoalsHistory({Key? key, required this.viewModel}) : super(key: key);

  @override
  State<RouteGoalsHistory> createState() => _RouteGoalsHistoryState();
}

class _RouteGoalsHistoryState extends State<RouteGoalsHistory> {
  /// The associated goals service to get the route goals from.
  late GoalsService _goalsService;

  /// Index of the currently displayed week.
  int _currentWeekIndex = 0;

  /// Return the users route goals.
  RouteGoals? get _goals => _goalsService.routeGoals;

  /// Get the list of weeks the history should include.
  List<WeekStats> get _reversedWeeks => widget.viewModel.weeks.reversed.toList();

  /// Get the stats of the currently selected week.
  WeekStats get _currentWeekStats => _reversedWeeks.elementAt(_currentWeekIndex);

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BoldContent(
            text: 'Routenziele',
            context: context,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
            textAlign: TextAlign.start,
          ),
          if (_goals == null) ...[
            const VSpace(),
            Icon(
              Icons.map,
              size: 48,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: BoldContent(
                text: 'Du hast noch keine Routenziele gesetzt',
                context: context,
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
              ),
            ),
            const VSpace(),
          ],
          if (_goals != null) ...[
            const SmallVSpace(),
            BoldSubHeader(
              text: _goals!.routeName,
              context: context,
              textAlign: TextAlign.center,
              height: 1,
            ),
            Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: AnimatedSwitcher(
                duration: ShortDuration(),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: RouteGoalsInWeek(
                  key: ValueKey(_currentWeekStats.getTimeDescription(null)),
                  goals: _goals!,
                  ridesInWeek: _currentWeekStats.rides,
                  daySize: 40,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                OnTabAnimation(
                  scaleFactor: 0.8,
                  onPressed:
                      _currentWeekIndex >= _reversedWeeks.length - 1 ? null : () => setState(() => _currentWeekIndex++),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 32,
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(_currentWeekIndex >= _reversedWeeks.length - 1 ? 0.25 : 1),
                  ),
                ),
                Expanded(
                  child: SubHeader(
                    text: _currentWeekStats.getTimeDescription(null),
                    context: context,
                    textAlign: TextAlign.center,
                    height: 1,
                  ),
                ),
                OnTabAnimation(
                  scaleFactor: 0.8,
                  onPressed: _currentWeekIndex == 0 ? null : () => setState(() => _currentWeekIndex--),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(_currentWeekIndex == 0 ? 0.25 : 1),
                  ),
                ),
              ],
            ),
          ],
          const SmallVSpace(),
        ],
      ),
    );
  }
}
