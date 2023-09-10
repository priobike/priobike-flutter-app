import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/views/route_stats.dart';
import 'package:priobike/main.dart';

class RouteGoalsHistory extends StatefulWidget {
  const RouteGoalsHistory({Key? key}) : super(key: key);

  @override
  State<RouteGoalsHistory> createState() => _RouteGoalsHistoryState();
}

class _RouteGoalsHistoryState extends State<RouteGoalsHistory> {
  static const int numOfPages = 10;

  /// The associated goals service.
  late UserGoalsService _goalsService;

  List<WeekStatsViewModel> viewModels = [];

  int displayedViewModelIndex = numOfPages - 1;

  RouteGoals? get goals => _goalsService.routeGoals;

  WeekStatsViewModel get currentViewModel => viewModels[displayedViewModelIndex];

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    _goalsService = getIt<UserGoalsService>();
    _goalsService.addListener(update);
    createViewModels();
    super.initState();
  }

  @override
  void dispose() {
    for (var vm in viewModels) {
      vm.endStreams();
    }
    _goalsService.removeListener(update);
    super.dispose();
  }

  void createViewModels() {
    var today = DateTime.now();
    var weekStart = today.subtract(Duration(days: today.weekday - 1));
    for (int i = 0; i < numOfPages; i++) {
      var tmpWeekStart = weekStart.subtract(Duration(days: 7 * i));
      var viewModel = WeekStatsViewModel(tmpWeekStart);
      viewModel.startStreams();
      viewModel.addListener(() => update());
      viewModels.add(viewModel);
    }
    viewModels = viewModels.reversed.toList();
  }

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
          if (goals == null) ...[
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
          if (goals != null) ...[
            const SmallVSpace(),
            BoldSubHeader(
              text: goals!.routeName,
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
                duration: TinyDuration(),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: RoutesInWeekWidget(
                  key: ValueKey(currentViewModel.rangeStr),
                  weekGoals: goals!.weekdays,
                  ridesInWeek: currentViewModel.allRides,
                  routeId: goals!.routeID,
                  buttonSize: 40,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                AnimatedButton(
                  scaleFactor: 0.8,
                  onPressed:
                      currentViewModel == viewModels.first ? null : () => setState(() => displayedViewModelIndex--),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 32,
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(currentViewModel == viewModels.first ? 0.25 : 1),
                  ),
                ),
                Expanded(
                  child: SubHeader(
                    text: currentViewModel.rangeStr,
                    context: context,
                    textAlign: TextAlign.center,
                    height: 1,
                  ),
                ),
                AnimatedButton(
                  scaleFactor: 0.8,
                  onPressed:
                      currentViewModel == viewModels.last ? null : () => setState(() => displayedViewModelIndex++),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 32,
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(currentViewModel == viewModels.last ? 0.25 : 1),
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
